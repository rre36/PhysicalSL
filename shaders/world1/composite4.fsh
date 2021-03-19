#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

const bool colortex0MipmapEnabled = true;

varying vec2 texcoord;

uniform sampler2D colortex0;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;

float pw = 1.0 / viewWidth;
float ph = 1.0 / viewHeight;
float pi = 3.1415927;

#include "/lib/post/bloomTile.glsl"

void main(){
	//Bloom
	vec3 blur = vec3(0);
	blur += bloomTile(2,vec2(0.0,0.0));
	blur += bloomTile(3,vec2(0.0,0.26));
	blur += bloomTile(4,vec2(0.135,0.26));
	blur += bloomTile(5,vec2(0.2075,0.26));
	blur += bloomTile(6,vec2(0.135,0.3325));
	blur += bloomTile(7,vec2(0.160625,0.3325));
	blur += bloomTile(8,vec2(0.1784375,0.3325));

/* DRAWBUFFERS:1 */
	gl_FragData[0] = vec4(blur, 1.0);
}
