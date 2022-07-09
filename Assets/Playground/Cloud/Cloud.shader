Shader "Playground/Cloud"
{
    Properties
    {
        _ScrollSpeed("Scroll Speed", float) = 1
        _Scale("Scale", float) = 1
        _Color1("Color1", Color) = (1, 1,1,1)
        _Color2("Color2", Color) = (0.6, 0.6, 0.6, 1)
        _CloudCover("CloudColver", float) = 0.5
        _AdditionalFallOff("AdditionalFallOff", float) = 0.1
        _IntersectionDensity("IntersectionDensity", float) = 0.5
    }
    SubShader
    {
        Tags {
            "RenderPipeline"="UniversalRenderPipeline"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

        Pass {
            Tags {
                "LightMode"="UniversalForward"
            }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex CloudPassVertex
            #pragma fragment CloudPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "../ShaderLibrary/Noise.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float _ScrollSpeed;
                float _Scale;
                float4 _Color1;
                float4 _Color2;
                float _CloudCover;
                float _AdditionalFallOff;
                float _IntersectionDensity;
            CBUFFER_END

            struct Attributes {
                float4 positionOS : POSITION;
                

            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                //float3 positionWS : TEXCOORD0; 
                float noise : TEXCOORD0;
                float4 positionNDC : TEXCOORD1;

            };

            Varyings CloudPassVertex(Attributes IN)
            {
                Varyings OUT;
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                float time = _TimeParameters.x * _ScrollSpeed;
                float2 xz = positionWS.xz;
                float noise1;
                Unity_GradientNoise_float(xz + time * 0.5, 0.1, noise1);
                float noise2 = Unity_SimpleNoise(xz + time, 1);    
                float noise3 = Unity_SimpleNoise(xz + time * 1.5, 0.5);

                float noise = (noise1 + noise2) * noise3;

                float3 worldPos = positionWS + float3(0, (noise - 0.5) * _Scale, 0);
                OUT.positionCS = TransformWorldToHClip(worldPos);
                OUT.noise = noise;

                float4 ndc = OUT.positionCS * 0.5f;
                OUT.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
                OUT.positionNDC.zw = OUT.positionCS.zw;

                return OUT;
            }

            float4 CloudPassFragment(Varyings IN) : SV_TARGET
            {
                float4 color = lerp(_Color1, _Color2, IN.noise);

                float alpha = smoothstep(_CloudCover, 2 * _CloudCover + _AdditionalFallOff, IN.noise);

                float fragDepth = IN.positionNDC.w;

                float sceneDepth = LinearEyeDepth(SampleSceneDepth(IN.positionNDC.xy/IN.positionNDC.w), _ZBufferParams);

                float density = saturate((sceneDepth - fragDepth) * _IntersectionDensity);
                return float4(color.rgb, alpha * density);
            }

            ENDHLSL
        }
    }
}
