#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    vec2 nodeOrigin;
    float tendrilsEnabled;
    float tendrilWidth;
    float tendrilCount;
    float tendrilReach;
    float tendrilRootWidth;
    float tendrilTipWidth;
    float dockNormal;
    float dockSign;
    float verticalF;
    float nodeCount;
    float nodeSpacing;
    float chamberRadius;
    float tubeRadius;
    float liquidPosition;
    float liquidEnabled;
    vec4 baseColor;
    vec4 liquidColor;
};
float smoothUnion(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}
void main() {
    vec2 pixel = qt_TexCoord0 * size - nodeOrigin;
    vec2 p = verticalF > 0.5 ? pixel.yx : pixel;
    p -= vec2(chamberRadius + 10.0);
    float end = max(0.0, nodeCount - 1.0) * nodeSpacing;
    vec2 nearest = vec2(clamp(p.x, 0.0, end), 0.0);
    float shape = length(p - nearest) - tubeRadius;
    for (int i = 0; i < 12; ++i) {
        if (float(i) >= nodeCount) break;
        shape = smoothUnion(shape, length(p - vec2(float(i) * nodeSpacing, 0)) - chamberRadius, 7.0);
    }
    float chambers = shape;
    if (tendrilsEnabled > 0.5) {
        for (int i = 0; i < 12; ++i) {
            if (float(i) >= nodeCount) break;
            for (int j = 0; j < 3; ++j) {
                if (float(j) >= tendrilCount) break;
                float along = float(i) * nodeSpacing;
                float spread = (float(j) - (tendrilCount - 1.0) * 0.5) * 10.0;
                vec2 root = vec2(along + sin(float(i) * 2.399 + float(j)) * 9.0 + spread,
                                 dockNormal + dockSign * tendrilReach);
                vec2 tip = vec2(along + spread * 0.35, 0.0);
                vec2 delta = tip - root;
                float t = clamp(dot(p - root, delta) / max(dot(delta, delta), 0.001), 0.0, 1.0);
                float radius = mix(tendrilRootWidth, tendrilTipWidth, t) + tendrilWidth * 0.2;
                float tether = length(p - root - delta * t) - radius;
                shape = smoothUnion(shape, tether, 7.0);
            }
        }
        shape = smoothUnion(shape, (p.y - dockNormal) * dockSign, 7.0);
    }
    // A chamber-sized volume squeezes into an elongated slug in each neck.
    // Clipping to the channel makes the liquid follow its walls, not slide on top.
    float squeeze = pow(abs(sin(liquidPosition * 3.14159265359)), 0.8);
    float across = mix(chamberRadius - 3.0, max(1.0, tubeRadius - 1.5), squeeze);
    float along = mix(chamberRadius - 3.0, nodeSpacing * 0.72, squeeze);
    vec2 liquidP = p - vec2(liquidPosition * nodeSpacing, 0.0);
    float liquid = (length(liquidP / vec2(along, across)) - 1.0) * min(along, across);
    liquid = max(liquid, chambers + 2.0);
    float coverage = 1.0 - smoothstep(-0.7, 0.7, shape);
    float fill = (1.0 - smoothstep(-0.7, 0.7, liquid)) * liquidEnabled;
    float rim = 1.0 - smoothstep(0.0, 2.0, abs(shape));
    vec3 rgb = mix(baseColor.rgb, liquidColor.rgb, max(fill, rim * 0.45));
    float alpha = coverage * baseColor.a * qt_Opacity;
    fragColor = vec4(rgb * alpha, alpha);
}
