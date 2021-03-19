#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
====================================================================================================

    Copyright (C) 2020 RRe36

    All Rights Reserved unless otherwise explicitly stated.


    By downloading this you have agreed to the license and terms of use.
    These can be found inside the included license-file
    or here: https://rre36.github.io/license/

    Violating these terms may be penalized with actions according to the Digital Millennium
    Copyright Act (DMCA), the Information Society Directive and/or similar laws
    depending on your country.

====================================================================================================
*/

#include "/global.glsl"

varying vec2 texcoord;

uniform vec2 pixelSize;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;

void main(){
    vec4 scenecolor     = texture2D(colortex0, texcoord);

    #ifdef Clouds
    float scenedepth    = texture2D(depthtex0, texcoord).x;

    const float cLOD    = sqrt(CloudRenderLOD);
    vec2 cloudcoord     = (texcoord)*rcp(cLOD)+vec2(1.0-rcp(cLOD), 0.0);
    if (!landMask(scenedepth)) {
        vec4 tex1       = texture2D(colortex1, cloudcoord);

        scenecolor.rgb  = scenecolor.rgb * tex1.a + tex1.rgb;
    }
    #endif

    /*DRAWBUFFERS:01*/
	gl_FragData[0] = clamp(scenecolor, 0.0, 65535.0);
    gl_FragData[1] = vec4(0.0);
}
