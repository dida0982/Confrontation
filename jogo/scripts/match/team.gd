class_name Team
## Os dois times da partida.

enum Id { AZUL, VERMELHO }

const NAMES := {
	Id.AZUL: "Azul",
	Id.VERMELHO: "Vermelho",
}

const COLORS := {
	Id.AZUL: Color(0.3, 0.65, 1.0),
	Id.VERMELHO: Color(1.0, 0.35, 0.3),
}


static func name_of(team: Id) -> String:
	return NAMES[team]


static func color_of(team: Id) -> Color:
	return COLORS[team]
