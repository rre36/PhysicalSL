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

varying float mat;

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 normal;
varying vec3 upVec;
varying vec3 sunVec;

varying vec3 sunlight;
varying vec3 skylight;

varying vec4 color;

#ifdef RPSupport
varying float dist;
varying vec3 binormal;
varying vec3 tangent;
varying vec3 viewVector;
varying vec4 vtexcoordam;
varying vec4 vtexcoord;
#endif

uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

uniform float frameTimeCounter;
uniform float nightVision;
uniform float rainStrength;
uniform float screenBrightness; 
uniform float shadowFade;
uniform float timeAngle;
uniform float timeBrightness;
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform vec4 entityColor;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform sampler2D texture;

#ifdef RPSupport
uniform sampler2D specular;
uniform sampler2D normals;
#endif

float eBS = eyeBrightnessSmooth.y/240.0;
float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.1)/0.1;
float moonVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.1)/0.1;

#ifdef RPSupport
vec2 dcdx = dFdx(texcoord.xy);
vec2 dcdy = dFdy(texcoord.xy);
#endif

vec3 lightVec = sunVec*(1.0-2.0*float(timeAngle > 0.5325 && timeAngle < 0.9675));

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float gradNoise(){
	return fract(52.9829189*fract(0.06711056*gl_FragCoord.x + 0.00583715*gl_FragCoord.y)+frameCounter/8.0);
}

#include "/lib/color/lightColor.glsl"
#include "/lib/color/torchColor.glsl"
#include "/lib/visual/shadows.glsl"
#include "/lib/util/spaceConversion.glsl"

#ifdef RPSupport
#include "/lib/rps/ggx.glsl"
#include "/lib/rps/parallax.glsl"
#endif

#if AA == 2
#include "/lib/util/jitter.glsl"
#endif

void main(){
	//Texture
	vec4 albedo = texture2D(texture, texcoord) * color;
	albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
	vec3 newnormal = normal;

	#ifdef RPSupport
	float pomfade = clamp((dist-POMDistance)/32.0,0.0,1.0);
	vec2 newcoord = vtexcoord.st*vtexcoordam.pq+vtexcoordam.st;
	
	#ifdef RPSPOM
	newcoord = getParallaxCoord(pomfade);
	albedo = texture2DGradARB(texture, newcoord, dcdx, dcdy) * vec4(color.rgb,1.0);
	#endif
	#endif

	#if defined RPSupport || defined ReflectRain
	float smoothness = 0.0;
	float f0 = 0.0;
	float skymapmod = 0.0;
	vec3 rawalbedo = vec3(0.0);
	vec3 spec = vec3(0.0);
	#endif
	
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
		vec4 specularmap = texture2DGradARB(specular, newcoord.xy, dcdx, dcdy);
		vec3 normalmap = texture2DGradARB(normals, newcoord.xy, dcdx, dcdy).xyz*2.0-1.0;
			normalmap.z  = sqrt(saturate(1.0 - dot(normalmap.xy, normalmap.xy)));

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

		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							  tangent.y, binormal.y, normal.y,
							  tangent.z, binormal.z, normal.z);
		float normalcheck = normalmap.x + normalmap.y + normalmap.z;

		if (normalcheck > -2.999) newnormal = normalize(normalmap * tbnMatrix);
		#endif
		
		//Convert to linear color space
		albedo.rgb = pow(albedo.rgb, vec3(2.2));
		
		#ifdef DisableTexture
		albedo.rgb = vec3(0.5);
		#endif

		#ifdef RPSupport
		vec3 rawalbedo = albedo.rgb;
		#ifdef ReflectSpecular
		if (f0 >= 0.9) albedo.rgb *= (1.0 - smoothness) * (1.0 - smoothness);
		#endif
		#endif
		
		//Lightmap
		#ifdef LightmapBanding
		float torchmap = clamp(floor(lmcoord.x*14.999) / 14, 0.0, 1.0);
		float skymap = clamp(floor(lmcoord.y*14.999) / 14, 0.0, 1.0);
		#else
		float torchmap = clamp(lmcoord.x, 0.0, 1.0);
		float skymap = clamp(lmcoord.y, 0.0, 1.0);
		#endif
		
		//Shadows
		vec3 shadow = vec3(0.0);
		
		float NdotL = clamp(dot(newnormal,lightVec)*1.01-0.01,0.0,1.0);
		float quarterNdotU = clamp(0.25 * dot(newnormal, upVec) + 0.75,0.5,1.0);
		quarterNdotU *= quarterNdotU;
		
		worldpos = toShadow(worldpos);
		
		float distb = sqrt(worldpos.x * worldpos.x + worldpos.y * worldpos.y);
		float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
		
		worldpos.xy /= distortFactor;
		worldpos.z *= 0.2;
		worldpos = worldpos*0.5+0.5;
		
		if (NdotL > 0.0 && skymap > 0.001){
			float NdotLm = NdotL * 0.99 + 0.01;
			float diffthresh = (8.0 * distortFactor * distortFactor * sqrt(1.0 - NdotLm *NdotLm) / NdotLm * pow(shadowDistance/256.0, 2.0) + 0.05) / shadowMapResolution;
			float step = 1.0/shadowMapResolution;

			worldpos.z -= diffthresh;
			
			shadow = getShadow(worldpos, step);
		}

		//Parallax Self Shadowing
		#ifdef RPSupport
		#ifdef RPSShadow
		if (dist < POMDistance+32.0 && skymap > 0.0 && NdotL > 0.0 && length(shadow) > 0.0)
			NdotL *= getParallaxShadow(pomfade, newcoord, lightVec, tbnMatrix);
		#endif
		#endif
		
		vec3 fullshading = shadow * NdotL;
		
		//Lighting Calculation
		vec3 scenelight = (mix(skylight, sunlight, fullshading * (shadowFade * (1.0-0.95*rainStrength))) * (4.0-3.0*eBS))  * skymap * skymap;
		float newtorchmap = pow(torchmap,10.0)*(EmissiveBrightness+0.5)+(torchmap*0.7);
		
		vec3 blocklight = (newtorchmap * newtorchmap) * torch_c;
		float minlight = (0.009*screenBrightness + 0.001)*(1.0-eBS);
		
		float emissive = float(entityColor.a > 0.05)*0.125;
		#ifdef RPSupport
		#if SpecularFormat == 0
		if (specularmap.a < 1.0) emissive = mix(specularmap.a,1.0,emissive);
		#endif
		#endif
		blocklight += albedo.rgb * (emissive * 4.0 / quarterNdotU);
		
		vec3 finallight = scenelight + blocklight + nightVision + minlight;
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
		float desat = clamp(sqrt(max(sqrt(length(fullshading/3))*skymap,skymap))*sunVisibility*(1-rainStrength*0.4) + sqrt(torchmap) + float(entityColor.a > 0.05) + emissive, DesaturationFactor * 0.3, 1.0);
		vec3 desat_n = light_n / LightNS;
		vec3 desat_w = weather / weatheri * 0.5;
		vec3 desat_c = mix(vec3(0.1),mix(desat_w * desat_w, desat_n * desat_n, (1.0 - sunVisibility)*(1.0 - rainStrength)),sqrt(skymap))*(1.0-desat);
		albedo.rgb = mix(luma(albedo.rgb)*desat_c*10.0,albedo.rgb,desat);
		#endif
		
		//Specular Highlight (GGX)
		#ifdef RPSupport
		skymapmod = skymap*skymap*(3.0-2.0*skymap);
		
		if (dot(fullshading,fullshading) > 0.0){
			vec3 light_me = mix(light_m,light_a,mefade);
			vec3 speccol = sunlight;
			
			if (f0 >= 0.9){
				speccol = sqrt(speccol);
				#if SpecularFormat == 0
				if (f0 < 1.0) speccol *= getMetalCol(f0);
				else speccol *= rawalbedo;
				#else
				speccol *= rawalbedo;
				#endif
			}

			spec = speccol * shadow * shadowFade * skymap * (1.0 - sqrt(rainStrength));
			
			spec *= GGX(newnormal,normalize(fragpos.xyz),lightVec,1.0-smoothness,f0,0.025 * sunVisibility + 0.05);
			albedo.rgb += spec;
			spec = spec/(4.0+spec);
		}

		if(f0 == 1.0) spec = rawalbedo;
		#endif
	}
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
	#if (defined RPSupport && defined ReflectSpecular) || defined ReflectRain
/* DRAWBUFFERS:0367 */
	gl_FragData[1] = vec4(smoothness,f0,skymapmod,1.0);
	gl_FragData[2] = vec4(newnormal*0.5+0.5,1.0);
	gl_FragData[3] = vec4(spec,1.0);
	#endif
}