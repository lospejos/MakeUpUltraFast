#include "/lib/config.glsl"

/* Color utils */

#ifdef THE_END
    #include "/lib/color_utils_end.glsl"
#elif defined NETHER
    #include "/lib/color_utils_nether.glsl"
#else
    #include "/lib/color_utils.glsl"
#endif

/* Ins / Outs */

varying vec2 texcoord;
varying vec4 tintColor;
varying float sky_luma_correction;
varying vec2 quad_xy;
varying float quad_corner;
varying float is_sun;

uniform vec3 sunPosition;

#if AA_TYPE > 0
    #include "/src/taa_offset.glsl"
#endif

/* Utility functions */

#include "/lib/luma.glsl"

// MAIN FUNCTION ------------------

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    tintColor = gl_Color;
    // Position inside the sun/moon quad: 2D coords in the plane facing the camera (sun at +sunPosition, moon opposite)
    vec3 vp = (gl_ModelViewMatrix * gl_Vertex).xyz;
    is_sun = step(0.0, dot(vp, sunPosition));
    vec3 center_dir = normalize(sunPosition) * (is_sun * 2.0 - 1.0);
    vec3 ref_up = abs(center_dir.y) > 0.99 ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);
    vec3 quad_up = normalize(ref_up - center_dir * dot(ref_up, center_dir));
    vec3 quad_right = cross(center_dir, quad_up);
    quad_xy = vec2(dot(vp, quad_right), dot(vp, quad_up));
    quad_corner = length(quad_xy);  // same at all 4 corners; edge midpoint = this / sqrt(2)

    sky_luma_correction = luma(dayBlend(LIGHT_SUNSET_COLOR, LIGHT_DAY_COLOR, LIGHT_NIGHT_COLOR));

    #if defined UNKNOWN_DIM
        sky_luma_correction = 1.0;
    #else
        #if (VOL_LIGHT == 1 && !defined NETHER) || (VOL_LIGHT == 2 && defined SHADOW_CASTING && !defined NETHER)
            sky_luma_correction = 3.5 / ((sky_luma_correction * -2.5) + 3.5);
        #else
            sky_luma_correction = 1.5 / ((sky_luma_correction * -2.5) + 3.5);
        #endif
    #endif

    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;

    #if AA_TYPE > 0
        gl_Position.xy += taaOffset * gl_Position.w;
    #endif
}
