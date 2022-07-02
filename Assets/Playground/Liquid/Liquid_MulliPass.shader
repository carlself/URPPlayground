Shader "Playground/Liquid_MultiPass" {
    Properties {
        _LiquidColor("LiquidColor", Color) = (0, 0.77, 1, 0)
        _FoamColor("FoamColor", Color) = (0.5, 1, 0, 0)
        _Frequency("Frequency", Float) = 2
        _Amplitude("Amplitude", Float) = 0.1
    }

    SubShader {
        Tags 
        { 
            "RenderType" = "Opaque" 
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "AlphaTest"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _LiquidColor;
            float4 _FoamColor;
            float _Frequency;
            float _Amplitude;
        CBUFFER_END
        ENDHLSL

        Pass {
            Name "FrontPass"
            Tags { "LightMode" = "UniversalForward"}
            Cull Back
            ZTest LEqual
            ZWrite On


            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex LiquidPassVertex
            #pragma fragment LiquidPassFragment


            struct Attributes {
                float3 positionOS : POSITION;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BseMap);

            Varyings LiquidPassVertex(Attributes IN) {
                Varyings OUT;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS);
                OUT.positionCS = positionInputs.positionCS;
                OUT.positionWS = positionInputs.positionWS;

                return OUT;
            }

            float4 LiquidPassFragment(Varyings IN) : SV_TARGET {
                float3 objectPositionWS = UNITY_MATRIX_M._m03_m13_m23;
                float3 positionOffset = IN.positionWS - objectPositionWS;
                float height = positionOffset.y;

                float wave = sin(_TimeParameters.x * _Frequency + positionOffset.x) * _Amplitude;
                height = height + wave;

                float edge1 = step(height, 0.0);
                float edge2 = step(height, 0.05);
                clip(edge2 - 0.5);
                float foamEdge = edge2 - edge1;

                float4 frontLiquidColor = _LiquidColor * edge1;
                float4 frontFoamColor = _FoamColor * foamEdge;
                float4 frontColor = frontLiquidColor + frontFoamColor;

                return float4(frontColor.rgb, 1);
            }

            ENDHLSL
        }

        Pass {
            Name "BackPass"
            Tags { "LightMode" = "SRPDefaultUnlit"}
            Cull Front
            ZTest LEqual
            ZWrite On


            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex LiquidPassVertex
            #pragma fragment LiquidPassFragment


            struct Attributes {
                float3 positionOS : POSITION;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BseMap);

            Varyings LiquidPassVertex(Attributes IN) {
                Varyings OUT;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS);
                OUT.positionCS = positionInputs.positionCS;
                OUT.positionWS = positionInputs.positionWS;


                return OUT;
            }

            float4 LiquidPassFragment(Varyings IN) : SV_TARGET {
                float3 objectPositionWS = UNITY_MATRIX_M._m03_m13_m23;
                float3 positionOffset = IN.positionWS - objectPositionWS;
                float height = positionOffset.y;

                float wave = sin(_TimeParameters.x * _Frequency + positionOffset.x) * _Amplitude;
                height = height + wave;

                float edge2 = step(height, 0.05);
                clip(edge2 - 0.5);
                return _FoamColor;
            }

            ENDHLSL
        }
    }
}