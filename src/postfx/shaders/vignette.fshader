#version 330

in vec2 fragTexCoord;
in vec4 fragColor;
out vec4 finalColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

uniform float uStrength;  // 0..1
uniform float uRadius;    // 0..1, где начинается затемнение

void main() {
    vec4 c = texture(texture0, fragTexCoord);

    float d = distance(fragTexCoord, vec2(0.5));
    // 0 внутри радиуса, 1 у краёв
    float v = smoothstep(uRadius, 1.0, d);
    float f = mix(1.0, 1.0 - v, uStrength);

    finalColor = vec4(c.rgb * f, c.a) * colDiffuse * fragColor;
}