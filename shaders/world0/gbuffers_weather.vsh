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

uniform float timeAngle;


uniform mat4 gbufferModelView;

void main(){
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
	
	gl_Position = ftransform();
	
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = clamp(lmcoord*2.0-1.0,0.0,1.0);

	//Sun position fix from Builderb0y
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	
	upVec = normalize(gbufferModelView[1].xyz);
	//sunVec = normalize(sunPosition);
}