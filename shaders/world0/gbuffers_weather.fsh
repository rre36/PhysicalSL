#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#include "/global.glsl"

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 upVec;
varying vec3 sunVec;

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
uniform sampler2D depthtex0;

float eBS = eyeBrightnessSmooth.y/240.0;
float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.1)/0.1;

vec3 toNDC(vec3 pos){
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
    vec3 p3 = pos * 2. - 1.;
    vec4 fragpos = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return fragpos.xyz / fragpos.w;
}

#include "/lib/color/lightColor.glsl"
#include "/lib/color/torchColor.glsl"

void main(){
	vec4 albedo = vec4(0.0);
	
	#ifdef Weather
	//Texture
	albedo.a = texture2D(texture, texcoord.xy).a;
	
	if (albedo.a > 0.001){
		albedo.rgb = texture2D(texture, texcoord.xy).rgb;
		albedo.a *= 0.2 * rainStrength * length(albedo.rgb/3.0)*float(albedo.a > 0.1);
		albedo.rgb = sqrt(albedo.rgb);
		albedo.rgb *= (ambient + lmcoord.x * lmcoord.x * torch_c) * WeatherOpacity;
		
		#ifdef Fog
		if (gl_FragCoord.z > 0.991){
			float z = texture2D(depthtex0,gl_FragCoord.xy/vec2(viewWidth,viewHeight)).r;
			if (z < 1.0){
				vec3 fragpos = toNDC(vec3(gl_FragCoord.xy/vec2(viewWidth,viewHeight),z));
				float fog = length(fragpos)/(FogRange*50.0*(sunVisibility*0.5+1.5))*(1.5*rainStrength+1.0)*eBS;
				fog = 1.0-exp(-2.0*fog*mix(sqrt(fog),1.0,rainStrength));
				albedo.rgb /= 1.0-fog;
			}
		} 
		#endif
	}
	#endif
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}