Shader "Dither/Blur" {
    Properties {
        _Blur("Blur Size",Range(0,10)) = 1
    }
    SubShader {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent+999" }
        LOD 100

        GrabPass{ "_BlurTexture" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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

            uniform float _Blur;
            sampler2D _BlurTexture;
            float4 _BlurTexture_TexelSize;

            fixed4 frag (v2f i) : SV_Target {
                float2 screenUV = i.scrPos.xy / i.scrPos.w; 
                float2 texcelSize = _BlurTexture_TexelSize.xy * _Blur;
                float4 bgcolor = tex2D(_BlurTexture,  screenUV);

                float4 neighborPixel = tex2D(_BlurTexture, screenUV + float2(texcelSize.x, 0));
                neighborPixel += tex2D(_BlurTexture, screenUV + float2(-texcelSize.x, 0));
                neighborPixel += tex2D(_BlurTexture, screenUV + float2(0, texcelSize.y));
                neighborPixel += tex2D(_BlurTexture, screenUV + float2(0, -texcelSize.y));
                neighborPixel += 0.7 * tex2D(_BlurTexture, screenUV + float2(texcelSize.x, texcelSize.y));
                neighborPixel += 0.7 * tex2D(_BlurTexture, screenUV + float2(texcelSize.x, -texcelSize.y));
                neighborPixel += 0.7 * tex2D(_BlurTexture, screenUV + float2(-texcelSize.x, texcelSize.y));
                neighborPixel += 0.7 * tex2D(_BlurTexture, screenUV + float2(-texcelSize.x, -texcelSize.y));
        
                return bgcolor;// + neighborPixel * 0.2 / 8;
            }
            ENDCG
        }
    }
}
