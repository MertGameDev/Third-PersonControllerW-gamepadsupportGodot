shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform float height_scale = 0.1;
uniform sampler2D noise;
uniform sampler2D normalmap;

varying vec2 tex_position;

// Pre-calculate constants for use in height function
const float wave_scale = 0.4;
const float wave_scale2 = 0.3;
const float wave_scale3 = 0.5;
const float wave_scale4 = 0.6;
const float wave_pow = 0.65;
const float wave_pow2 = 4.0;

float wave(vec2 position){
  position += texture(noise, position / 64.0).x * 2.0 - 1.0;
  vec2 wv = 1.0 - abs(sin(position));
  return pow(1.0 - pow(wv.x * wv.y, wave_pow), wave_pow2);
}

float height(vec2 position, float time) {
  float d = wave((position + time) * wave_scale) * 0.3;
  d += wave((position - time) * wave_scale2) * 0.3;
  d += wave((position + time) * wave_scale3) * 0.2;
  d += wave((position - time) * wave_scale4) * 0.2;
  return d;
}

void vertex() {
  // Get the current vertex position
  vec3 pos = VERTEX;

  // Get the height of the terrain at this position
  float k = height(pos.xz, TIME);

  // Set the Y position of the vertex to the terrain height
  VERTEX.y = k * height_scale;

  // Calculate the normal vector using nearby terrain heights
  NORMAL = normalize(vec3(
    k - height(pos.xz + vec2(0.1, 0.0), TIME),
    0.1,
    k - height(pos.xz + vec2(0.0, 0.1), TIME)
  ));

  // Apply the normal map to the normal vector
  NORMAL = normalize(texture(normalmap, tex_position).rgb * 2.0 - 1.0 + NORMAL);
}

void fragment() {
  // Calculate the fresnel factor
  float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));

  // Set material properties
  RIM = 0.2;
  METALLIC = 0.0;
  ROUGHNESS = 0.01 * (1.0 - fresnel);
  ALBEDO = vec3(0.1, 0.3, 0.5) + (0.1 * fresnel);
}