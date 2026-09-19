#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uDpr;
uniform float uExtent;
uniform vec4 uCubic;
uniform float uDither;

out vec4 fragColor;

float bezier(float t, float a, float b) {
  float m = 1.0 - t;
  return 3.0 * m * m * t * a + 3.0 * m * t * t * b + t * t * t;
}

float ease(float x) {
  if (x <= 0.0) return 0.0;
  if (x >= 1.0) return 1.0;
  float low = 0.0;
  float high = 1.0;
  for (int i = 0; i < 20; i++) {
    float t = (low + high) * 0.5;
    if (bezier(t, uCubic.x, uCubic.z) < x) low = t;
    else high = t;
  }
  return bezier((low + high) * 0.5, uCubic.y, uCubic.w);
}

void main() {
  vec2 position = FlutterFragCoord().xy;
  float edge = max(uSize.y * uExtent, 0.00001);
  float leading = ease(clamp(position.y / edge, 0.0, 1.0));
  float trailing = 1.0 - ease(clamp((position.y - uSize.y + edge) / edge, 0.0, 1.0));
  float alpha = leading * trailing;
  // A dstIn mask discards RGB, so dithering must affect alpha itself.
  if (alpha > 0.0 && alpha < 1.0) {
    vec2 pixel = floor(position * uDpr);
    float noise = fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715)))) - 0.5;
    alpha = clamp(alpha + noise * uDither / 255.0, 0.0, 1.0);
  }
  fragColor = vec4(0.0, 0.0, 0.0, alpha);
}
