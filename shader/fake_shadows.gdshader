shader_type spatial;
render_mode unshaded;

uniform vec3 albedo: source_color = vec3(1.0, 1.0, 1.0);
// uniform vec3 shadow: source_color = vec3(0.0, 0.0, 0.0);

void fragment() {
	ALBEDO = mix(albedo / 2.0, albedo, dot(NORMAL, VIEW));
}