shader_type spatial;
render_mode unshaded;

uniform vec3 albedo: source_color = vec3(1.0, 1.0, 1.0);
uniform float alpha : hint_range( 0.0, 1.0 ) = 1.0;

void fragment() {
	ALBEDO = mix(albedo / 2.0, albedo, dot(NORMAL, VIEW));
	ALPHA = alpha;
}