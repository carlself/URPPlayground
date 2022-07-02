Shader "Playground/Portal"
{
    Properties
    {
        [HDR]_BaseColor("Color", Color) = (1,1,1,1)
        _NoiseMap("Noise", 2D) = "white" {}
        _SpiralSpeed("SpiralSpeed", float) = 1
        _InwardSpeed("InwardSpeed", float) = 1
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque" 
            "RenderPipeline"="UniversalRenderPipeline"
            "Queue"="AlphaTest"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            float4 _NoiseMap_ST;
            float _SpiralSpeed;
            float _InwardSpeed;
        CBUFFER_END
        ENDHLSL

        Pass
        {
            Name "Portal"
            Tags {
                "LightMode"="UniversalForward"
            }

            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex PortalPassVertex
            #pragma fragment PortalPassFragment


            struct Attributes {
                float3 position : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_NoiseMap);
            SAMPLER(sampler_NoiseMap);

            Varyings PortalPassVertex(Attributes IN) {
                Varyings OUT;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.position);
                OUT.positionCS = positionInputs.positionCS;
                OUT.uv = TRANSFORM_TEX(IN.uv, _NoiseMap);
                
                return OUT;
            }

            float2 ToPolarCoordinates(float2 uv, float2 center){
                float2 delta = uv - center;
                float radius = length(delta) * 2;
                float angle = atan2(delta.x, delta.y) * 1.0/6.28;
                return float2(radius, angle);
            }

            inline float unity_noise_randomValue (float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
            }

            inline float unity_noise_interpolate (float a, float b, float t)
            {
                return (1.0-t)*a + (t*b);
            }

            inline float unity_valueNoise (float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);

                uv = abs(frac(uv) - 0.5);
                float2 c0 = i + float2(0.0, 0.0);
                float2 c1 = i + float2(1.0, 0.0);
                float2 c2 = i + float2(0.0, 1.0);
                float2 c3 = i + float2(1.0, 1.0);
                float r0 = unity_noise_randomValue(c0);
                float r1 = unity_noise_randomValue(c1);
                float r2 = unity_noise_randomValue(c2);
                float r3 = unity_noise_randomValue(c3);

                float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
                float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
                float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
                return t;
            }

            float Unity_SimpleNoise_float(float2 UV, float Scale)
            {
                float t = 0.0;

                float freq = pow(2.0, float(0));
                float amp = pow(0.5, float(3-0));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(1));
                amp = pow(0.5, float(3-1));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(2));
                amp = pow(0.5, float(3-2));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                return t;
            }

            float4 PortalPassFragment(Varyings IN) : SV_TARGET {
                float2 polar = ToPolarCoordinates(IN.uv, float2(0.5, 0.5));
                float radius = _TimeParameters.x * _InwardSpeed + polar.x;
                float angle = polar.y + polar.x * _SpiralSpeed;

                float2 edgeNoiseUV = IN.uv + float2(_TimeParameters.x, 0);
                float edgeNoise =Unity_SimpleNoise_float(edgeNoiseUV, 10);
                float noisyEdge = polar.x + edgeNoise * 0.2;
                float edge = step(noisyEdge, 1); 
                clip(edge - 0.5);

                float4 noise = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, float2(radius, angle));

                float power =  pow(noisyEdge, 2.5) + pow(noise.r, 1.2);

                float3 baseColor = power * _BaseColor.rgb;

                return float4(baseColor.rgb, 1.0);
            }

            ENDHLSL
        }
    }
}
