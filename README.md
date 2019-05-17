# VRChat-Mobile-ToonLit
ACiiL. Discord ACIIL#4694.

Modified the SDK mobile friendly VRChat-Mobile-ToonLit.shader with versions to support vertex lights. The 4 dynamic pass lights will become the 4 vertex inputs. The theory here is applicable for upgrading all other official shaders with this MIT licence.

Apply these shaders to you PC version of the avatar and enjoy having it light up in PC worlds where such expect point and spot lights as well as mirrors with pixel lights quality off (its vertex lit quality).
Do not apply these shaders on you Quest avatar, only whitelisted work.



VRChat-Mobile-ToonLit-4VL.shader    - Runs 4 lights, attenuation is influenced most by closest light.
VRChat-Mobile-ToonLit-1VL.shader    - Only Runs the 1st primary.



Shader developers wanting to use this source. For performance in this particular implementation the vertex light sampling is in vertex pass thus light detail is dependent on mesh smoothness. If you want smoother falloff you may solve the entire vertex lights function (including world Position) in fragment() and enjoy a much smoother and even radial falloff.