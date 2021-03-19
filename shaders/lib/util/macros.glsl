#define _pow2(x) ((x)*(x))
#define _rcp(x) (1.0 / (x))
#define sstep(x, low, high) smoothstep(low, high, x)
#define _cube_smooth(x) ((x * x) * (3.0 - 2.0 * x))
#define saturate(x) clamp(x, 0.0, 1.0)
#define landMask(x) (x < 1.0)

float rcp(float x) {
    return _rcp(x);
}
vec2 rcp(vec2 x) {
    return _rcp(x);
}
vec3 rcp(vec3 x) {
    return _rcp(x);
}

float pow2(float x) {
    return x*x;
}
vec2 pow2(vec2 x) {
    return x*x;
}
vec3 pow2(vec3 x) {
    return x*x;
}

float cube_smooth(float x) {
    return _cube_smooth(x);
}
vec3 cube_smooth(vec3 x) {
    return _cube_smooth(x);
}