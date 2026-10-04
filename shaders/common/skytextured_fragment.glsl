#include "/lib/config.glsl"

/* Color utils */

#ifdef THE_END
    #include "/lib/color_utils_end.glsl"
#elif defined NETHER
    #include "/lib/color_utils_nether.glsl"
#else
    #include "/lib/color_utils.glsl"
#endif

/* Uniforms */

uniform sampler2D tex;

#ifdef NETHER
    uniform vec3 fogColor;
#endif

/* Ins / Outs */

varying vec2 texcoord;
varying vec4 tintColor;
varying float sky_luma_correction;  // Flat
varying vec2 quad_xy;
varying float quad_corner;
varying float is_sun;

#define SUN_SIZE 0.22
#define MOON_SIZE 0.33

vec2 hash22(vec2 q) {
    vec3 p3 = fract(vec3(q.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

float vnoise(vec2 q) {
    vec2 i = floor(q);
    vec2 f = fract(q);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash22(i).x, hash22(i + vec2(1.0, 0.0)).x, f.x),
               mix(hash22(i + vec2(0.0, 1.0)).x, hash22(i + vec2(1.0, 1.0)).x, f.x), f.y);
}

// MAIN FUNCTION ------------------

void main() {
    #if defined THE_END
        #if MC_VERSION >= 12109
            vec4 blockColor = vec4(ZENITH_DAY_COLOR, 0.0);  // End Flashes Fix
        #else
            vec4 blockColor = vec4(ZENITH_DAY_COLOR, 1.0);
        #endif
    #elif defined NETHER  // Unused
        vec4 background_color_full = vec4(mix(fogColor * 0.1, vec3(1.0), 0.04), 1.0);
        vec3 background_color = background_color_full.rgb;
        vec4 blockColor = vec4(background_color, 1.0);
    #else
        // Toma el color puro del bloque
        vec4 blockColor = texture2D(tex, texcoord) * tintColor;

        blockColor.rgb *= sky_luma_correction;

        // The sky sprite is a small square inside a larger quad: draw a procedural disk instead
        float disk_size = mix(MOON_SIZE, SUN_SIZE, is_sun);  // fraction of the half-quad
        vec2 p = quad_xy / (quad_corner * 0.7071 * disk_size);  // sphere units: |p| = 1 at the limb
        float r2 = dot(p, p);
        float disk = 1.0 - smoothstep(0.93, 1.0, sqrt(r2));
        vec3 disk_color;

        if (is_sun > 0.5) {
            disk_color = vec3(1.0, 0.93, 0.80) * (1.0 + 0.25 * (1.0 - r2));
        } else {
            // Soft crescent: disk minus an offset dark disk. moonPhase 0 full, 4 new,
            // 1-3 waning (lit left), 5-7 waxing (lit right)
            float phase_angle = float(moonPhase) * 0.7853982;
            float frac = 0.5 + 0.5 * cos(phase_angle);  // illuminated fraction
            float side = sin(phase_angle) >= 0.0 ? 1.0 : -1.0;
            float dark_dist = length(p - vec2(side * 2.2 * frac, 0.0));
            float lit = smoothstep(0.8, 1.1, dark_dist);
            float body = (1.0 - smoothstep(0.75, 1.05, sqrt(r2))) * lit;
            float halo = 0.16 * (0.3 + 0.7 * frac) * mix(0.15, 1.0, lit) * exp(-3.0 * max(sqrt(r2) - 0.9, 0.0));
            disk = clamp(body + halo * (1.0 - body), 0.0, 1.0);
            disk_color = vec3(0.95, 0.97, 1.0) * 0.6;
        }

        blockColor = vec4(disk_color * tintColor.rgb * sky_luma_correction, disk);
    #endif

    // Sun/moon are sky: far depth so deferred clouds (sky only) cover them
    gl_FragDepth = 1.0;

    #include "/src/writebuffers.glsl"
}
