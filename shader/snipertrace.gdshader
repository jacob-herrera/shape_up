shader_type spatial;

uniform float alpha : hint_range( 0.0, 1.0 ) = 0.5;

void fragment(){
	ALBEDO = vec3(1.0, 1.0, 1.0);
	ALPHA = alpha;
}