#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

uniform float uThreshold;
uniform float uSharpness;

out vec4 finalColor;

void main()
{
    float dist = texture(texture0, fragTexCoord).a;

    float signedDist = dist - uThreshold;

    float grad = length(vec2(dFdx(signedDist), dFdy(signedDist)));

    // Чем больше sharpness, тем тоньше линия сглаживания
    float w = max(grad / max(uSharpness, 0.0001), 0.0001);

    float alpha = smoothstep(-w, w, signedDist);

    if (alpha <= 0.001) {
        discard;
    }

    finalColor = vec4(fragColor.rgb, fragColor.a * alpha);
}
