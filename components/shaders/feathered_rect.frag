#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    vec4 color;
    float radius;
    float feather;
};

// Standard 2D rounded box SDF
float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    // Convert normalized UV [0, 1] to pixel coords centered at (0, 0)
    vec2 p = (qt_TexCoord0 - 0.5) * size;
    
    // Half-extents of the rectangle, inset by half the feather margin so it stays within bounds
    float f = max(feather, 1.0);
    vec2 b = max(vec2(0.0), (size * 0.5) - vec2(f * 0.5));
    float r = clamp(radius, 0.0, min(b.x, b.y));

    // Distance from the rounded rectangle boundary
    float d = sdRoundBox(p, b, r);

    // Smoothstep: 1.0 inside (-f*0.5), fading to 0.0 at edge (+f*0.5)
    float alpha = 1.0 - smoothstep(-f * 0.5, f * 0.5, d);
    alpha *= color.a * qt_Opacity;

    // Premultiplied alpha output (standard for QtQuick ShaderEffect)
    fragColor = vec4(color.rgb * alpha, alpha);
}
