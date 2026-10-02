#version 330

in vec2 fragTexCoord;
in vec4 fragColor;
out vec4 finalColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

uniform float uAmount;  // 0..~0.02, радиальный сдвиг от центра

void main() {
    vec4 c = texture(texture0, fragTexCoord);

    vec2 d   = fragTexCoord - vec2(0.5);
    vec2 off = d * uAmount;

    float r = texture(texture0, fragTexCoord + off).r;
    float b = texture(texture0, fragTexCoord - off).b;

    finalColor = vec4(r, c.g, b, c.a) * colDiffuse * fragColor;
}