Shader "Custom/ObraDinnSurface"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Dither ("Dither", float) = 0.0
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows finalcolor:obradinn

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        #undef UNITY_OPAQUE_ALPHA
        #define UNITY_OPAQUE_ALPHA(X)

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float4 color : COLOR;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float _Dither;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void obradinn (Input IN, SurfaceOutputStandard o, inout fixed4 color)
        {
            fixed4 newCol;
            newCol.rg = IN.color.rg;
            newCol.b = dot(color.rgb, fixed3(0.299f, 0.587f, 0.114f));
            newCol.a = _Dither;
            color = newCol;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c;
            
            //o.Emission.rgb = o.Albedo.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            //o.Alpha = _Dither;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
