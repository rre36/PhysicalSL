#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define About 0 //[0]
#define Sharpen 0 //[0 1 2 3 4 5]

//Buffer Format
const int R11F_G11F_B10F = 0;
const int RGB10_A2 = 1;
const int RGBA16 = 2;
const int RGB16 = 3;
const int RGB8 = 4;
const int R8 = 5;

const int colortex0Format = R11F_G11F_B10F; //main
const int colortex1Format = RGB8; //raw translucent, bloom
const int colortex2Format = RGBA16; //temporal stuff
const int colortex3Format = RGB8; //specular data

const int gaux1Format = R8; //cloud alpha
const int gaux2Format = RGB10_A2; //reflection image
const int gaux3Format = RGB16; //normals
const int gaux4Format = RGB16; //specular highlight

const float sunPathRotation = -40.0; //[-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]
const int noiseTextureResolution = 512;
const bool shadowHardwareFiltering = true;
const float drynessHalflife = 25.0f;
const float wetnessHalflife = 200.0f;

varying vec2 texcoord;

#if Sharpen > 0
uniform float viewWidth;
uniform float viewHeight;
#endif

uniform sampler2D colortex1;

void main(){
	
	vec3 color = texture2D(colortex1,texcoord.xy).rgb;

	#if Sharpen > 0
	vec2 view = 1.0 / vec2(viewWidth,viewHeight);
	color *= Sharpen * 0.1 + 1.0;
	color -= texture2D(colortex1,texcoord.xy+vec2(1.0,0.0)*view).rgb * Sharpen * 0.025;
	color -= texture2D(colortex1,texcoord.xy+vec2(0.0,1.0)*view).rgb * Sharpen * 0.025;
	color -= texture2D(colortex1,texcoord.xy+vec2(-1.0,0.0)*view).rgb * Sharpen * 0.025;
	color -= texture2D(colortex1,texcoord.xy+vec2(0.0,-1.0)*view).rgb * Sharpen * 0.025;
	#endif
	
	#ifdef About
	#endif
	
	gl_FragColor = vec4(color,1.0);

}