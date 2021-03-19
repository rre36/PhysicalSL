#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#include "/global.glsl"

varying vec2 texcoord;

varying vec3 upVec;
varying vec3 sunVec;

varying vec4 color;

uniform int isEyeInWater;
uniform int worldTime;

uniform float nightVision;
uniform float rainStrength;
uniform float timeAngle;
uniform float timeBrightness;
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;

uniform sampler2D texture;
uniform sampler2D gaux1;

float eBS = eyeBrightnessSmooth.y/240.0;
float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.1)/0.1;
float moonVisibility = clamp(dot(-sunVec,upVec)+0.05,0.0,0.1)/0.1;

#include "/lib/color/lightColor.glsl"

void main(){
	//Texture
	vec4 albedo = texture2D(texture, texcoord.xy) * color;

	//Convert to linear color space
	albedo.rgb = pow(albedo.rgb,vec3(2.2)) * SkyboxBrightness * albedo.a;

    /*
	#ifdef Clouds
	if(albedo.a > 0.0){
		float cloudalpha = texture2D(gaux1,gl_FragCoord.xy/vec2(viewWidth,viewHeight)).r;
		cloudalpha /= pow(1.0-0.6*rainStrength,2.0);
		albedo.a *= 1.0-cloudalpha;
	}
	#endif*/
	
	#ifdef SkyDesaturation
	albedo.rgb = mix(length(albedo.rgb)*pow(light_n,vec3(1.6))*4.0,albedo.rgb,sunVisibility);
	#endif
	
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}