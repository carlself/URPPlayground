Shader "Playground/ToonGlass"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1, 0.2)
        _Offset("Offset", float) = 0.2
        _ScaleMultiplier("ScaleMultiplier", float) = 0.7
        _A("A", float) = 3
        _B("B", float) = 1
        _LineWidth("LineWidth", float) = 0.5
        _LineAlpha("LineAlpha", float) = 0.4
    }

        SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex ToonGlassVertex 
            #pragma fragment ToonGlassFragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float _Offset;
                float _ScaleMultiplier;
                float _A;
                float _B;
                float _LineWidth;
                float _LineAlpha;
            CBUFFER_END
            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 tangentOS : TANGENT;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionTS : TEXCOORD0;
            };

            Varyings ToonGlassVertex(Attributes IN)
            {
                Varyings OUT;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);

                float3 cameraPosWS = GetCameraPositionWS();
                float3 relativePosition = positionInputs.positionWS - cameraPosWS;

                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);

                OUT.positionCS = positionInputs.positionCS;
                OUT.positionTS = mul(relativePosition, float3x3(normalInputs.tangentWS, normalInputs.bitangentWS, normalInputs.normalWS));



                return OUT;
            }

            float4 ToonGlassFragment(Varyings IN) : SV_TARGET
            {
                float3 positionTS = IN.positionTS;
                float value = abs(positionTS.x + positionTS.y);

                value = saturate(1 - (value - _Offset) * _ScaleMultiplier);
                value = frac(pow(_A + 1.01, value) * _B);

                float alpha = step(_LineWidth, value) * _LineAlpha + _Color.a;

                return float4(_Color.rgb, alpha);
            }
            ENDHLSL
        }
    }
}
