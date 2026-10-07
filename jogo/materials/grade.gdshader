// Material de "greybox": cor lisa com linhas a cada 1 metro.
// Ajuda a ter noção de tamanho e distância enquanto o mapa não tem arte.
shader_type spatial;

uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 line_color : source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform float line_width = 0.02;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	vec3 n = abs(normalize(world_normal));
	vec3 dist = abs(fract(world_pos + 0.5) - 0.5);
	float line = 0.0;
	if (n.x < 0.5) { line = max(line, step(dist.x, line_width)); }
	if (n.y < 0.5) { line = max(line, step(dist.y, line_width)); }
	if (n.z < 0.5) { line = max(line, step(dist.z, line_width)); }
	ALBEDO = mix(base_color.rgb, line_color.rgb, line);
	ROUGHNESS = 0.9;
}
