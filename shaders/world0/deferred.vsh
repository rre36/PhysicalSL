#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#include "/global.glsl"

varying vec3 upVec;
varying vec3 sunVec;

varying vec3 _sunlight;
varying vec3 _skylight;

varying vec2 texcoord;

uniform int cloud_sunlight;

uniform int worldTime;

uniform float timeAngle;

uniform float sunAngle;
uniform float shadowFade;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

#include "/lib/visual/sky.glsl"

void main(){
	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0.xy;
	
	//Sun position fix from Builderb0y
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	
	upVec = normalize(gbufferModelView[1].xyz);
	//sunVec = normalize(sunPosition);

    vec3 sun_vec    = normalize(mat3(gbufferModelViewInverse) * sunVec);

    mat2x3 light_vec;
        light_vec[0] = sun_vec;
        light_vec[1] = -sun_vec;

    _skylight = atmos_approx(vec3(0.0, 1.0, 0.0), light_vec) * pi;
    _sunlight = (worldTime>23000 || worldTime<12900) ? atmos_light(sun_vec) * sun_illum : atmos_light(-sun_vec) * moon_illum * vec3(0.4, 0.7, 1.3) * 1.3;
}
