Shader "Dithering/BayerMatrix" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _BayerTex ("Texture", 2D) = "white" {}
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
            };

            struct v2f {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 scrPos : TEXCOORD1;
            };

            uniform float4 _Color;
            sampler2D _BayerTex;
            float4 _BayerTex_TexelSize;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeScreenPos(o.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float3 frag (v2f i) : SV_Target {
                //dithering
                float2 screenUV = (i.scrPos.xy / i.scrPos.w) * (_ScreenParams.xy / _BayerTex_TexelSize.zw);
                float threshold = tex2D( _BayerTex, screenUV ).r;
                clip(_Color.a - threshold - 0.0001);
                
                float4 col = _Color
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col.rgb;
            }
            ENDCG
        }
    }
}
