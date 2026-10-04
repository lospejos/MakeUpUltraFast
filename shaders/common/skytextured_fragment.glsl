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
            // Lit sphere: moonPhase 0 full, 4 new, 1-3 waning (lit left), 5-7 waxing (lit right)
            vec3 n = vec3(p, sqrt(max(0.0, 1.0 - r2)));
            float phase_angle = float(moonPhase) * 0.7853982;
            vec3 light_dir = vec3(-sin(phase_angle), 0.0, cos(phase_angle));
            float n_dot_l = dot(n, light_dir);
            float lit = smoothstep(-0.02, 0.06, n_dot_l) * (0.55 + 0.45 * pow(max(n_dot_l, 0.0), 0.4));

            // Surface: maria + craters
            float maria = vnoise(p * 1.8 + 7.0) * 0.6 + vnoise(p * 4.5) * 0.4;
            float albedo = 0.95 - 0.55 * smoothstep(0.38, 0.62, maria);
            vec2 g = p * 3.5;
            vec2 cell = floor(g);
            vec2 h = hash22(cell);
            float d = length(fract(g) - 0.5 - (h - 0.5) * 0.5);
            float crater = step(0.4, h.x) * (smoothstep(0.24, 0.14, d) * 0.3 - smoothstep(0.24, 0.27, d) * smoothstep(0.32, 0.27, d) * 0.12);
            albedo -= crater;

            disk_color = vec3(0.95, 0.97, 1.0) * 0.75 * albedo * (0.03 + 0.97 * lit);
        }

        blockColor = vec4(disk_color * tintColor.rgb * sky_luma_correction, disk);
    #endif

    // Sun/moon are sky: far depth so deferred clouds (sky only) cover them
    gl_FragDepth = 1.0;

    #include "/src/writebuffers.glsl"
}
