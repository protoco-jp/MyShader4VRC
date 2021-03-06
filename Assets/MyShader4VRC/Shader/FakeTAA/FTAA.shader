Shader "MS4VRC/Dither/FakeTAA/FTAA"
{
    Properties {
        _temporalWeight("Temporal Weight", Range(0,1)) = 0.5
    }
    SubShader {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent+999" }
        LOD 100
        Cull Front
        Ztest Always
        GrabPass{ "_OldBufferTexture" }
        GrabPass{ "_CurrentBufferTexture" }
        Pass {
            Stencil {
                Ref 128
                Comp Equal
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float4 scrPos : TEXCOORD1;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeScreenPos(o.vertex);
                o.uv = v.uv;
                return o;
            }

            uniform float _temporalWeight;
            sampler2D _OldBufferTexture;
            sampler2D _CurrentBufferTexture;
            float4 _OldBufferTexture_TexelSize;

            float3 frag (v2f i) : SV_Target {
                float2 screenUV = i.scrPos.xy / i.scrPos.w; 
                float3 oldCol = saturate(tex2D(_OldBufferTexture,  screenUV));
                float3 currentCol = saturate(tex2D(_CurrentBufferTexture,  screenUV));
                return (1-_temporalWeight)*oldCol + _temporalWeight*currentCol;
            }
            ENDCG
        }
    }
}
