// VRChat Toon shader, based on Unity's Mobile/Diffuse. Copyright (c) 2019 VRChat.
//Partially derived from "XSToon" (MIT License) - Copyright (c) 2019 thexiexe@gmail.com
// Vertex 4 lights support added by ACiil. Discord ACIIL#4694.
// Simplified Toon shader.
// -fully supports only 1 directional light. Other lights can affect it, but it will be per-vertex/SH.

Shader "VRChat/Mobile/Toon Lit 1 vertex light"
{
	Properties
	{	
		_MainTex("Texture", 2D) = "white" {}
	}

	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }
		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fwdbase 

			#include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

            struct VertexInput
            {
            	float4 vertex : POSITION;
            	float2 uv : TEXCOORD0;
            	float4 color : COLOR;
            };

            struct VertexOutput
            {	
            	float4 pos : SV_POSITION;
            	float2 uv : TEXCOORD0;
            	float4 worldPos : TEXCOORD1;
            	float4 color : TEXCOORD2;
            	float4 indirect : TEXCOORD3;
            	float4 direct : TEXCOORD4;
				float4 vertexLighting : TEXCOORD5;
            	SHADOW_COORDS(7)
            };

			// Unity's modified Shade4PointLights() version without the lambert tint darkening and with attenuation pass out.
            // Multiply the out attenuation on this return color.
            // Simplified for 1st vertex light.
			// ACiiL
            half3 softShade1PointLights_Atten (
                float4 lightPosX, float4 lightPosY, float4 lightPosZ,
                half3 lightColor0, half4 lightAttenSq, float3 pos,
                out half attenVert)
            {
                // to light vectors
                float3 toLightPos0 = float3(lightPosX[0], lightPosY[0], lightPosZ[0]) - pos;
                // squared lengths
                float lengthSq = dot(toLightPos0, toLightPos0);
                // don't produce NaNs if some vertex position overlaps with the light
                lengthSq = max(lengthSq, 0.000001);

                // attenuation
                half atten = 1.0 / (1.0 + lengthSq * lightAttenSq);
                attenVert = atten;

                // final color
                half3 col = lightColor0 * atten;
                return col;
            }

            UNITY_DECLARE_TEX2D(_MainTex); 
            half4 _MainTex_ST;

			VertexOutput vert (VertexInput v)
            {
            	VertexOutput o;
            	o.pos = UnityObjectToClipPos(v.vertex);
            	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
            	o.uv = v.uv;
            	
                half3 indirectDiffuse = ShadeSH9(float4(0, 0, 0, 1)); // We don't care about anything other than the color from GI, so only feed in 0,0,0, rather than the normal
            	half4 lightCol = _LightColor0;
				half4 vertexCol = unity_LightColor[0];
            	 
                //If we don't have a directional light or realtime light in the scene, we can derive light color from a slightly modified indirect color.
                int lightEnv = int(any(_WorldSpaceLightPos0.xyz));       
            	if(lightEnv != 1)
            		lightCol = indirectDiffuse.xyzz * 0.2; 
            
                float4 lighting = lightCol; 
            	
            	o.color = v.color;
            	o.direct = lighting;
            	o.indirect = indirectDiffuse.xyzz;
				half vertexAtten;
				o.vertexLighting = half4( softShade1PointLights_Atten(
                    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0
                    , unity_LightColor[0], unity_4LightAtten0, o.worldPos, vertexAtten), 1);
				o.vertexLighting *= vertexAtten;
            	TRANSFER_SHADOW(o);
            	return o;
            }
            
            float4 frag (VertexOutput i, float facing : VFACE) : SV_Target
            {
                UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
            
            	float4 albedo = UNITY_SAMPLE_TEX2D(_MainTex, TRANSFORM_TEX(i.uv, _MainTex));
            	half4 final = (albedo * i.color) * (i.direct * attenuation + i.indirect + i.vertexLighting);
            	
            	return float4(final.rgb, 1);
            }
			ENDCG
		}

		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On ZTest LEqual
			CGPROGRAM
			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2

			#include "UnityCG.cginc"
            #include "UnityShaderVariables.cginc"

            uniform float4      _Color;
            uniform sampler2D   _MainTex;
            uniform float4      _MainTex_ST;
            
            struct VertexInput
            {
                float4 vertex   : POSITION;
                float3 normal   : NORMAL;
                float2 uv0      : TEXCOORD0;
            };
            
            struct VertexOutputShadowCaster
            {
                V2F_SHADOW_CASTER_NOPOS
                float2 tex : TEXCOORD1;
            };
            
            void vertShadowCaster(VertexInput v, out VertexOutputShadowCaster o, out float4 opos : SV_POSITION)
            {
                TRANSFER_SHADOW_CASTER_NOPOS(o, opos)
                o.tex = TRANSFORM_TEX(v.uv0, _MainTex);
            }


            half4 fragShadowCaster(VertexOutputShadowCaster i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            
			ENDCG
		}
	}
	Fallback "Mobile/Diffuse"
}
