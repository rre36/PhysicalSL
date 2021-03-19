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


float rayleigh_phase(float cosTheta) {
    float phase = 0.8 * (1.4 + 0.5 * cosTheta);
    phase *= rcp(pi*4);
  	return phase;
}

float mie_phase(float cosTheta, float g) {
    float mie   = 1.0 + pow2(g) - 2.0*g*cosTheta;
        mie     = (1.0 - pow2(g)) / ((4.0*pi) * mie*(mie*0.5+0.5));
    return mie;
}


/*
Very loosely based on robobos approximation, just jacked up with my own multiscattering approximation which
also fills the sub-horizion area with a less distracting color
*/

#define sunIllum_r 1.00     //[0.00 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30 0.32 0.34 0.36 0.38 0.40 0.42 0.44 0.46 0.48 0.50 0.52 0.54 0.56 0.58 0.60 0.62 0.64 0.66 0.68 0.70 0.72 0.74 0.76 0.78 0.80 0.82 0.84 0.86 0.88 0.90 0.92 0.94 0.96 0.98 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define sunIllum_g 0.94     //[0.00 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30 0.32 0.34 0.36 0.38 0.40 0.42 0.44 0.46 0.48 0.50 0.52 0.54 0.56 0.58 0.60 0.62 0.64 0.66 0.68 0.70 0.72 0.74 0.76 0.78 0.80 0.82 0.84 0.86 0.88 0.90 0.92 0.94 0.96 0.98 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define sunIllum_b 0.92     //[0.00 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30 0.32 0.34 0.36 0.38 0.40 0.42 0.44 0.46 0.48 0.50 0.52 0.54 0.56 0.58 0.60 0.62 0.64 0.66 0.68 0.70 0.72 0.74 0.76 0.78 0.80 0.82 0.84 0.86 0.88 0.90 0.92 0.94 0.96 0.98 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define sunIllum_mult 1.00  //[0.00 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30 0.32 0.34 0.36 0.38 0.40 0.42 0.44 0.46 0.48 0.50 0.52 0.54 0.56 0.58 0.60 0.62 0.64 0.66 0.68 0.70 0.72 0.74 0.76 0.78 0.80 0.82 0.84 0.86 0.88 0.90 0.92 0.94 0.96 0.98 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

#define moonIllum_r 0.60    //[0.00 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30 0.32 0.34 0.36 0.38 0.40 0.42 0.44 0.46 0.48 0.50 0.52 0.54 0.56 0.58 0.60 0.62 0.64 0.66 0.68 0.70 0.72 0.74 0.76 0.78 0.80 0.82 0.84 0.86 0.88 0.90 0.92 0.94 0.96 0.98 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define moonIllum_g 0.80    //[0.00 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30 0.32 0.34 0.36 0.38 0.40 0.42 0.44 0.46 0.48 0.50 0.52 0.54 0.56 0.58 0.60 0.62 0.64 0.66 0.68 0.70 0.72 0.74 0.76 0.78 0.80 0.82 0.84 0.86 0.88 0.90 0.92 0.94 0.96 0.98 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define moonIllum_b 1.00    //[0.00 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30 0.32 0.34 0.36 0.38 0.40 0.42 0.44 0.46 0.48 0.50 0.52 0.54 0.56 0.58 0.60 0.62 0.64 0.66 0.68 0.70 0.72 0.74 0.76 0.78 0.80 0.82 0.84 0.86 0.88 0.90 0.92 0.94 0.96 0.98 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define moonIllum_mult 0.02 //[0.001 0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0-26 0.28 0.30 0.32 0.34 0.36 0.38 0.40 0.42 0.44 0.46 0.48 0.50 0.52 0.54 0.56 0.58 0.60 0.62 0.64 0.66 0.68 0.70 0.72 0.74 0.76 0.78 0.80 0.82 0.84 0.86 0.88 0.90 0.92 0.94 0.96 0.98 1.00]

const vec3 light_coeff  = vec3(0.3, 0.55, 1.0);
const vec3 zenith_coeff = vec3(0.08, 0.19, 1.0);

const vec3 sun_illum    = vec3(sunIllum_r, sunIllum_g, sunIllum_b) * sunIllum_mult;
const vec3 moon_illum   = vec3(moonIllum_r, moonIllum_g, moonIllum_b) * moonIllum_mult;

const float density_coeff = 0.55;
const float horizon_offset = -0.04;

float atmos_density(float x) {
    return density_coeff * rcp(pow(max(x - horizon_offset, 0.35e-3), 0.95));
}
vec3 atmos_absorbtion(vec3 x, float y){
	vec3 absorption = x * -y;
	     absorption = exp(absorption) * 2.0;
    
    return absorption;
}

vec3 atmos_light(vec3 lightvec) {
    vec3 magic_ozone = light_coeff * mix(vec3(1.0, 1.15, 1.0), vec3(1.0), sstep(lightvec, 0.0, 0.2));
    
    return atmos_absorbtion(magic_ozone, atmos_density(lightvec.y));
}

vec3 atmos_approx(vec3 dir, vec3 sunvec, vec3 moonvec) {
    float vDotS = dot(sunvec, dir);
    float vDotM = dot(moonvec, dir);

    mat2x3 phase    = mat2x3(rayleigh_phase(vDotS), mie_phase(vDotS, 0.74), mie_phase(vDotS, 0.65),
                        rayleigh_phase(vDotM), mie_phase(vDotM, 0.74), mie_phase(vDotM, 0.65));
                
    float sun_mult  = sqrt(saturate(length(max(sunvec.y - horizon_offset, 0.0)))) * 0.9;
    float moon_mult = sqrt(saturate(length(max(moonvec.y - horizon_offset, 0.0)))) * 0.9;

    vec3 magic_ozone = zenith_coeff * mix(vec3(1.0, 1.1, 1.0), vec3(1.0), sstep(max(sunvec.y, moonvec.y), 0.0, 0.2));

    float density   = atmos_density(dir.y);
    vec3 absorption = atmos_absorbtion(magic_ozone, density);

    vec3 sunlight   = atmos_light(sunvec) * sun_illum;
    vec3 moonlight  = atmos_light(moonvec) * moon_illum;

    float sun_ms    = phase[0].x * sstep(sunvec.y, horizon_offset, horizon_offset + 0.2) * 1.5 + phase[0].z * 0.5 + 0.1;
        sun_ms     *= 0.5 + sstep(sunvec.y, horizon_offset, horizon_offset + 0.4) * 0.5;

    float moon_ms   = phase[1].x * sstep(moonvec.y, horizon_offset, horizon_offset + 0.2) * 1.5 + phase[1].z;
        moon_ms    *= 0.5 + sstep(moonvec.y, horizon_offset, horizon_offset + 0.4) * 0.5;

    float sun_visibility = sstep(sunvec.y, -0.14, horizon_offset);
        phase[0].y *= sun_visibility;

    float moon_visibility = sstep(sunvec.y, -0.14, horizon_offset);
        phase[1].y *= moon_visibility;
    
    //float sun_rmult  = atmos_rayleigh(dir, sunvec);
    vec3 sun_scatter = zenith_coeff * density;
        sun_scatter  = mix(sun_scatter * absorption, mix(1.0 - exp2(-0.5 * sun_scatter), 0.5 * magic_ozone / (1.0 + magic_ozone), 1.0 - exp2(-0.25 * density)), sun_mult);
        sun_scatter *= sunlight * 0.5 + 0.5 * length(sunlight);
        sun_scatter += (1.0 - exp(-density * magic_ozone)) * sun_ms * sunlight;
        sun_scatter += phase[0].y * sunlight * rcp(pi);

    //float moon_rmult  = atmos_rayleigh(dir, moonvec);
    vec3 moon_scatter = zenith_coeff * density;
        moon_scatter  = mix(moon_scatter * absorption, mix(1.0 - exp2(-0.5 * moon_scatter), 0.5 * magic_ozone / (1.0 + magic_ozone), 1.0 - exp2(-0.25 * density)), moon_mult);
        moon_scatter *= moonlight * 0.5 + 0.5 * length(moonlight);
        moon_scatter += (1.0 - exp(-density * magic_ozone)) * moon_ms * moonlight;
        moon_scatter += phase[1].y * moonlight * rcp(pi);
        moon_scatter  = mix(moon_scatter, dot(moon_scatter, vec3(1.0/3.0)) * vec3(0.2, 0.55, 1.0), 0.8);

    vec3 result     = (sun_scatter) + (moon_scatter);

    return result * rcp(pi);
}
vec3 atmos_approx(vec3 dir, mat2x3 lightvec) {
    return atmos_approx(dir, lightvec[0], lightvec[1]);
}