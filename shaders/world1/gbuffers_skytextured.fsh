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
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;

uniform sampler2D texture;

void main(){
	//Texture
	vec4 albedo = texture2D(texture, texcoord.xy);
	
	//Convert to linear color space
	albedo.rgb = pow(albedo.rgb,vec3(2.2)) * SkyboxBrightness * 0.01;
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}