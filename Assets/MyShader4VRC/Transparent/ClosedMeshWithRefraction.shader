Shader "DepthLiquid/Translucent/ClosedMeshWithRefraction"
{
    Properties {
        _Color("Color", Color) = (0.5,0.5,0.5,1)
        _Fade("Fade", Float) = 0.5
        _Refraction("Refraction", Range (0, 1)) = 0.2
    }
    SubShader {
        Tags { "RenderType" = "Transparent"  "Queue" = "Transparent+999" }
        LOD 100
        GrabPass
        {
            "_Background4LiquidTexture"
        }
        GrabPass
        {
            "_Depth4LiquidTexture"
        }
        Pass { //inside
            Cull Front
            ZWrite Off
            ZTest Always

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float4 grabPos : TEXCOORD0;
            };

            uniform float4 _Color;
            uniform float _Fade;
            sampler2D _Background4LiquidTexture;
            sampler2D _Depth4LiquidTexture;

            //UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos( v.vertex );
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target {
                float4 bgcolor = tex2Dproj(_Background4LiquidTexture, i.grabPos);
                float4 dpcolor = tex2Dproj(_Depth4LiquidTexture, i.grabPos);
                float4 dpmask = clamp(_Fade * dpcolor, 0.1, 1);
                float4 color = (bgcolor * (1 - dpmask) + _Color * ( dpmask )) / (1+dpmask);
                return color;
            }
            ENDCG
        }
        Pass { // fake Ztest
            Cull Back
            ZWrite Off
            ZTest Always

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float4 grabPos : TEXCOORD0;
            };

            sampler2D _Background4LiquidTexture;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos( v.vertex );
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target {
                return tex2Dproj(_Background4LiquidTexture, i.grabPos);
            }
            ENDCG
        }
        Pass { //outside
            Cull Back
            ZWrite Off
            //ZTest Always

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float4 grabPos : TEXCOORD0;
                float4 projPos : TEXCOORD1;
                float2 refractUV : TEXCOORD2;
                float refractStr : TEXCOORD3;
            };

            uniform float4 _Color;
            uniform float _Fade;
            uniform float _Refraction;
            sampler2D _Background4LiquidTexture;
            sampler2D _Depth4LiquidTexture;

            //UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos( v.vertex );
                o.projPos = ComputeScreenPos (o.vertex);
                COMPUTE_EYEDEPTH(o.projPos.z);
                o.grabPos = ComputeGrabScreenPos(o.vertex);

                float3 worldNorm = UnityObjectToWorldNormal(v.normal);
                float3 viewNorm = mul((float3x3)UNITY_MATRIX_V, worldNorm);
                //float3 viewPos = UnityObjectToViewPos(v.vertex);
                //float3 viewDir = normalize(viewPos);
                //float3 viewCross = cross(viewDir, viewNorm);
                //viewNorm = float3(-viewCross.y, viewCross.x, 0.0);
                o.refractUV = viewNorm.xy;
                o.refractStr = length(viewNorm.xy);
                return o;
            }

            float4 frag (v2f i) : SV_Target {
                i.refractStr = clamp(i.refractStr,0,1);
                i.grabPos.x -= i.refractUV.x*(1-i.refractStr)*_Refraction;
                i.grabPos.y -= i.refractUV.y*(1-i.refractStr)*_Refraction;
                float4 bgcolor = tex2Dproj(_Background4LiquidTexture, i.grabPos);
                float4 dpcolor = tex2Dproj(_Depth4LiquidTexture, i.grabPos);
                float4 dpmask = clamp(_Fade*(dpcolor - i.projPos.z), 0.1, 1);
                float4 color = (bgcolor * (1 - dpmask) + _Color * ( dpmask )) / (1+dpmask);

                return color;
            }
            ENDCG
        }


    }
    FallBack "Diffuse"
}
