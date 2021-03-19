#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#include "/global.glsl"

const float shadowMapBias = 1.0-25.6/shadowDistance;

const bool colortex5Clear = false;

varying vec3 upVec;
varying vec3 sunVec;

varying vec2 texcoord;

uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

uniform float aspectRatio;
uniform float blindness;
uniform float far;
uniform float frameTimeCounter;
uniform float near;
uniform float rainStrength;
uniform float timeAngle;
uniform float timeBrightness;
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;
uniform vec3 sunvec;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;

float eBS = eyeBrightnessSmooth.y/240.0;
float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.1)/0.1;

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float ld(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

#include "/lib/color/waterColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/fog/waterFog.glsl"
#include "/lib/visual/ambientOcclusion.glsl"
#include "/lib/visual/promoOutline.glsl"
#include "/lib/visual/volumetricLight.glsl"
#include "/lib/color/lightColor.glsl"

#ifdef BlackOutline
#include "/lib/color/skyColor.glsl"
#include "/lib/color/torchColor.glsl"
#include "/lib/fog/overlandFog.glsl"
#include "/lib/fog/commonFog.glsl"
#include "/lib/visual/blackOutline.glsl"
#endif

vec3 water_fog(vec3 scenecolor, float d, vec3 color) {
    float dist      = max(0.0, d);
    float density   = dist*6.5e-1;
    vec3 scatter   = 1.0-exp(-min(density*0.8, 64e-1)*vec3(0.02, 0.24, 1.0));
    vec3 transmittance = exp(-density*vec3(1.0, 0.28, 0.06)*1.2);

    return scenecolor*transmittance + color*scatter*0.3;
}

void main(){
	vec4 color = texture2D(colortex0,texcoord.xy);
	float z = texture2D(depthtex0,texcoord.xy).r;
	float z1 = texture2D(depthtex1,texcoord.xy).r;
	
	//Dither
	#if defined AO || defined LightShaft
	float dither = bayer64(gl_FragCoord.xy);
	#endif
	/*
    // not sure what this even does but it's ditched now
	//Ambient Occlusion
	#ifdef AO
	if (z1-z > 0 && ld(z)*far < 32.0){
		vec3 rawtranslucent = texture2D(colortex1,texcoord.xy).rgb;
		if (dot(rawtranslucent,rawtranslucent) < 0.02) color.rgb *= mix(dbao(depthtex0, dither),1.0,clamp(0.03125*ld(z)*far,0.0,1.0));
		}
	#endif*/
	
	//Underwater Fog
    bool water     = texture2D(colortex3, texcoord).x > 0.5;

	if (isEyeInWater == 1.0){
		vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, z, 1.0) * 2.0 - 1.0);
		fragpos /= fragpos.w;
		
		//Blindness
		float b = clamp(blindness*2.0-1.0,0.0,1.0);
		b = 1.0-b*b;
		
		color.rgb = calcWaterFog(color.rgb, fragpos.xyz, water_c*b, cmult, wfogrange*(1.0+eBS));
	} else if (water) {
		vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, z, 1.0) * 2.0 - 1.0);
		fragpos /= fragpos.w;

        vec4 fragpos1 = gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, z1, 1.0) * 2.0 - 1.0);
		fragpos1 /= fragpos1.w;

        color.rgb   = water_fog(color.rgb, distance(fragpos.xyz, fragpos1.xyz), ambient * 0.25 + light * 0.05);
    }
	
	//Black Outline
	#ifdef BlackOutline
	if (blackoutlinemask(depthtex0,depthtex1) > 0.5 || isEyeInWater > 0.5)
		color.rgb = blackoutline(depthtex0, color.rgb, 1.0 + eBS);
	#endif
	
	//Promo Art Outline
	#ifdef PromoOutline
	if (z1-z > 0) color.rgb = promooutline(color.rgb, depthtex0);
	#endif
	
	//Prepare light shafts
    //or not, gonna use proper volume fog instead
	#ifdef LightShaft
	vec3 rawtranslucent = vec3(1.0);
	vec3 vl = getVolumetricRays(z, z1, rawtranslucent, dither) * (1.0 - sstep(sunvec.y, 0.0, 0.25) * 0.7);
	#else
	vec3 vl = vec3(0.0);
	#endif

    vec4 tex1   = texture2D(colortex1, texcoord);

    color.rgb   = mix(color.rgb, tex1.rgb / max(tex1.a, 1e-8), tex1.a);
	
/*DRAWBUFFERS:01*/
	gl_FragData[0] = color;
	gl_FragData[1] = vec4(vl / 12.0,1.0);
	#ifdef ReflectPrevious
/*DRAWBUFFERS:015*/
	gl_FragData[2] = vec4(pow(color.rgb, vec3(0.125)) * 0.5, float(z < 1.0));
	#endif
}
