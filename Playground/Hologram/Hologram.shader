Shader "Playground/Hologram"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _HologramScrollSpeed1("Hologram Scroll Speed1", Float) = 1
        _HologramScrollSpeed2("Hologram Scroll Speed2", Float) = 1

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

            float4 HologramPassFragment(Varyings IN) : SV_Target
            {
                float y = IN.positionWS.y;
                float sinWave = saturate(sin((_TimeParameters.x * _HologramScrollSpeed1 + y) * 70));
                float fracWave = pow(frac((_TimeParameters.x * _HologramScrollSpeed2 + y) * 1), 2);

                float fresnel = FresnelEffect(IN.normalWS, IN.viewDirWS, 1.5);
                float value = fresnel + sinWave + fracWave;

                float4 baseMapColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                float4 color = baseMapColor * _BaseColor;
                return value * color; 
            }
            ENDHLSL
        }
    }
}


