Shader "MS4VRC/Dither/FakeTAA/GrabBuffer"
{
    SubShader
    {
        Tags { "RenderType"="Background" "Queue"="Background-1000" }
        LOD 100
        ColorMask 0
        ZWrite Off
        GrabPass{ "_OldBufferTexture" }
        Pass{}
    }
}
