#define POMQuality 64 //[4 8 16 32 64 128 256 512]
#define POMDepth 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define POMDistance 64.0 //[16.0 32.0 48.0 64.0 80.0 96.0 112.0 128.0]
#define POMShadowAngle 2.0 //[0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0]

vec4 readNormal(vec2 coord){
	return texture2DGradARB(normals,fract(coord)*vtexcoordam.pq+vtexcoordam.st,dcdx,dcdy);
}

vec2 getParallaxCoord(float pomfade){
    vec2 newcoord = vtexcoord.st*vtexcoordam.pq+vtexcoordam.st;
    vec2 coord = vtexcoord.st;

    if (dist < POMDistance+32.0){
        vec3 normalmap = readNormal(vtexcoord.st).xyz*2.0-1.0;
        float normalcheck = normalmap.x + normalmap.y + normalmap.z;
        if (viewVector.z < 0.0 && readNormal(vtexcoord.st).a < (1.0-1.0/POMQuality) && normalcheck > -2.999){
            vec2 interval = viewVector.xy * 0.2 * (1.0-pomfade) * POMDepth / (-viewVector.z * POMQuality);
            for (int i = 0; i < POMQuality; i++) {
                if (readNormal(coord).a < 1.0-float(i)/POMQuality) coord = coord+interval;
                else break;
            }
            newcoord = fract(coord.st)*vtexcoordam.pq+vtexcoordam.st;
        }
    }

    return newcoord;
}

float getParallaxShadow(float pomfade, vec2 coord, vec3 lightVec, mat3 tbn){
    float parallaxshadow = 1.0;
    float height = texture2DGradARB(normals,coord,dcdx,dcdy).a;

    if (height < (1.0-1.0/POMQuality)){
        vec3 parallaxdir = (tbn * lightVec);
        parallaxdir.xy *= 0.2 * POMShadowAngle * POMDepth;
        vec2 newvtexcoord = (coord-vtexcoordam.st)/vtexcoordam.pq;
        float step = 1.28/POMQuality;
        
        for(int i = 0; i < POMQuality/4; i++){
            float currz = height + parallaxdir.z * step * i;
            float offsetheight = texture2DGradARB(normals,fract(newvtexcoord+parallaxdir.xy*i*step)*vtexcoordam.pq+vtexcoordam.st,dcdx,dcdy).a;
            parallaxshadow *= clamp(1.0-(offsetheight-currz)*40.0,0.0,1.0);
            if (parallaxshadow < 0.01) break;
        }
        
        parallaxshadow = mix(parallaxshadow,1.0,pomfade);
    }

    return parallaxshadow;
}