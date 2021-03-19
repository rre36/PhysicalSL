#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#include "/global.glsl"

varying vec3 upVec;
varying vec3 sunVec;

uniform float timeAngle;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView;

varying vec3 tint;

varying float star;

void main(){
	gl_Position = ftransform();

	upVec = normalize(gbufferModelView[1].xyz);

    tint    = gl_Color.rgb;
	
	//Sun position fix from Builderb0y
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));

	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	
	//upVec = normalize(gbufferModelView[1].xyz);
	//sunVec = normalize(sunPosition);

	float isStar = float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0);

	star = isStar;
}