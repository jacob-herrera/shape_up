shader_type spatial;

uniform vec3 albedo: source_color = vec3(1.0, 1.0, 1.0);
uniform float alpha : hint_range( 0.0, 1.0 ) = 0.5;

void fragment(){
	ALBEDO = albedo;
	ALPHA = alpha;
}