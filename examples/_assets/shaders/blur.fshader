#version 330

in vec2 fragTexCoord;
in vec4 fragColor;
out vec4 finalColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

uniform vec2  uTexel;      // 1.0 / virtual_size
uniform vec2  uDirection;  // (1,0) = H, (0,1) = V
uniform float uRadius;     // в текселях виртуального рендера

void main() {
    vec2 step = uTexel * uDirection * uRadius;

    // 9-tap гаусс, sigma ~ 2
    float w0 = 0.2270270270;
    float w1 = 0.1945945946;
    float w2 = 0.1216216216;
    float w3 = 0.0540540541;
    float w4 = 0.0162162162;

    vec4 c = texture(texture0, fragTexCoord) * w0;
    c += texture(texture0, fragTexCoord + step * 1.0) * w1;
    c += texture(texture0, fragTexCoord - step * 1.0) * w1;
    c += texture(texture0, fragTexCoord + step * 2.0) * w2;
    c += texture(texture0, fragTexCoord - step * 2.0) * w2;
    c += texture(texture0, fragTexCoord + step * 3.0) * w3;
    c += texture(texture0, fragTexCoord - step * 3.0) * w3;
    c += texture(texture0, fragTexCoord + step * 4.0) * w4;
    c += texture(texture0, fragTexCoord - step * 4.0) * w4;

    finalColor = c * colDiffuse * fragColor;
}