shader_type spatial;

uniform vec3 albedo: source_color = vec3(1.0, 1.0, 1.0);
uniform float amt : hint_range( 0.0, 1.0 ) = 0.0;

const vec3 RED = vec3(1.0, 0.0, 0.0);
// const vec3 BLACK = vec3(0.0, 0.0, 0.0);

void fragment() {
	vec3 normal = mix(albedo/2.0, albedo, dot(NORMAL, VIEW));
	ALBEDO = mix(normal, RED, amt);
}
