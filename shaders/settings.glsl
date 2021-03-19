#define WavingWater

//#define SoftParticle
//#define WorldCurvature

const float sunPathRotation = -40.0; //[-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]

const float shadowDistance = 256.0; //[128.0 256.0 512.0 1024.0]
const int shadowMapResolution = 2048; //[1024 2048 3072 4096 8192]

#define Weather
#define WeatherOpacity 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]


#define AA 2 //[0 1 2]
#define Clouds
#define Desaturation
#define DesaturationFactor 1.0 //[2.0 1.5 1.0 0.5 0.0]
//#define DisableTexture
#define EmissiveBrightness 1.00 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define EmissiveRecolor
//#define Fog
#define FogRange 8 //[2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 18 20 22 24 26 28 30 32 36 40 44 48 52 56 60 64]
//#define LightmapBanding
#define LightmapDirStrength 1.0 //[2.0 1.4 1.0 0.7 0.5]
#define POMQuality 64 //[4 8 16 32 64 128 256 512]
#define POMDepth 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define POMDistance 64.0 //[16.0 32.0 48.0 64.0 80.0 96.0 112.0 128.0]
#define POMShadowAngle 2.0 //[0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0]
#define Reflection
//#define ReflectPrevious
//#define ReflectRain
#define ReflectRainType 0 //[0 1]
#define ReflectRough
#define ReflectSpecular
#define ReflectTranslucent
//#define RPSupport
//#define RPSLightmap
#define RPSPOM
#define RPSShadow
#define ShadowColor
#define ShadowFilter
#define SpecularFormat 0 //[0 1 2]
#define SubsurfaceScattering

#define WaterNormals 1 //[0 1 2]
#define WaterParallax
#define WaterOctave 5 //[2 3 4 5 6 7 8]
#define WaterBump 3.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00 4.25 4.50 4.75 5.00]
#define WaterLacunarity 1.50 //[1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define WaterPersistance 0.80 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90]
#define WaterSize 450.0 //[150.0 200.0 250.0 300.0 350.0 400.0 450.0 500.0 550.0 600.0 650.0 700.0 750.0]
#define WaterSharpness 0.10 //[0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40]
#define WaterSpeed 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00 3.50 4.00]

//#define WorldTimeAnimation
#define AnimationSpeed 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00 3.50 4.00 5.00 6.00 7.00 8.00]

#define SkyboxBrightness 1.50 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define SkyDesaturation
//#define RoundSunMoon
#define Stars

#define AO
//#define BlackOutline
//#define PromoOutline

#define Vignette

#define AutoExposure
#define Bloom

//#define ColorGrading
//#define DirtyLens
//#define LensFlare
#define LensFlareStrength 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]
//#define DOF
//#define MotionBlur

#define LightShaft
#define LightShaftStrength 1.00	//[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]

#define CloudRenderLOD 4.0