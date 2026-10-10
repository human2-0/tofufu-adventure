Godot SSR Water by Marcel Bankmann, MIT.
Asset Library: https://godotengine.org/asset-library/asset/2152
Source: https://github.com/marcelb/GodotSSRWater
Pinned revision: 391b2f9f9fc289c8ef0ccc2889cf53b5d3cfdaec
Only the water shader and license are vendored. The original shader is unmodified.
The package is inactive reference material. Runtime volcanic and northern water both
use `game/world/common/ocean_water.gdshader` through `OceanMaterial`, with analytic
waves and authored vertex depth. No SSR shader or procedural noise textures load.

Earlier derivatives beside this folder remain inactive; they preserve the original
MIT header. The Mobile renderer remains the project default.
