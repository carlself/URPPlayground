Shader "Playground/Hologram_Glitch"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _HologramScrollSpeed1("Hologram Scroll Speed1", Float) = 1
        _HologramScrollSpeed2("Hologram Scroll Speed2", Float) = 1
        // _DistortionScale("Distortion Scale", Float) = 1
        // _DistortionSpeed("Distortion Speed", Float) = 1
        // _DistortionStrength("Distortion Strength", Float) = 1

        _GlitchSpeed("Glitch Speed", Float) = 1
        _GlitchAmount("Glitch Amount", Float) = 1
        _GlitchStrength("Glitch Strength", Float) = 1
        _GlitchColor1("Glitch Color1", Color) = (1, 1, 1, 1)
        _GlitchColor2("Glitch Color2", Color) = (1, 1, 1, 1)

    }
    SubShader
    {
        Tags 
        {
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" =  "Transparent"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            float4 _BaseMap_ST;
            float _HologramScrollSpeed1;
            float _HologramScrollSpeed2;
            float _GlitchSpeed;
            float _GlitchAmount;
            float _GlitchStrength;
            float4 _GlitchColor1;
            float4 _GlitchColor2;
        CBUFFER_END
        ENDHLSL

        Pass {
            Name "Hologram"
            Tags {
                "LightMode" = "UniversalForward"
            }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex HologramPassVertex
            #pragma fragment HologramPassFragment

            struct Attributes 
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };


            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 viewDirWS : TEXCOORD3;
            };


            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            Varyings HologramPassVertex(Attributes IN)
            {
                Varyings OUT;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS);
                OUT.positionCS = positionInputs.positionCS;
                OUT.positionWS = positionInputs.positionWS;
                OUT.viewDirWS = _WorldSpaceCameraPos.xyz - positionInputs.positionWS;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            float FresnelEffect(float3 Normal, float3 ViewDir, float Power)
            {
                return pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
            }

            float2 GradientNoise_dir(float2 p)
            {
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }

            float GradientNoise(float2 p)
            {
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(GradientNoise_dir(ip), fp);
                float d01 = dot(GradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(GradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(GradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
            }

            float GradientNoise(float2 UV, float Scale)
            {
                return GradientNoise(UV * Scale) + 0.5;
            }

            float RandomRange(float2 Seed, float Min, float Max)
            {
                float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
                return lerp(Min, Max, randomno);
            }

            float4 HologramPassFragment(Varyings IN) : SV_Target
            {
                float y = IN.positionWS.y;
                float sinWave = saturate(sin((_TimeParameters.x * _HologramScrollSpeed1 + y) * 70));
                float fracWave = pow(frac((_TimeParameters.x * _HologramScrollSpeed2 + y) * 1), 2);

                float fresnel = FresnelEffect(IN.normalWS, IN.viewDirWS, 1.5);
                float value = fresnel + sinWave + fracWave;
                
                float glitch = round((floor(_TimeParameters.x * _GlitchSpeed) + y) * 10);
                float random = RandomRange(glitch, -1, 1);
                float u = step(abs(random), _GlitchAmount) *random * 0.1 * _GlitchStrength + IN.uv.x;

                float saturatedRandom = saturate(random);
                float4 glitchColor = saturatedRandom * _GlitchColor1 - saturatedRandom * _GlitchColor2;

                float4 baseMapColor = SAMPLE_TEXTURE2D_LOD(_BaseMap, sampler_BaseMap, float2(u, IN.uv.y), 0);
                float4 color = baseMapColor * (value  * _BaseColor + glitchColor);
                return color; 
            }
            ENDHLSL
        }
    }
}


