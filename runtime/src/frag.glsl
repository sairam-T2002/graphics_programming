#version 400 core
out vec4 FragColor;
in vec3 outPos;
in vec3 colorFromProgram;
uniform vec4 colorFromUniform;
uniform bool useUniformColor;

void main()
{
    if (useUniformColor) {
        FragColor = colorFromUniform;
    } else {
        FragColor = vec4(colorFromProgram, 1.0);
    }
}
