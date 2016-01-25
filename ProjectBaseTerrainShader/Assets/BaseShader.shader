Shader "BaseShader" {

// Propriétés apparaissant dans l'inspecteur de Unity
// Valeurs utilisées par le shader
// Typiquement la couleur de l'objet, sa texture, etc...
Properties {
    //_WaterSegmentCoords ("_WaterSegmentCoords", Vector) = (0.0, 0.0, 10.0, 10.0) // 2d coords of water segment
    //_WaterSegmentRadius ("_WaterSegmentRadius", Float) = 0.1 // 2d coords of water segment
	_Color ("Main Color", Color) = (1,1,1,1)
	_MainTex ("Base (RGB)", 2D) = "white" {}
}

// Les sous shaders correspondent à différentes version du meme shader, il y en a un minimum, 
// et il peut en avoir n pour définir des niveaux de détails. 
// Unity se charge de choisir le bon SubShader en fonction de la Carte graphique de l'utilisateur.
// Ici nous n'avons que un seul SubShader !
// Si aucun SubShader n'est supporté alors Unity appelle un Fallback Shader, soit le shader d'un autre shader.
SubShader {
	Tags { "RenderType"="Opaque" }
	// Définit le niveau de détails, il permet de spécifier si le shader doit etre utilisé meme si la carte graphique le supporte
	// Utile si la Carte est trop lente on évite d'utiliser un shader qui alourdi le traitement (par défaut fixé à infinit).
	LOD 200	// Level of Details 200 = Diffuse

    CGPROGRAM
    	// Utilise le modèle d'illumination Lampert (diffuse) inclut dans Unity
        #pragma surface surf Lambert
        //#pragma surface surf SimpleSpecular

        sampler2D _MainTex;		// Sampler pour l'utilisation de textures image 2D
        fixed4 _Color;
        //float4 _WaterSegmentCoords;
        //float _WaterSegmentRadius;

		// Variables d'Entrées du shader
        struct Input {
            float3 worldPos;	// Position dans le monde
        	float2 uv_MainTex;	// Couleur de la texture
        };

        /////////// primitives définies par champs de distance ////////////////
        // Pour le groupe qui bosse sur l'hydrographie :
        // Pour un point p donné, elles retournent la distance à la primitive 
        // définie par A, width (et B pr le segment). Par la suite, 
        // pour chaque pixel, le shader évalue la distance aux primitives
        // de la scene, et si la distance retourne est en deça d'un certain
        // seuil, le pixel est considéré çomme intérieur à la primitive,
        // et coloré en conséquence. 
        // Notez que la présence d'un cours d'eau n'est que rarement visible
        // sur les photos aériennes, votre rendu n'a pas à être "réaliste",
        // mais seulement "esthétique" et apporter de l'animation si possible.

        // disque de rayon width et de centre A 
        //float disk(float2 A, float2 p, float width)
        //{
        //    return length(p - A) - width; 
        //}

        // Segment d'épaisseur rayon width 
        // et dont les extremités sont positionnées en A et B 
//        float segment(float2 A, float2 B, float2 p, float width)
//        {
//            float2 ap = float2(p - A);
//            float2 ab = float2(B - A);
//            float h = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
//            return length(ap - ab * h) - width;
//        }

        //////////////////////// Operations ///////////////////////////////////

        // altération de la distance à la primitive 
        // (altération de la frontière de la primitive)
        // par un scalaire
        // essayer avec disp = sin(p.x) la primitive aura un bord ondulé
        // en introduisant _SinTime.x on introduit de l'animation
        // voir http://docs.unity3d.com/462/Documentation/Manual/SL-BuiltinValues.html
        //float opDisp(float obj, float disp)
        //{
        //    return obj + disp;
        //}

        //////////////////// detection naive de vegetation ////////////////////
        // Pour le groupe qui bosse sur la végétation :
        // ne vous cassez pas la tête à affiner la détection, 
        // mais vous êtes libre de modifier cette fonction
        // pour lui faire retourner autre chose qu'un booléen
        // si ça vous arrange pour votre calcul par la suite
        float isVeget (fixed3 pxColor)
        {
            return pxColor.g > pxColor.r + 0.05 && pxColor.g > pxColor.b + 0.05;
        }
        
        float isVeget2 (fixed3 pxColor)
        {
            return pxColor.g > pxColor.r + 0.06 && pxColor.g > pxColor.b + 0.06;
        }
        
        float isVeget3 (fixed3 pxColor)
        {
            return pxColor.g > pxColor.r + 0.07 && pxColor.g > pxColor.b + 0.07;
        }
        
        float isVeget4 (fixed3 pxColor)
        {
            return pxColor.g > pxColor.r + 0.08 && pxColor.g > pxColor.b + 0.08;
        }
        
        
        // test lumiere
//        half4 LightingSimpleSpecular (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten) {
//	        half3 h = normalize (lightDir + viewDir);
//
//	        half diff = max (0, dot (s.Normal, lightDir));
//
//	        float nh = max (0, dot (s.Normal, h));
//	        float spec = pow (nh, 48.0);
//
//	        half4 c;
//	        c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec) * atten;
//	        c.a = s.Alpha;
//	        return c;
//	    }
        
        /////////////////////////////////////////////////////////////////////////////////////////////////
        /////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////////////////////// main //////////////////////////////////////////////
        ////////////////////////////Fonction principale d'un Shader de surface///////////////////////////
        /////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////
        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            // Applique la couleur de la texture et couleur de l'objet au pixel de à la surface
            o.Albedo = c.rgb;	// Couleur Diffuse de l'objet
            o.Alpha = c.a;		// Alpha pour la transparance

			// Position du pixel dans l'environnement
            float2 pos = IN.worldPos.xz;

            ///////////////////////// Hydrographie ///////////////////////
            //float water0 = segment(_WaterSegmentCoords.xy, _WaterSegmentCoords.zw, pos, _WaterSegmentRadius);
            //float water1 = segment(_WaterSegmentCoords.xy, _WaterSegmentCoords.zw, pos, _WaterSegmentRadius);
            //float water = min(water0, water1);

            // approche naive :
            //if (water < 0.0)
            //    o.Albedo = lerp(o.Albedo, fixed3(0.5,0.6,0.7), 0.6);	// Lerp Combine 2 couleurs et applique une transparence.
            // Le if c'est le Mal dans un shader (cependant à l'echelle de ce projet minimal
            // ça ne se ressentira pas)
            // Autre approche naive avec blurring des frontières mais sans if
             //o.Albedo = lerp(o.Albedo, fixed3(0.5,0.6,0.7), max(-water * 10., 0.));
            
            
            ///////////////////////// Vegetation ///////////////////////
			
            if (isVeget(c.rgb))
            	o.Albedo = lerp(o.Albedo, fixed3(0.1,0.3,0.1), 0.6);
            	
            if (isVeget2(c.rgb))
            	o.Albedo = lerp(o.Albedo, fixed3(0.1,0.2,0.0), 0.3);
            	
            if (isVeget3(c.rgb))
            	o.Albedo = lerp(o.Albedo, fixed3(0.1,0.1,0.0), 0.2);
            
            if (isVeget4(c.rgb))
            	o.Albedo = lerp(o.Albedo, fixed3(0.0,0.1,0.0), 0.1);

        }
    ENDCG
}

// Fallback
Fallback "Diffuse"
}
