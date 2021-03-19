vec2 blackoutlineoffset[12] = vec2[12](vec2(-2.0,2.0),vec2(-1.0,2.0),vec2(0.0,2.0),vec2(1.0,2.0),vec2(2.0,2.0),vec2(-2.0,1.0),vec2(-1.0,1.0),vec2(0.0,1.0),vec2(1.0,1.0),vec2(2.0,1.0),vec2(1.0,0.0),vec2(2.0,0.0));

float blackoutline(sampler2D depth, float forcefull){
	float ph = 1.0/1080.0;
	float pw = ph/aspectRatio;

	float outline = 1.0;
	float z = ld(texture2D(depth,texcoord.xy).r)*far*2.0;
	float minz = far;
	float sampleza = 0.0;
	float samplezb = 0.0;

	#ifdef Fog
	float dist = FogRange*16.0;
	if (isEyeInWater > 0.5) dist = wfogrange*1.5;
	#else
	float dist = 4096.0;
	#endif

	for (int i = 0; i < 12; i++){
		sampleza = ld(texture2D(depth,texcoord.xy+vec2(pw,ph)*blackoutlineoffset[i]).r)*far;
		samplezb = ld(texture2D(depth,texcoord.xy-vec2(pw,ph)*blackoutlineoffset[i]).r)*far;
		outline *= clamp(1.0-(z-(sampleza+samplezb))*0.5,0.0,1.0);
		minz = min(minz,min(sampleza,samplezb));
	}
	outline = mix(outline,1.0,min(minz/dist,clamp(0.8+0.2*isEyeInWater,0.0,1.0))*(1.0-forcefull));

	return outline;
}

float blackoutlinemask(sampler2D depth0, sampler2D depth1){
	float ph = 1.0/540.0;
	float pw = ph/aspectRatio;

	float mask = 0.0;
	for (int i = 0; i < 12; i++){
		mask += float(texture2D(depth0,texcoord.xy+vec2(pw,ph)*blackoutlineoffset[i]).r < texture2D(depth1,texcoord.xy+vec2(pw,ph)*blackoutlineoffset[i]).r);
		mask += float(texture2D(depth0,texcoord.xy-vec2(pw,ph)*blackoutlineoffset[i]).r < texture2D(depth1,texcoord.xy-vec2(pw,ph)*blackoutlineoffset[i]).r);
	}

	return clamp(mask,0.0,1.0);
}