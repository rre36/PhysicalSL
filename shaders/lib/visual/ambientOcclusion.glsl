#define AOStrength 1.50	//[1.00 1.25 1.50 1.75 2.00]

vec2 offsetDist(float x, int s){
	float n = fract(x*1.414)*3.1415;
    return vec2(cos(n),sin(n))*x/s;
}

float dbao(sampler2D depth, float dither){
	float ao = 0.0;

	#if AA == 2
	int samples = 5;
	dither = fract(frameTimeCounter * 4.0 + dither);
	#else
	int samples = 10;
	#endif
	
	float d = texture2D(depth,texcoord.xy).r;
	float hand = float(d < 0.56);
	d = ld(d);
	
	float sd = 0.0;
	float angle = 0.0;
	float dist = 0.0;
	vec2 scale = 0.7 * vec2(1.0/aspectRatio,1.0) * gbufferProjection[1][1] / (2.74747742 * max((far - near) * d + near, 7.0));

	for (int i = 1; i <= samples; i++) {
		vec2 offset = offsetDist(i + dither, samples) * scale;

		sd = ld(texture2D(depth, texcoord.xy + offset).r);
		float sample = (far - near) * (d - sd) * 2.0;
		if (hand > 0.5) sample *= 1024.0;
		angle = clamp(0.5 - sample, 0.0, 1.0);
		dist = clamp(0.25 * sample - 1.0, 0.0, 1.0);

		sd = ld(texture2D(depth, texcoord.xy - offset).r);
		sample = (far - near) * (d - sd) * 2.0;
		if (hand > 0.5) sample *= 1024.0;
		angle += clamp(0.5 - sample, 0.0, 1.0);
		dist += clamp(0.25 * sample - 1.0, 0.0, 1.0);
		
		ao += clamp(angle + dist, 0.0, 1.0);
	}
	ao /= samples;
	
	return pow(ao,AOStrength);
}