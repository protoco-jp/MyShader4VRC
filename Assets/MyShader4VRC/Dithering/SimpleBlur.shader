Shader "Dither/Blur" {
    Properties {
        [KeywordEnum(BOX_2X2, BOX_4X4)]_NOISE("Box Size", Float) = 0
    }
    SubShader {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent+999" }
        LOD 100

        GrabPass{ "_BlurTexture" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _BOX_2X2 _BOX_4X4

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float4 scrPos : TEXCOORD0;
            };

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeScreenPos(o.vertex);
                return o;
            }

            sampler2D _BlurTexture;
            float4 _BlurTexture_TexelSize;

            fixed4 frag (v2f i) : SV_Target {
                float2 screenUV = i.scrPos.xy / i.scrPos.w; 
                float2 texcelSize = _BlurTexture_TexelSize.xy;

                float4 bgcolor = tex2D(_BlurTexture, screenUV);
                #ifdef _BOX_2X2
                bgcolor += tex2D(_BlurTexture, screenUV + float2(texcelSize.x, texcelSize.y));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(texcelSize.x, 0));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(0, texcelSize.y));
                bgcolor /= 4;
                #elif _BOX_4X4
                bgcolor += tex2D(_BlurTexture, screenUV + float2(texcelSize.x, texcelSize.y));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(texcelSize.x, 0));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(texcelSize.x, -texcelSize.y));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(texcelSize.x, -2*texcelSize.y));

                bgcolor += tex2D(_BlurTexture, screenUV + float2(0, texcelSize.y));
                //bgcolor += tex2D(_BlurTexture, screenUV + float2(0, 0));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(0, -texcelSize.y));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(0, -2*texcelSize.y));

                bgcolor += tex2D(_BlurTexture, screenUV + float2(-texcelSize.x, texcelSize.y));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(-texcelSize.x, 0));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(-texcelSize.x, -texcelSize.y));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(-texcelSize.x, -2*texcelSize.y));

                bgcolor += tex2D(_BlurTexture, screenUV + float2(-2*texcelSize.x, texcelSize.y));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(-2*texcelSize.x, 0));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(-2*texcelSize.x, -texcelSize.y));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(-2*texcelSize.x, -2*texcelSize.y));

                bgcolor /= 16;
                #endif

                return bgcolor;
            }
            ENDCG
        }
    }
}
