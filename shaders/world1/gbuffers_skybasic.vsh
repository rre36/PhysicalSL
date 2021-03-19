#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#include "/global.glsl"
 
varying vec3 upVec;
varying vec3 sunVec;

uniform int worldTime;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView;

void main(){
	gl_Position = ftransform();

	upVec = normalize(gbufferModelView[1].xyz);
	
	//Sun position fix from Builderb0y
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = 0.0;
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	
	//upVec = normalize(gbufferModelView[1].xyz);
	//sunVec = normalize(sunPosition);
}