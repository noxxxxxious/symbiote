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
    float tendrilJitter;
    float tendrilSpread;
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

// Stable pseudo-randomness keeps the organism organic without making tendrils
// crawl around from frame to frame or after an unrelated UI animation.
float tendrilHash(float n) {
    return fract(sin(n * 12.9898 + 78.233) * 43758.5453);
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
    if (tendrilsEnabled > 0.5 && tendrilCount > 0.5) {
        // Tendrils are a pool for the entire workspace organism. Their tips are
        // distributed over the continuous chamber/tube extent, so a tendril can
        // naturally terminate on a chamber, a neck, or anywhere between them.
        const int MAX_WORKSPACE_TENDRILS = 16;
        float count = clamp(floor(tendrilCount + 0.5), 1.0, float(MAX_WORKSPACE_TENDRILS));

        // Include most of the first/last chamber instead of limiting the usable
        // span to workspace center points. This also gives a one-node indicator
        // enough width to support several distinct tendrils.
        float organismStart = -chamberRadius * 0.78;
        float organismEnd = end + chamberRadius * 0.78;
        float organismSpan = max(1.0, organismEnd - organismStart);
        float occupiedSpan = organismSpan * clamp(tendrilSpread, 0.05, 1.0);
        float occupiedStart = (organismStart + organismEnd - occupiedSpan) * 0.5;

        for (int j = 0; j < MAX_WORKSPACE_TENDRILS; ++j) {
            if (float(j) >= count) break;

            float jf = float(j);
            float distributed = count <= 1.0 ? 0.5 : jf / (count - 1.0);
            float seed = jf + nodeCount * 17.0;

            // Jitter is applied to the organism-side attachment rather than to a
            // chamber index, which is what lets tips land on the connective tube.
            float tipAlong = occupiedStart + distributed * occupiedSpan;
            tipAlong += (tendrilHash(seed) - 0.5) * 2.0 * tendrilJitter;
            tipAlong = clamp(tipAlong, organismStart, organismEnd);

            // Roots live on the dock border. Reach controls how far the root may
            // fan sideways from its attachment, producing longer/slanted strands
            // while preserving a real connection to the screen-edge organism.
            float rootAlong = tipAlong + (tendrilHash(seed + 31.7) - 0.5) * 2.0 * tendrilReach;
            rootAlong = clamp(rootAlong, organismStart, organismEnd);

            vec2 root = vec2(rootAlong, dockNormal);
            vec2 tip = vec2(tipAlong, 0.0);
            vec2 delta = tip - root;
            float t = clamp(dot(p - root, delta) / max(dot(delta, delta), 0.001), 0.0, 1.0);
            float radius = mix(tendrilRootWidth, tendrilTipWidth, t) + tendrilWidth * 0.2;
            float tether = length(p - root - delta * t) - radius;
            shape = smoothUnion(shape, tether, 7.0);
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
