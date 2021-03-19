float weight[7] = float[7](1.0, 6.0, 15.0, 20.0, 15.0, 6.0, 1.0);

vec3 bloomTile(float lod, vec2 offset){
	vec3 bloom = vec3(0.0);
	vec3 temp = vec3(0.0);
	float scale = pow(2.0,lod);
	vec2 coord = (texcoord.xy-offset)*scale;
	float padding = 0.005*scale;

	if (coord.x > -padding && coord.y > -padding && coord.x < 1.0+padding && coord.y < 1.0+padding){
		for (int i = -3; i <= 3; i++) {
			for (int j = -3; j <= 3; j++) {
			float wg = weight[i + 3] * weight[j + 3];
			vec2 bcoord = (texcoord.xy-offset+vec2(i,j)*pw*vec2(1.0,aspectRatio))*scale;
			if (wg > 0){
				temp = texture2D(colortex0,bcoord).rgb;
				bloom += temp*wg;
				}
			}
		}
		bloom /= 4096.0;
	}

	return pow(bloom/128.0,vec3(0.25));
}