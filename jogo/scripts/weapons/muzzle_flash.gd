class_name MuzzleFlash
## Clarão rápido no cano da arma quando alguém atira: uma luz forte e uma
## "bolinha" brilhante que somem em poucos centésimos de segundo.

const DURATION := 0.05
const COLOR := Color(1.0, 0.75, 0.35)


static func spawn(parent: Node, at: Vector3) -> void:
	if parent == null:
		return
	var flash := Node3D.new()
	parent.add_child(flash)
	flash.global_position = at

	var light := OmniLight3D.new()
	light.light_color = COLOR
	light.light_energy = 3.0
	light.omni_range = 4.0
	light.shadow_enabled = false
	flash.add_child(light)

	var glow := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = COLOR
	material.emission_enabled = true
	material.emission = COLOR
	sphere.material = material
	glow.mesh = sphere
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash.add_child(glow)

	flash.get_tree().create_timer(DURATION).timeout.connect(flash.queue_free)
