#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#include "/global.glsl"

varying float star;

varying vec3 upVec;
varying vec3 sunVec;

varying vec3 tint;

uniform int isEyeInWater;
uniform int worldTime;

uniform float blindness;
uniform float frameCounter;
uniform float frameTimeCounter;
uniform float nightVision;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle;
uniform float timeBrightness;
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;
uniform vec3 sunvec, moonvec;
uniform vec3 sunvecView, moonvecView;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform sampler2D noisetex;

#ifdef WorldTimeAnimation
float frametime = float(worldTime)/20.0*AnimationSpeed;
#else
float frametime = frameTimeCounter*AnimationSpeed;
#endif

float eBS = eyeBrightnessSmooth.y/240.0;
float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.1)/0.1;
float moonVisibility = clamp(dot(-sunVec,upVec)+0.05,0.0,0.1)/0.1;

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

#define gbuffer

#include "/lib/color/lightColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/visual/clouds.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/visual/sky.glsl"

void main(){
    if (star > 0.5) discard;

	//NDC Coordinate
	vec4 fragpos = gbufferProjectionInverse*(vec4(gl_FragCoord.xy/vec2(viewWidth,viewHeight),gl_FragCoord.z,1.0)*2.0-1.0);
	fragpos /= fragpos.w;

    vec3 worldvec    = normalize(mat3(gbufferModelViewInverse) * (fragpos.xyz));
	
	//Render Sky
    vec3 sun_vec    = normalize(mat3(gbufferModelViewInverse) * sunVec);

    mat2x3 light_vec;
        light_vec[0] = sun_vec;
        light_vec[1] = -sun_vec;

    vec3 albedo     = atmos_approx(worldvec, light_vec);
	
	//Round Sun & Moon
	#ifdef RoundSunMoon
        float cosSn = dot(normalize(fragpos.xyz),sunVec);
        float isMoon = float(cosSn < 0.0);
        float sun = pow(abs(cosSn),800.0*isMoon+800.0) * (1.0-sqrt(rainStrength));
        vec3 light_me = mix(light_m,light_a,mefade);
        vec3 suncol = mix(sqrt(light_n)*moonVisibility,mix(light_me,sqrt(light_d*light_me*LightDS),timeBrightness)*sunVisibility,float(cosSn > 0.0));
        albedo += (sun * 32.0) * suncol;
	#endif
	
	albedo *= 1.0+nightVision;

	//Dither
	float dither = bayer64(gl_FragCoord.xy);

	//Stars
	#ifdef Stars
	if (moonVisibility > 0.0) albedo.rgb = drawStars(fragpos.xyz,albedo.rgb,light_n);
	#endif

	//Brighten sky when Light Shaft is disabled
	float cosS = dot(normalize(fragpos.xyz),sunVec*(1.0-2.0*float(timeAngle > 0.5325 && timeAngle < 0.9675)));
	float visfactor = 0.05*(1.0-0.8*timeBrightness)*(3.0*rainStrength+1.0);
	float invvisfactor = 1.0-visfactor;

	float visibility = clamp(cosS*0.5+0.5,0.0,1.0);
	visibility = clamp((visfactor/(1.0-invvisfactor*visibility)-visfactor)*1.015/invvisfactor - 0.015,0.0,1.0);
	visibility = mix(1.0,visibility,0.25*eBS+0.75) * (1.0-rainStrength*eBS*0.875);

	#ifdef LightShaft
	if (isEyeInWater == 1) albedo.rgb += 0.225 * light * visibility * shadowFade;
	#else
	//albedo.rgb += 0.225 * light * visibility * shadowFade;
	#endif

	//Sky Exposure
	albedo.rgb *= 4.0-3.0*eBS;
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(albedo,1.0);
}