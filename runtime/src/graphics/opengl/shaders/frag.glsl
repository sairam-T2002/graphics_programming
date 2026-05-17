#version 400 core

in vec3 outPos;
in vec3 colorFromProgram;
in vec2 texCoord;

out vec4 FragColor;

uniform vec4 colorFromUniform;
uniform bool useUniformColor;
uniform bool useUniformTexture;
uniform sampler2D textureFromProgram1;
uniform sampler2D textureFromProgram2;

void main()
{
    if (useUniformTexture) {
        FragColor = mix(texture(textureFromProgram1, texCoord), texture(textureFromProgram2, texCoord), 0.2) * (useUniformColor ? colorFromUniform : vec4(1.0, 1.0, 1.0, 1.0));
    }
    else if (useUniformColor) {
        FragColor = colorFromUniform;
    } else {
        FragColor = vec4(colorFromProgram, 1.0);
    }
}
