#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#include "/global.glsl"

const bool colortex1MipmapEnabled = true;

varying vec3 upVec;
varying vec3 sunVec;

varying vec3 sunlight;

varying vec2 texcoord;

uniform int isEyeInWater;
uniform int worldTime;

uniform float blindness;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle;
uniform float timeBrightness;

uniform ivec2 eyeBrightnessSmooth;

uniform sampler2D colortex0;
uniform sampler2D colortex1;

float eBS = eyeBrightnessSmooth.y/240.0;
float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.1)/0.1;

#include "/lib/color/lightColor.glsl"

void main(){
	vec4 color = texture2D(colortex0,texcoord.xy);
	
	//Light Shafts
	#ifdef LightShaft
	vec3 vl = texture2DLod(colortex1,texcoord.xy,1.5).rgb * 12.0;
	
	float b = clamp(blindness*2.0-1.0,0.0,1.0);
	b = b*b;
	
	color.rgb += vl * sunlight * LightShaftStrength * (0.25 * (1.0-rainStrength*eBS*0.875) * (1.0-b)) * 0.4;
	//color.rgb = vl * vl;
	#endif
	
/*DRAWBUFFERS:0*/
	gl_FragData[0] = color;
}
