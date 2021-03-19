#version 120
#extension GL_ARB_shader_texture_lod : enable
#extension GL_EXT_gpu_shader4 : enable

/*
====================================================================================================

    Copyright (C) 2020 RRe36

    All Rights Reserved unless otherwise explicitly stated.


    By downloading this you have agreed to the license and terms of use.
    These can be found inside the included license-file
    or here: https://rre36.github.io/license/

    Violating these terms may be penalized with actions according to the Digital Millennium
    Copyright Act (DMCA), the Information Society Directive and/or similar laws
    depending on your country.

====================================================================================================
*/

#include "/global.glsl"

const int noiseTextureResolution = 256;

varying vec3 upVec;
varying vec3 sunVec;

varying vec3 _sunlight;
varying vec3 _skylight;

varying vec2 texcoord;

uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;
uniform int cloud_sunlight;

uniform float aspectRatio;
uniform float blindness;
uniform float eyeAltitude;
uniform float far;
uniform float frameTimeCounter;
uniform float near;
uniform float nightVision;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle;
uniform float timeBrightness;
uniform float viewWidth;
uniform float viewHeight;
uniform float wetness;

uniform ivec2 eyeBrightnessSmooth;

uniform vec2 pixelSize;

uniform vec3 cameraPosition;
uniform vec3 sunvec;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;

#ifdef WorldTimeAnimation
float frametime = float(worldTime)/20.0*AnimationSpeed;
#else
float frametime = frameTimeCounter*AnimationSpeed;
#endif

#include "/lib/visual/sky.glsl"

float max_depth3x3(sampler2D depthtex, vec2 coord, vec2 px) {
    float tl    = texture2D(depthtex, coord + vec2(-px.x, -px.y)).x;
    float tc    = texture2D(depthtex, coord + vec2(0.0, -px.y)).x;
    float tr    = texture2D(depthtex, coord + vec2(px.x, -px.y)).x;
    float tmin  = max(tl, max(tc, tr));

    float ml    = texture2D(depthtex, coord + vec2(-px.x, 0.0)).x;
    float mc    = texture2D(depthtex, coord).x;
    float mr    = texture2D(depthtex, coord + vec2(px.x, 0.0)).x;
    float mmin  = max(ml, max(mc, mr));

    float bl    = texture2D(depthtex, coord + vec2(-px.x, px.y)).x;
    float bc    = texture2D(depthtex, coord + vec2(0.0, px.y)).x;
    float br    = texture2D(depthtex, coord + vec2(px.x, px.y)).x;
    float bmin  = max(bl, max(bc, br));

    return max(tmin, max(mmin, bmin));
}

float dither_bluenoise() {
    ivec2 coord = ivec2(fract(gl_FragCoord.xy/256.0)*256.0);
    float noise = texelFetch2D(noisetex, coord, 0).a;

    #if AA == 2
        noise   = fract(noise+float(frameCounter)/pi);
    #endif

    return noise;
}

float lin_step(float x, float low, float high) {
    float t = saturate((x-low)/(high-low));
    return t;
}

vec3 noise_2d(vec2 pos) {
    return texture2D(noisetex, pos).xyz;
}
float value_3d(vec3 pos) {
    vec3 p  = floor(pos); 
    vec3 b  = fract(pos);

    vec2 uv = (p.xy+vec2(-97.0)*p.z)+b.xy;
    vec2 rg = texture2D(noisetex, (uv)/256.0).xy;

    return cube_smooth(mix(rg.x, rg.y, b.z));
}

float cloud_phase(float cos_theta, float g) {
    float a     = mie_phase(cos_theta, 0.44*g)+mie_phase(cos_theta, 0.89*g)*0.75;
    float b     = mie_phase(cos_theta, -0.25*g) * 1.44;

    return mix(a, b, 0.38) + 0.01 * g;
}

#define vcloud_samples 60   //[20 30 40 50 60 70 80 90 100]
#define vcloud_alt 1e3      //[3e2 4e2 5e2 6e2 7e2 8e2 9e2 1e3 2e3 3e3 4e3]
#define vcloud_depth 4e3    //[1e3 2e3 3e3 4e3 5e3 6e3 7e3 8e3]
#define vcloud_clip 2e5

#define vcloud_detail 1     //[0 1]
#define vcloud_coverage 0.0 //[-0.5 -0.4 -0.3 -0.2 -0.1 0.0 0.1 0.2 0.3 0.4 0.5]

const float vc_size         = 0.00062;
const float vc_highedge     = vcloud_alt + vcloud_depth;

float vcloud_time   = frametime * 0.2;

float vcloud_shape(vec3 pos) {
    float altitude      = pos.y;

    float erode_low     = 1.0-sstep(altitude, vcloud_alt, vcloud_alt+vcloud_depth*0.13);
    float erode_high    = sstep(altitude, vcloud_alt+vcloud_depth*0.16, vc_highedge);
    float fade_low      = sstep(altitude, vcloud_alt, vcloud_alt+vcloud_depth*0.075);
    float fade_high     = 1.0-sstep(altitude, vcloud_alt+vcloud_depth*0.65, vc_highedge);

    vec3 wind       = vec3(vcloud_time, 0.0, vcloud_time*0.6);

    pos            *= vc_size;
    pos            += wind*0.1;

    float coverage_bias = 0.52 - wetness*0.3 - vcloud_coverage;

    float coverage  = noise_2d(pos.xz*0.028).b;
        coverage    = (coverage - coverage_bias) * rcp(1.0 - saturate(coverage_bias));

        coverage   *= fade_low;
        coverage   *= fade_high;
        coverage   -= erode_low*0.25;
        coverage   -= erode_high*0.7;

        coverage    = saturate(coverage * 1.1);
        
    if (coverage <= 0.0) return 0.0;

    float wfade     = sstep(altitude, vcloud_alt, vcloud_alt+vcloud_depth*0.33)*0.5+0.5;

    float dfade     = 0.01 + sstep(altitude, vcloud_alt, vcloud_alt+vcloud_depth*0.2)*0.2;
        dfade      += sstep(altitude, vcloud_alt+vcloud_depth*0.1, vcloud_alt+vcloud_depth*0.55)*0.65;
        dfade      += sstep(altitude, vcloud_alt+vcloud_depth*0.2, vcloud_alt+vcloud_depth*0.65)*3.0;
        dfade      += sstep(altitude, vcloud_alt+vcloud_depth*0.4, vc_highedge-vcloud_depth*0.15)*2.0;

    float shape     = coverage;
    float slope     = sqrt(1.0 - saturate(shape));

        pos.xy += shape * 0.5;
    float n1        = value_3d(pos * 6.0) * 0.3 * wfade;
        shape      -= n1 * slope;   pos -= n1 * 0.5;

    if (shape <= 0.0) return 0.0;

    #if vcloud_detail >= 1
        slope      = sqrt(1.0 - saturate(shape));
        shape      -= value_3d(pos * 24.0) * 0.15 * slope;
    #endif

    return max(shape * dfade, 0.0);
}

uniform vec3 cloud_lvec;

float vcloud_light(vec3 pos, vec3 dir, const int steps, float upmix) {
    float stepsize  = vcloud_depth / steps;
        stepsize   *= 1.0 - upmix * 0.9;

    float density   = 0.0;

    for (int i = 0; i < steps; ++i, pos += dir * stepsize) {
        if (pos.y > vc_highedge || pos.y < vcloud_alt) continue;

        density  += vcloud_shape(pos) * stepsize;
    }

    return density;
}

vec4 compute_vcloud(vec3 wvec) {
    bool visible    = wvec.y > 0.0;

    if (visible) {
        vec3 bs     = wvec*((vcloud_alt-eyeAltitude)/wvec.y);
        vec3 ts     = wvec*((vc_highedge-eyeAltitude)/wvec.y);

        vec3 spos   = bs;
        vec3 epos   = ts;

        float dither = dither_bluenoise();

        const float bl  = vcloud_depth / vcloud_samples;
        float stepl     = length((epos-spos)/vcloud_samples);
        float stepcoeff = stepl/bl;
            stepcoeff   = 0.45+clamp(stepcoeff-1.1, 0.0, 4.0)*0.5;
            //stepcoeff   = mix(stepcoeff, 10.0, pow2(within));
        int steps       = int(vcloud_samples*stepcoeff);

        vec3 rstep  = (epos-spos)/steps;
        vec3 rpos   = rstep*dither + spos + cameraPosition;
        float rlength = length(rstep);

        vec3 scatter    = vec3(0.0);
        float transmittance = 1.0;

        mat2x3 light_vec;
            light_vec[0] = sunvec;
            light_vec[1] = -sunvec;

        vec3 skycol     = atmos_approx(wvec, light_vec);

        vec3 sunlight   = _sunlight;
            sunlight   *= tau * pi;
        vec3 skylight   = _skylight;

        float vdotl     = dot(wvec, cloud_lvec);

        float pfade     = saturate(mie_phase(vdotl, 0.55));

        const float sigma_a = 1.00;         //absorption coeff
        const float sigma_s = 0.10;         //scattering coeff, can technically be assumed to be sigma_t since the albedo is close to 1.0
        const float sigma_t = 0.10;         //extinction coeff, 0.05-0.12 for cumulus, 0.04-0.06 for stratus

        float upmix     = saturate(dot(vec3(0.0, 1.0, 0.0), cloud_lvec));

        for (int i = 0; i<steps; ++i, rpos += rstep) {
            if (transmittance < 0.075) break;
            if (rpos.y < vcloud_alt || rpos.y > vc_highedge) continue;

            float dist  = distance(rpos, cameraPosition);
            if (dist > vcloud_clip) continue;

            float density   = vcloud_shape(rpos);
            if (density<=0.0) continue;

            float extinction = density * sigma_t;
            float stept     = exp(-extinction*rlength);
            float integral  = (1.0 - stept) / sigma_t;

            vec2 step_scatter = vec2(0.0);

            float direct_d    = vcloud_light(rpos, cloud_lvec, 5, upmix);
            float sky_d       = vcloud_light(rpos, vec3(0.0, 1.0, 0.0), 3, 1.0);

            float powder    = 1.0 - exp(-density * 15.0);
            float dpowder   = mix(powder, 1.0, pfade);

            float s_d   = sigma_s;
            float t_d   = sigma_t;

            for (int j = 0; j<4; ++j) {
                float n     = float(j);

                s_d    *= 0.33;
                t_d    *= 0.33;

                float phase     = cloud_phase(vdotl, pow(0.33, n));

                step_scatter.x += exp(-direct_d * t_d) * phase * dpowder * s_d;
                step_scatter.y += exp(-sky_d * t_d) * powder * s_d;
            }

            vec3 col        = (sunlight * step_scatter.x) + (skylight * step_scatter.y);

            float atmosfade = exp(-dist * 3.3e-5);
                col     = mix(skycol * sigma_t, col, atmosfade);

            float fade  = 1.0 - sstep(dist, vcloud_clip * 0.7, vcloud_clip);
            
            scatter     += col * integral * transmittance * fade;

            stept   = mix(1.0, stept, fade);

            transmittance  *= stept;
        }
        transmittance = lin_step(transmittance, 0.075, 1.0);

        vec3 color  = scatter;

        return vec4(color, transmittance);
    } else {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }
}

#define viewMAD(m, v) (mat3(m) * (v) + (m)[3].xyz)
#define diag3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define diag4(mat) vec4(diag3(mat), (mat)[2].w)
#define projMAD(m, v) (diag3(m) * (v) + (m)[3].xyz)

vec3 screen_viewspace(vec3 screenpos, mat4 projInv) {
    screenpos   = screenpos*2.0-1.0;

    vec3 viewpos    = vec3(vec2(projInv[0].x, projInv[1].y)*screenpos.xy + projInv[3].xy, projInv[3].z);
        viewpos    /= projInv[2].w*screenpos.z + projInv[3].w;
    
    return viewpos;
}
vec3 screen_viewspace(vec3 screenpos) {
    return screen_viewspace(screenpos, gbufferProjectionInverse);
}

vec3 view_scenespace(vec3 viewpos, mat4 mvInv) {
    return viewMAD(mvInv, viewpos);
}
vec3 view_scenespace(vec3 viewpos) {
    return view_scenespace(viewpos, gbufferModelViewInverse);
}

void main(){
    const float cLOD    = sqrt(CloudRenderLOD);

    vec2 scalecoord  = (texcoord-vec2(1.0-rcp(cLOD), 0.0))*cLOD;

    float d     = max_depth3x3(depthtex0, scalecoord, pixelSize*cLOD);

    vec4 return1    = vec4(0.0, 0.0, 0.0, 1.0);

    if (clamp(scalecoord, -0.003, 1.003) == scalecoord && !landMask(d)) {
        scalecoord      = clamp(scalecoord, 0.0, 1.0);
        vec3 viewpos    = screen_viewspace(vec3(scalecoord, 1.0));
        vec3 viewvec    = normalize(viewpos);
        vec3 scenepos   = view_scenespace(viewpos);
        vec3 svec       = normalize(scenepos);

        return1     = compute_vcloud(svec);
    }

    #ifdef Clouds
    /* - */
    #endif

    /*DRAWBUFFERS:1*/
	gl_FragData[0] = clamp(return1, 0.0, 65535.0);
}
