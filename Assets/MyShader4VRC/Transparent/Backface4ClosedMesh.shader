Shader "DepthLiquid/Translucent/Backface4ClosedMesh"
{
    SubShader {
        Tags { "RenderType" = "Transparent"  "Queue" = "Transparent+995" }
        LOD 100
        GrabPass
        {
            "_Background4LiquidTexture"
        }
        Pass {
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
                float4 projPos : TEXCOORD2;
            };

            UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos( v.vertex );
                o.projPos = ComputeScreenPos (o.vertex);
                COMPUTE_EYEDEPTH(o.projPos.z);
                return o;
            }

            float4 frag (v2f i) : SV_Target {
                float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
                float partZ = i.projPos.z;
                float4 color = min(partZ,sceneZ);
                color.a = 1;
                return color;
            }
            ENDCG
        }

    }
    FallBack "Diffuse"
}
