#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize.xy;
    float time = uTime * 0.5;

    // Create a simple color based on time
    vec3 color = vec3(0.5 + 0.5 * cos(time + uv.xyx + vec3(0,2,4)));

    fragColor = vec4(color, 1.0);
} 