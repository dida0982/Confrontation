extends Node
## Rede: conexão entre os jogadores. Fica carregado o jogo todo como "Rede".
##
## Modelo: um jogador CRIA a partida (é o "host", que também joga) e os outros
## ENTRAM pelo IP dele. O host é o servidor: decide dano, mortes, placar e
## renascimento. Cada jogador controla o próprio movimento.
##
## Fluxo:
## 1. host() ou join() -> todos ficam na SALA (lobby) e escolhem o time.
## 2. O host chama start_match(mapa) -> todos carregam o mapa.
## 3. Cada um avisa report_map_loaded(); quando todos carregaram, o servidor
##    emite all_loaded e a partida cria os jogadores.
##
## Jogar sozinho usa o mesmo caminho, só que sem conexão (play_offline).
##
## Bots: se bots_enabled, a partida completa os dois times até 5 contra 5 com
## bots (só o host cria e controla os bots). Eles não entram em "players".

signal players_changed
## O servidor confirmou a entrada deste jogador na sala.
signal joined_lobby
## Só no servidor: todos os jogadores carregaram o mapa.
signal all_loaded
## Só no servidor: um jogador saiu (id do jogador).
signal player_left(id: int)
## A configuração de bots mudou (a sala mostra para todos).
signal bots_changed

const PORT := 7777
const MAX_PER_TEAM := 5
const MAX_PLAYERS := MAX_PER_TEAM * 2
const MAX_NAME_LENGTH := 16
const MENU_SCENE := "res://scenes/menu_principal.tscn"
const DEFAULT_MAP := "res://scenes/mapas/porto.tscn"
## Nomes dos bots (cada um ganha "Bot " na frente).
const BOT_NAMES := [
	"Tatu", "Jaguar", "Falcão", "Sabiá", "Capivara", "Tucano", "Onça", "Arara",
	"Gavião", "Quati", "Boto", "Sucuri", "Coruja", "Lobo", "Jacaré",
]

## id do jogador -> {"name": String, "team": Team.Id}
var players := {}
var in_match := false
var current_map := ""
## Mensagem para mostrar no menu (ex.: "O host fechou a partida").
var last_message := ""
## Completar os times com bots até 5 contra 5.
var bots_enabled := false
## Dificuldade dos bots (BotController.Difficulty: 0 = Fácil, 1 = Normal, 2 = Difícil).
var bot_difficulty := 1

var _local_name := ""
## Só no servidor: quem já carregou o mapa atual.
var _loaded := {}
var _all_loaded_sent := false


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


## true quando está conectado com outros (host ou cliente).
func is_online() -> bool:
	return not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer)


func local_id() -> int:
	return multiplayer.get_unique_id()


# --- Começar / entrar / sair ------------------------------------------------

## Joga sozinho, sem conexão (treino com os bonecos).
func play_offline(player_name: String, map_path: String) -> void:
	_close_connection()
	players = {1: {"name": clean_name(player_name), "team": Team.Id.AZUL}}
	start_match(map_path)


## Joga sozinho no time Azul com 4 bots aliados contra 5 bots inimigos.
func play_vs_bots(player_name: String, difficulty: int) -> void:
	_close_connection()
	players = {1: {"name": clean_name(player_name), "team": Team.Id.AZUL}}
	bots_enabled = true
	bot_difficulty = difficulty
	start_match(DEFAULT_MAP)


## Só o host: liga/desliga os bots da sala e escolhe a dificuldade.
func set_bots(enabled: bool, difficulty: int) -> void:
	if multiplayer.is_server():
		_sync_bots.rpc(enabled, difficulty)


## Quantos bots entram em cada time para completar 5 contra 5.
func bots_needed(team: Team.Id) -> int:
	return maxi(MAX_PER_TEAM - team_count(team), 0) if bots_enabled else 0


## Quando um mapa é aberto direto no editor (F6), sem passar pelo menu:
## cria um jogador sozinho para dar para testar.
func ensure_offline_player() -> void:
	if not players.is_empty() or is_online():
		return
	players = {1: {"name": clean_name(Configuracoes.player_name), "team": Team.Id.AZUL}}
	in_match = true


## Cria a partida neste computador. Retorna OK ou o erro do Godot.
func host(player_name: String) -> Error:
	_close_connection()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_PLAYERS - 1)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	players = {1: {"name": clean_name(player_name), "team": Team.Id.AZUL}}
	players_changed.emit()
	joined_lobby.emit()
	return OK


## Entra na partida de outro computador pelo IP.
func join(address: String, player_name: String) -> Error:
	_close_connection()
	_local_name = clean_name(player_name)
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address.strip_edges(), PORT)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	return OK


## Sai da partida/sala e volta para o menu principal.
func leave(message: String = "") -> void:
	last_message = message
	_close_connection()
	get_tree().change_scene_to_file(MENU_SCENE)


## Pede para trocar de time (o servidor confere se tem vaga).
func request_team(team: Team.Id) -> void:
	_change_team.rpc_id(1, team)


## Só o servidor: todos carregam o mapa e a partida começa.
func start_match(map_path: String) -> void:
	if not multiplayer.is_server():
		return
	_loaded.clear()
	_all_loaded_sent = false
	_load_map.rpc(map_path)


## Só o servidor: leva todo mundo de volta para a sala.
func return_to_lobby() -> void:
	if multiplayer.is_server():
		_load_lobby.rpc()


## Chamado pela partida quando o mapa terminou de carregar neste computador.
func report_map_loaded() -> void:
	_map_loaded.rpc_id(1)


func team_count(team: Team.Id) -> int:
	var count := 0
	for id in players:
		if players[id]["team"] == team:
			count += 1
	return count


## IPs deste computador na rede local (para os amigos entrarem).
func local_addresses() -> PackedStringArray:
	var result := PackedStringArray()
	for address in IP.get_local_addresses():
		if address.count(".") == 3 and not address.begins_with("127.") and not address.begins_with("169.254."):
			result.append(address)
	return result


static func clean_name(player_name: String) -> String:
	var cleaned := player_name.strip_edges().replace("[", "").replace("]", "")
	if cleaned.is_empty():
		cleaned = "Jogador"
	return cleaned.left(MAX_NAME_LENGTH)


# --- Mensagens pela rede ----------------------------------------------------

## Cliente -> servidor: "quero entrar com este nome".
@rpc("any_peer", "reliable")
func _register(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if in_match:
		_reject.rpc_id(id, "A partida já começou. Peça para o host voltar para a sala.")
		return
	if players.size() >= MAX_PLAYERS:
		_reject.rpc_id(id, "A sala está cheia (5 contra 5).")
		return
	var team := Team.Id.AZUL if team_count(Team.Id.AZUL) <= team_count(Team.Id.VERMELHO) else Team.Id.VERMELHO
	players[id] = {"name": clean_name(player_name), "team": team}
	_sync_players.rpc(players)
	_sync_bots.rpc_id(id, bots_enabled, bot_difficulty)


@rpc("authority", "call_local", "reliable")
func _sync_players(new_players: Dictionary) -> void:
	var first_time := not multiplayer.is_server() and not players.has(local_id())
	players = new_players
	players_changed.emit()
	if first_time and players.has(local_id()):
		joined_lobby.emit()


@rpc("authority", "call_local", "reliable")
func _sync_bots(enabled: bool, difficulty: int) -> void:
	bots_enabled = enabled
	bot_difficulty = clampi(difficulty, 0, 2)
	bots_changed.emit()


@rpc("authority", "reliable")
func _reject(reason: String) -> void:
	leave.call_deferred(reason)


@rpc("any_peer", "call_local", "reliable")
func _change_team(team: Team.Id) -> void:
	if not multiplayer.is_server():
		return
	var id := _sender_id()
	if not players.has(id) or players[id]["team"] == team or team_count(team) >= MAX_PER_TEAM:
		return
	players[id]["team"] = team
	_sync_players.rpc(players)


@rpc("authority", "call_local", "reliable")
func _load_map(map_path: String) -> void:
	in_match = true
	current_map = map_path
	get_tree().change_scene_to_file(map_path)


@rpc("authority", "call_local", "reliable")
func _load_lobby() -> void:
	in_match = false
	get_tree().change_scene_to_file(MENU_SCENE)


@rpc("any_peer", "call_local", "reliable")
func _map_loaded() -> void:
	if not multiplayer.is_server():
		return
	_loaded[_sender_id()] = true
	_check_all_loaded()


func _check_all_loaded() -> void:
	if _all_loaded_sent or not in_match:
		return
	for id in players:
		if not _loaded.has(id):
			return
	_all_loaded_sent = true
	all_loaded.emit()


# --- Eventos de conexão -----------------------------------------------------

func _on_connected_to_server() -> void:
	_register.rpc_id(1, _local_name)


func _on_connection_failed() -> void:
	leave.call_deferred("Não foi possível conectar. Confira o IP e se o host já criou a partida.")


func _on_server_disconnected() -> void:
	leave.call_deferred("A conexão com o host acabou (ele saiu ou a internet caiu).")


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server() or not players.has(id):
		return
	players.erase(id)
	_loaded.erase(id)
	player_left.emit(id)
	_sync_players.rpc(players)
	_check_all_loaded()


func _close_connection() -> void:
	if is_online():
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players = {}
	in_match = false
	bots_enabled = false
	_loaded.clear()
	_all_loaded_sent = false


func _sender_id() -> int:
	var id := multiplayer.get_remote_sender_id()
	return id if id != 0 else multiplayer.get_unique_id()
