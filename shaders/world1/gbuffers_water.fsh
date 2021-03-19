#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

/*
Note : gbuffers_basic, gbuffers_entities, gbuffers_hand, gbuffers_terrain, gbuffers_textured, and gbuffers_water contains mostly the same code. If you edited one of these files, you need to do the same thing for the rest of the file listed.
*/

#include "/global.glsl"
 
const float shadowMapBias = 1.0-25.6/shadowDistance;

varying float dist;
varying float mat;

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 binormal;
varying vec3 normal;
varying vec3 sunVec;
varying vec3 tangent;
varying vec3 upVec;
varying vec3 viewVector;
varying vec3 wpos;

varying vec4 color;

#ifdef RPSupport
varying vec4 vtexcoordam;
varying vec4 vtexcoord;
#endif

uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

uniform float blindness;
uniform float frameTimeCounter;
uniform float nightVision;
uniform float rainStrength;
uniform float screenBrightness; 
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform sampler2D texture;
uniform sampler2D gaux2;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;

#ifdef RPSupport
uniform sampler2D specular;
uniform sampler2D normals;
#endif

#ifdef RPSupport
vec2 dcdx = dFdx(texcoord.xy);
vec2 dcdy = dFdy(texcoord.xy);
#endif

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float gradNoise(){
	return fract(52.9829189*fract(0.06711056*gl_FragCoord.x + 0.00583715*gl_FragCoord.y)+frameCounter/8.0);
}

#ifdef WorldTimeAnimation
float frametime = float(worldTime)/20.0*AnimationSpeed;
#else
float frametime = frameTimeCounter*AnimationSpeed;
#endif

float waterH(vec3 pos, vec3 fpos) {
	float noise = 0;

	float mult = clamp((-dot(normalize(normal),normalize(fpos)))*8.0,0.0,1.0)/sqrt(sqrt(max(dist,4.0)));
	float lacunarity = 1.0;
	float persistance = 1.0;
	float weight = 0.0;
	
	if (mult > 0.01){
		#if WaterNormals == 1
		noise  = texture2D(noisetex,(pos.xz+vec2(frametime)*0.35-pos.y*0.2)/512.0* 1.1).r*1.0;
		noise += texture2D(noisetex,(pos.xz-vec2(frametime)*0.35-pos.y*0.2)/512.0* 1.5).r*0.8;
		noise -= texture2D(noisetex,(pos.xz+vec2(frametime)*0.35+pos.y*0.2)/512.0* 2.5).r*0.6;
		noise += texture2D(noisetex,(pos.xz-vec2(frametime)*0.35-pos.y*0.2)/512.0* 5.0).r*0.4;
		noise -= texture2D(noisetex,(pos.xz+vec2(frametime)*0.35+pos.y*0.2)/512.0* 8.0).r*0.2;
		noise *= mult;
		#endif
		#if WaterNormals == 2
		for(int i = 0; i < WaterOctave; i++){
			float mult = (mod(i,2))*2.0-1.0;
			noise += texture2D(noisetex,(pos.xz+vec2(frametime)*WaterSpeed*0.35*mult+pos.y*0.2*mult)/WaterSize * lacunarity).r*persistance*mult;
			if (i==0) noise = -noise;
			weight += persistance;
			lacunarity *= WaterLacunarity;
			persistance *= WaterPersistance;
		}
		noise *= mult * WaterBump / weight * WaterSize / 450.0;
		#endif
	}

	return noise;
}

vec3 getParallaxWaves(vec3 posxz, vec3 viewVector,vec3 fragpos) {
	vec3 parallaxPos = posxz;
	float waveH = (waterH(posxz,fragpos.xyz)-0.5)*0.2;
	
	for(int i = 0; i < 4; i++){
		parallaxPos.xz += waveH*(viewVector.xy)/dist;
		waveH = (waterH(parallaxPos,fragpos.xyz)-0.5)*0.2;
	}
	return parallaxPos;
}

float getReflectionAlpha(sampler2D colortex, sampler2D depthtex, vec2 pos){
	return texture2D(colortex, pos).a;
}

#include "/lib/color/endColor.glsl"
#include "/lib/color/torchColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/fog/endFog.glsl"
#include "/lib/fog/commonFog.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/rps/ggx.glsl"
#include "/lib/visual/screenSpaceReflection.glsl"
#include "/lib/visual/shadows.glsl"

#ifdef RPSupport
#include "/lib/rps/directionalLightmap.glsl"
#include "/lib/rps/labMetal.glsl"
#include "/lib/rps/parallax.glsl"
#endif

#if AA == 2
#include "/lib/util/jitter.glsl"
#endif

void main(){
	//Texture
	vec4 albedo = texture2D(texture, texcoord) * vec4(color.rgb,1.0);
	
	#ifdef RPSupport
	float pomfade = clamp((dist-POMDistance)/32.0,0.0,1.0);
	vec2 newcoord = vtexcoord.st*vtexcoordam.pq+vtexcoordam.st;
	
	#ifdef RPSPOM
	newcoord = getParallaxCoord(pomfade);
	albedo = texture2DGradARB(texture, newcoord, dcdx, dcdy) * vec4(color.rgb,1.0);
	#endif

	float smoothness = 0.0;
	float f0 = 0.0;
	#endif
	
	vec3 vlalbedo = vec3(1.0);
	
	if (albedo.a > 0.0){
		//NDC Coordinate
		#if AA == 2
		vec3 fragpos = toNDC(vec3(taaJitter(gl_FragCoord.xy/vec2(viewWidth,viewHeight),-0.5),gl_FragCoord.z));
		#else
		vec3 fragpos = toNDC(vec3(gl_FragCoord.xy/vec2(viewWidth,viewHeight),gl_FragCoord.z));
		#endif
		
		//World Space Coordinate
		vec3 worldpos = toWorld(fragpos);

		//Specular & Normal Mapping
		#ifdef RPSupport
		vec4 specularmap = texture2D(specular,texcoord.xy);

		#if SpecularFormat == 0	//labPBR
		smoothness = specularmap.r;
		f0 = specularmap.g;
		if (f0 < 0.9) f0 *= f0;
		#endif
		#if SpecularFormat == 1	//Old PBR
		smoothness = specularmap.r;
		if (specularmap.g >= 0.9) f0 = 1.0;
		else f0 = specularmap.g * 0.78 + 0.02;
		#endif
		#if SpecularFormat == 2	//Grayscale
		smoothness = specularmap.r;
		f0 = float(mat > 3.98 && mat < 4.02) * 0.98 + 0.02;
		#endif
		#endif
		
		vec3 newnormal = normal;
		vec3 normalmap = vec3(0.0,0.0,1.0);
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							  tangent.y, binormal.y, normal.y,
							  tangent.z, binormal.z, normal.z);
							  
		#if WaterNormals == 1 || WaterNormals == 2
		if (mat > 0.98 && mat < 1.02){
			vec3 posxz = wpos.xyz;
			#ifdef WaterParallax
			posxz = getParallaxWaves(posxz,viewVector,fragpos.xyz);
			#endif
			
			#if WaterNormals == 2
			float deltaPos = WaterSharpness;
			#else
			float deltaPos = 0.1;
			#endif
			#ifdef WaterDistantWave
			deltaPos += 0.3*clamp(dist/64.0-0.25,0.0,1.0);
			#endif
			float h0 = waterH(posxz,fragpos.xyz);
			float h1 = waterH(posxz + vec3(deltaPos,0.0,0.0),fragpos.xyz);
			float h2 = waterH(posxz + vec3(-deltaPos,0.0,0.0),fragpos.xyz);
			float h3 = waterH(posxz + vec3(0.0,0.0,deltaPos),fragpos.xyz);
			float h4 = waterH(posxz + vec3(0.0,0.0,-deltaPos),fragpos.xyz);
			
			float xDelta = ((h1-h0)+(h0-h2))/deltaPos;
			float yDelta = ((h3-h0)+(h0-h4))/deltaPos;
			
			normalmap = vec3(xDelta,yDelta,1.0-xDelta*xDelta-yDelta*yDelta);
			
			float bumpmult = 0.03;	
			
			normalmap = normalmap * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);
			
			newnormal = clamp(normalize(normalmap * tbnMatrix),vec3(-1.0),vec3(1.0));
		}
		#endif
		#ifdef RPSupport
		if (mat < 0.02 || mat > 1.98){
			normalmap = texture2DGradARB(normals, newcoord.xy, dcdx, dcdy).xyz*2.0-1.0;
			if (texture2DGradARB(normals, newcoord.xy, dcdx, dcdy).a > 0.01) newnormal = normalize(normalmap * tbnMatrix);
		}
		#endif
		
		//Convert to linear color space
		albedo.rgb = pow(albedo.rgb, vec3(2.2));
		
		#ifdef DisableTexture
		albedo.rgb = vec3(0.5);
		#endif
		
		#ifdef RPSupport
		vec3 rawalbedo = albedo.rgb;
		#ifdef ReflectSpecular
		if (f0 >= 0.9 && (mat < 0.98 || mat > 1.02)) albedo.rgb *= (1.0 - smoothness) * (1.0 - smoothness);
		#endif
		#endif

		//Lightmap
		#ifdef LightmapBanding
		float torchmap = clamp(floor(lmcoord.x*14.999 * (0.75 + 0.25 * color.a)) / 14, 0.0, 1.0);
		#else
		float torchmap = clamp(lmcoord.x, 0.0, 1.0);
		#endif

		//Directional Lightmap
		#ifdef RPSupport
		#ifdef RPSLightmap
		mat3 lmTBN = mat3(normalize(dFdx(fragpos)),normalize(dFdy(fragpos)),vec3(0.0));
		lmTBN[2] = cross(lmTBN[0], lmTBN[1]);

		torchmap = directionalLightmap(torchmap,lmcoord.x,newnormal,lmTBN);
		#endif
		#endif
		
		//Material Flag
		float water = float(mat > 0.98 && mat < 1.02);
		float translucent = float(mat > 1.98 && mat < 2.02);
		
		#ifndef WaterVanilla
		if (water > 0.5){
			albedo = vec4(water_c * cmult, water_a);
			albedo.rgb *= albedo.rgb;
		}
		#endif
		
		vlalbedo = mix(vec3(1.0), albedo.rgb, sqrt(albedo.a))*(1.0-pow(albedo.a,64.0));
		
		//Shadows
		vec3 shadow = vec3(0.0);
		
		float NdotL = clamp(dot(newnormal,sunVec)*1.01-0.01,0.0,1.0);
		float quarterNdotU = clamp(0.25 * dot(normal, upVec) + 0.75,0.5,1.0);
		quarterNdotU *= quarterNdotU;
		
		worldpos = toShadow(worldpos);
		
		float distb = sqrt(worldpos.x * worldpos.x + worldpos.y * worldpos.y);
		float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
		
		worldpos.xy /= distortFactor;
		worldpos.z *= 0.2;
		worldpos = worldpos*0.5+0.5;
		
		if (NdotL > 0.0){
			float NdotLm = NdotL * 0.99 + 0.01;
			float diffthresh = (8.0 * distortFactor * distortFactor * sqrt(1.0 - NdotLm *NdotLm) / NdotLm * pow(shadowDistance/256.0, 2.0) + 0.05) / shadowMapResolution;
			float step = 1.0/shadowMapResolution;

			worldpos.z -= diffthresh;
			
			shadow = getShadow(worldpos, step);
		}
		
		//Parallax Self Shadowing
		#ifdef RPSupport
		#ifdef RPSShadow
		if (dist < POMDistance+32.0 && NdotL > 0.0 && length(shadow) > 0.0)
			NdotL *= getParallaxShadow(pomfade, newcoord, sunVec, tbnMatrix);
		#endif
		#endif
		
		vec3 fullshading = shadow * NdotL;
		
		//Lighting Calculation
		vec3 scenelight = mix(end_c*0.025, end_c*0.1, fullshading);
		float newtorchmap = pow(torchmap,10.0)*(EmissiveBrightness+0.5)+(torchmap*0.7);
		
		vec3 blocklight = (newtorchmap * newtorchmap) * torch_c;
		#ifdef LightmapBanding
		scenelight *= floor(color.a*4.0+0.8)/4.0;
		float minlight = (0.009*screenBrightness + 0.001)*floor(color.a*4.0+0.8)/4.0;
		float sl = 1.0;
		#else
		float minlight = (0.009*screenBrightness + 0.001);
		float sl = color.a * color.a;
		#endif
		
		vec3 finallight = (scenelight + blocklight + nightVision + minlight) * sl;

		#ifdef RPSupport
		#if SpecularFormat == 0
		if (specularmap.a < 1.0) finallight += albedo.rgb * luma(albedo.rgb) * (specularmap.a * 4.0 / quarterNdotU) * sl;
		#endif
		#endif

		albedo.rgb *= finallight * quarterNdotU;

		//Material AO
		#ifdef RPSupport
		#if SpecularFormat == 0
		float ao = clamp(length(normalmap), 0.0, 1.0);
		albedo.rgb *= ao * ao;
		#endif
		#endif
		
		//Desaturation
		#ifdef Desaturation
		float desat = clamp(sqrt(torchmap), DesaturationFactor * 0.4, 1.0);
		vec3 desat_c = end_c*0.125*(1.0-desat);
		albedo.rgb = mix(luma(albedo.rgb)*desat_c*10.0,albedo.rgb,desat);
		#endif
		
		float fresnel = pow(clamp(1.0 + dot(newnormal, normalize(fragpos.xyz)),0.0,1.0),5.0);
		vec3 skyRef = end_c * 0.01 * clamp(1.0-isEyeInWater,0.0,1.0);
		float dither = bayer64(gl_FragCoord.xy);

		if (water > 0.5 || (translucent > 0.5 && albedo.a < 0.95)){
			vec4 reflection = vec4(0.0);
			
			fresnel = (fresnel*0.98 + 0.02) * max(1.0-isEyeInWater*0.5*water,0.5) * (1.0-translucent*0.3);
			
			#ifdef Reflection
			reflection = raytrace(gaux2,depthtex1,fragpos.xyz,newnormal,dither);
			reflection.rgb = pow(reflection.rgb*2.0,vec3(8.0));
			#endif
			
			float sun = GGX(newnormal,normalize(fragpos.xyz),sunVec,0.4,0.02,0.1);
			
			skyRef += (sun / fresnel) * end_c * 0.25 * shadow;

			reflection.rgb = mix(skyRef,reflection.rgb,reflection.a);
			
			albedo.rgb = mix(albedo.rgb,max(reflection.rgb,vec3(0.0)),fresnel);
			albedo.a = mix(albedo.a,1.0,fresnel);
		}else{
			#ifdef RPSupport
			vec3 fresnel3 = vec3(mix(f0, 1.0, pow(fresnel, 5.0)));
			#if SpecularFormat == 0
			if (f0 >= 0.9 && f0 < 1.0) fresnel3 = complexFresnel(fresnel, f0);
			#endif
			fresnel3 *= smoothness * smoothness;

			#ifdef ReflectRough
			vec2 noisecoord = gl_FragCoord.xy/512.0;
			#if AA == 2
			noisecoord += fract(frameCounter*vec2(0.4,0.25));
			#endif
			#endif

			#ifdef ReflectSpecular
			if (length(fresnel3) > 0.002){
				vec4 reflection = vec4(0.0);
				
				#ifdef ReflectRough
				if (smoothness > 0.95) reflection = raytrace(gaux2,depthtex1,fragpos.xyz,newnormal,dither);
				else reflection = raytraceRough(gaux2,depthtex1,fragpos.xyz,newnormal,dither,1.0-smoothness,noisecoord);
				#else
				reflection = raytrace(gaux2,depthtex1,fragpos.xyz,newnormal,dither);
				#endif
				reflection.rgb = pow(reflection.rgb*2.0,vec3(8.0));

				reflection.rgb = mix(skyRef,reflection.rgb,reflection.a);
				
				if (f0 >= 0.9){
					if (f0 == 1.0) fresnel3 = mix(rawalbedo,vec3(1.0),fresnel) * smoothness * smoothness;
					albedo.rgb += reflection.rgb * fresnel3;
				}else{
					albedo.rgb = mix(albedo.rgb,reflection.rgb,fresnel3);
				}
				albedo.a = mix(albedo.a,1.0,luma(fresnel3));
			}
			#endif
			
			if (dot(fullshading,fullshading) > 0.0){
				vec3 speccol = end_c;

				if (f0 >= 0.9){
					speccol = sqrt(speccol);
					#if SpecularFormat == 0
					if (f0 < 1.0) speccol *= getMetalCol(f0);
					else speccol *= rawalbedo * 4.0;
					#else
					speccol *= rawalbedo * 4.0;
					#endif
				}

				vec3 spec = speccol * 0.25 * shadow;
				spec *= GGX(newnormal,normalize(fragpos.xyz),sunVec,1.0-smoothness,f0,0.1);
				albedo.rgb += spec;
			}
			#endif
		}
		
		//Fog
		#ifdef Fog
		albedo.rgb = calcFog(albedo.rgb,fragpos.xyz, blindness);
		if (isEyeInWater == 1) albedo.a = mix(albedo.a,1.0,min(length(fragpos)/wfogrange,1.0));
		#endif
	}
	
/* DRAWBUFFERS:01 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(vlalbedo,1.0);
}