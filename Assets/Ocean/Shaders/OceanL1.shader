Shader "Mobile/OceanL1" {
	Properties {
	    _SurfaceColor ("SurfaceColor", Color) = (1,1,1,1)
	    _WaterColor ("WaterColor", Color) = (1,1,1,1)

		_Specularity ("Specularity", Range(0.01,1)) = 0.3

		_SunColor ("SunColor", Color) = (1,1,0.901,1)

		_Bump ("Bump (RGB)", 2D) = "bump" {}
		_Foam("Foam (RGB)", 2D) = "white" {}
		_FoamBump ("Foam B(RGB)", 2D) = "bump" {}
		_FoamFactor("Foam Factor", Range(0,3)) = 1.8
		_Size ("UVSize", Float) = 0.015625//this is the best value (1/64) to have the same uv scales of normal and foam maps on all ocean sizes
		_FoamSize ("FoamUVSize", Float) = 2//tiling of the foam texture
		_SunDir ("SunDir", Vector) = (0.3, -0.6, -1, 0)
		_WaveOffset ("Wave speed", Float) = 0

		_FakeUnderwaterColor ("Water Color LOD1", Color) = (0.196, 0.262, 0.196, 1)
	}
	
	
	    SubShader {
        Tags { "RenderType" = "Opaque" "Queue"="Geometry"}
        LOD 3
    	Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#include "UnityCG.cginc"

			struct v2f {
    			float4 pos : SV_POSITION;
    			half3  bumpTexCoord : TEXCOORD1;
    			float3  viewDir : TEXCOORD2;
    			float3  lightDir : TEXCOORD4;
				UNITY_FOG_COORDS(7)
				half4 buv : TEXCOORD5;
				half3 normViewDir : TEXCOORD6;
				float3 halfVec : TEXCOORD0;
			};

			float _Size;
			float _FoamSize;
			half4 _SunDir;
			half4 _FakeUnderwaterColor;
            half _WaveOffset;
            
			v2f vert (appdata_tan v) {
    			v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);

    			o.bumpTexCoord.xy = v.vertex.xz*_Size;///float2(_Size.x, _Size.z)*5;
    			o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
    			o.bumpTexCoord.z = v.tangent.w;
    
  				half4 projSource = float4(v.vertex.x, 0.0, v.vertex.z, 1.0);
    			half4 tmpProj = mul( UNITY_MATRIX_MVP, projSource);

    			float3 objSpaceViewDir = ObjSpaceViewDir(v.vertex);
    			float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) );
				float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal );
    
    			o.viewDir = mul(rotation, objSpaceViewDir);
    			o.lightDir = mul(rotation, float3(_SunDir.xyz));

				o.buv = half4(o.bumpTexCoord.x + _WaveOffset * 0.05, o.bumpTexCoord.y + _WaveOffset * 0.03, o.bumpTexCoord.x*1.1 + _WaveOffset * 0.04, o.bumpTexCoord.y*1.1);

				o.normViewDir = normalize(o.viewDir);

				o.halfVec = normalize(o.normViewDir - normalize(o.lightDir));

				UNITY_TRANSFER_FOG(o, o.pos);

    			return o;
			}

			sampler2D _Bump;
			sampler2D _Foam;
			half _FoamFactor;
			half4 _WaterColor;//Lod1;
			half4 _SurfaceColor;
			half _Specularity;
            half4 _SunColor;

			half4 frag (v2f i) : COLOR {
				//half3 normViewDir = normalize(i.viewDir);
				//half4 buv = half4(i.bumpTexCoord.x + _WaveOffset * 0.05, i.bumpTexCoord.y + _WaveOffset * 0.03, i.bumpTexCoord.x + _WaveOffset * 0.04, i.bumpTexCoord.y - _WaveOffset * 0.02);
                
				half3 tangentNormal0 = (tex2D(_Bump, i.buv.xy) * 2.0) + (tex2D(_Bump, i.buv.zw) * 2.0) - 2;

				half3 tangentNormal = normalize(tangentNormal0);

				half4 result = half4(0, 0, 0, 1);
                
				float fresnelLookup = dot(tangentNormal, i.normViewDir);
				//float bias = 0.06;
				//float power = 4.0;
				float fresnelTerm = 0.06 + (1.0-0.06)*pow(1.0 - fresnelLookup, 4.0);

				half4 foam = clamp(tex2D(_Foam, i.bumpTexCoord.xy *_FoamSize)  - 0.5, 0.0, 1.0) * i.bumpTexCoord.z * _FoamFactor;

				//float3 halfVec = normalize(i.normViewDir - normalize(i.lightDir));

				float specular = pow(max(dot(i.halfVec,  tangentNormal) , 0.0), 250.0 * _Specularity ) *(1.2-foam);
                
				result.rgb = lerp(_WaterColor*_FakeUnderwaterColor, _SunColor.rgb*_SurfaceColor*0.85, fresnelTerm*0.65) + clamp(foam.r, 0.0, 1.0)*_SunColor.b + specular*_SunColor.rgb;

				UNITY_APPLY_FOG(i.fogCoord, result); 

    			return result;
			}
			ENDCG
			

		}
    }
 
    
}
