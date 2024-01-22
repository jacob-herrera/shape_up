shader_type spatial;

uniform vec3 previous_position;
uniform vec3 new_position;
uniform float intensity=1.0;
uniform float freq = 1.0;
uniform float delta;

/** Godot Docs **/
float hash(vec2 p) {
  return fract(sin(dot(p * 17.17, vec2(14.91, 67.31))) * 4791.9511);
}

float noise(vec2 x) {
  vec2 p = floor(x);
  vec2 f = fract(x);
  f = f * f * (3.0 - 2.0 * f);
  vec2 a = vec2(1.0, 0.0);
  return mix(mix(hash(p + a.yy), hash(p + a.xy), f.x),
         mix(hash(p + a.yx), hash(p + a.xx), f.x), f.y);
}


float fbm(vec2 x) {
  float height = 0.0;
  float amplitude = 0.5;
  float frequency = 3.0;
  for (int i = 0; i < 6; i++){
    height += noise(x * frequency * freq) * amplitude;
    amplitude *= 0.5;
    frequency *= 2.0;
  }
  return height;
}

/***/

void vertex(){
	float height = fbm(VERTEX.xz * 4.0 + TIME);
	vec3 move_dir = previous_position - new_position;
	float mag = clamp(dot(VERTEX,move_dir),0,1);
	VERTEX += intensity * height * move_dir * mag;
	//COLOR.xyz = vec3(dot(VERTEX,move_dir));
}

void fragment(){
	ALBEDO = vec3(1.0,1.0,0.0);
}