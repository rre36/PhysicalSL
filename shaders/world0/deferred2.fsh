#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#include "/global.glsl"

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
uniform float nightVision;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle;
uniform float timeBrightness;
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;

#if (defined RPSupport && defined ReflectSpecular) || defined ReflectRain
uniform float wetness;

uniform vec3 previousCameraPosition;

uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
#endif

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;

#if (defined RPSupport && defined ReflectSpecular) || defined ReflectRain
uniform sampler2D colortex3;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
#endif

#ifdef WorldTimeAnimation
float frametime = float(worldTime)/20.0*AnimationSpeed;
#else
float frametime = frameTimeCounter*AnimationSpeed;
#endif

float eBS = eyeBrightnessSmooth.y/240.0;
float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.1)/0.1;
float moonVisibility = clamp(dot(-sunVec,upVec)+0.05,0.0,0.1)/0.1;

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float ld(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

float gradNoise(){
	return fract(52.9829189*fract(0.06711056*gl_FragCoord.x + 0.00583715*gl_FragCoord.y)+frameCounter/8.0);
}

#if (defined RPSupport && defined ReflectSpecular) || defined ReflectRain
float getReflectionAlpha(sampler2D colortex, sampler2D depthtex, vec2 pos){
	return float(texture2D(depthtex, pos).r < 1.0);
}
#endif

#include "/lib/color/lightColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/color/torchColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/fog/overlandFog.glsl"
#include "/lib/fog/commonFog.glsl"
#include "/lib/visual/ambientOcclusion.glsl"
#include "/lib/visual/promoOutline.glsl"
#include "/lib/visual/clouds.glsl"
#include "/lib/visual/sky.glsl"

#ifdef BlackOutline
#include "/lib/fog/waterFog.glsl"
#include "/lib/visual/blackOutline.glsl"
#endif

#ifdef RPSupport
#include "/lib/rps/labMetal.glsl"
#endif

#if (defined RPSupport && defined ReflectSpecular) || defined ReflectRain
#include "/lib/visual/screenSpaceReflection.glsl"
#endif

void main(){
	vec4 color = texture2D(colortex0,texcoord.xy);
	float z = texture2D(depthtex0,texcoord.xy).r;
	
	//Dither
	float dither = bayer64(gl_FragCoord.xy);
	
	//NDC Coordinate
	vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, z, 1.0) * 2.0 - 1.0);
	fragpos /= fragpos.w;
	
	if (z < 1.0){
		//Specular Reflection
		#if (defined RPSupport && defined ReflectSpecular) || defined ReflectRain
		float smoothness = texture2D(colortex3,texcoord.xy).r;
		float smoothness2 = smoothness * smoothness;
		float f0 = texture2D(colortex3,texcoord.xy).g;
		float skymap = texture2D(colortex3,texcoord.xy).b;
		vec3 normal = texture2D(colortex6,texcoord.xy).xyz*2.0-1.0;
		
		float fresnel = pow(clamp(1.0 + dot(normal, normalize(fragpos.xyz)),0.0,1.0),5.0);
		vec3 fresnel3 = vec3(mix(f0, 1.0, fresnel));
		#ifdef RPSupport
		#if SpecularFormat == 0
		if (f0 >= 0.9 && f0 < 1.0) fresnel3 = complexFresnel(fresnel, f0);
		#endif
		#endif
		fresnel3 *=  smoothness2;
		
		#ifdef ReflectRough
		vec2 noisecoord = texcoord.xy*vec2(viewWidth,viewHeight)/512.0;
		#if AA == 2
		noisecoord += fract(frameCounter*vec2(0.4,0.25));
		#endif
		#endif
		
		if (length(fresnel3) > 0.05 * length(color.rgb)){
			vec4 reflection = vec4(0.0);
			vec3 skyRef = vec3(0.0);

			#ifdef ReflectPrevious
			#define colortexR colortex5
			#else
			#define colortexR colortex0
			#endif

			#ifdef ReflectRough
			if (smoothness >= 0.9) reflection = raytrace(colortexR,depthtex0,fragpos.xyz,normal,dither);
			else reflection = raytraceRough(colortexR,depthtex0,fragpos.xyz,normal,dither,1.0-smoothness,noisecoord);
			#else
			reflection = raytrace(colortexR,depthtex0,fragpos.xyz,normal,dither);
			#endif

			#ifdef ReflectPrevious
			reflection.rgb = pow(reflection.rgb*2.0,vec3(8.0));
			#endif

			if (reflection.a < 1.0){
				vec3 skyRefPos = reflect(normalize(fragpos.xyz),normal);
				#ifdef ReflectRough
				if (smoothness < 0.95){
					float r = 1.0-smoothness;
					r *= r;

					vec3 noise = vec3(texture2D(noisetex,noisecoord).xy*2.0-1.0,0.0);
					if (length(noise.xy) > 0) noise.xy /= length(noise.xy);
					noise.xy *= 0.7*r;
					noise.z = 1.0 - (noise.x * noise.x + noise.y * noise.y);

					vec3 tangent = normalize(cross(gbufferModelView[1].xyz, normal));
					mat3 tbnMatrix = mat3(tangent, cross(normal, tangent), normal);

					skyRefPos = reflect(normalize(fragpos.xyz),normalize(tbnMatrix * noise));
				}
				#endif
                vec3 worldvec    = normalize(mat3(gbufferModelViewInverse) * skyRefPos);
                vec3 sun_vec    = normalize(mat3(gbufferModelViewInverse) * sunVec);
                skyRef  = atmos_approx(worldvec, sun_vec, -sun_vec);
				#ifdef Clouds
				vec4 cloud = drawCloud(skyRefPos*2048.0, dither, skyRef, light, ambient);
				skyRef = mix(skyRef,cloud.rgb,cloud.a);
				#endif
				skyRef *= (4.0-3.0*eBS)*skymap;
			}

			reflection.rgb = mix(skyRef,reflection.rgb,reflection.a);
			
			vec3 spec = texture2D(colortex7,texcoord.xy).rgb;
			if (f0 >= 0.9){
				reflection.rgb += vec3(0.001) * (1.0 - reflection.a) * (1.0 - skymap);
				if (f0 == 1.0) fresnel3 = mix(spec * 0.8, vec3(1.0), fresnel) * smoothness2;
				color.rgb += reflection.rgb * fresnel3;
			}else{
				spec = 4.0 * fresnel3 * spec/(1.0-spec);
				color.rgb = mix(color.rgb, reflection.rgb, fresnel3)+spec;
			}
		}
		#endif
		
		//Ambient Occlusion
		#ifdef AO
		color.rgb *= dbao(depthtex0, dither);
		#endif

		//Promo Art Outline
		#ifdef PromoOutline
		color.rgb = promooutline(color.rgb, depthtex0);
		#endif
		
		//Fog
		#ifdef Fog
		color.rgb = calcFog(color.rgb, fragpos.xyz, blindness);
		#endif
	}else{
		//Lava Fog
		if (isEyeInWater == 2){
			#ifdef EmissiveRecolor
			color.rgb = pow(Torch/TorchS,vec3(4.0))*2.0;
			#else
			color.rgb = vec3(1.0,0.3,0.01);
			#endif
		}

		//Blindness
		float b = clamp(blindness*2.0-1.0,0.0,1.0);
		b = b*b;
		if (blindness > 0.0) color.rgb *= 1.0-b;
	}
	
	//Black Outline
	#ifdef BlackOutline
	color.rgb = blackoutline(depthtex0, color.rgb, 1.0 + eBS);
	#endif

/*DRAWBUFFERS:03*/
	gl_FragData[0] = color;
    gl_FragData[1] = vec4(0.0);
	#ifndef ReflectPrevious
/*DRAWBUFFERS:035*/
	gl_FragData[2] = vec4(pow(color.rgb,vec3(0.125)) * 0.5, float(z < 1.0));
	#endif
}
