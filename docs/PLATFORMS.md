# Platform setup

The shared offline game now accepts keyboard/mouse, gamepad and multitouch actions. Export presets are development baselines, not certification or store-ready releases. Godot 4.7.2 is the locally tested editor; install matching export templates. Desktop Holepunch co-op is implemented for the existing adventure; see [runtime setup](../networking/README.md). Mobile and console networking integration remains unimplemented.

## Controls

| Action | Keyboard / mouse | Standard gamepad position | Touch |
| --- | --- | --- | --- |
| Walk | WASD / arrows | Left stick (analog) / D-pad | Direction buttons |
| Aim | Mouse | Right stick; otherwise travel direction | Travel direction |
| Jump / super jump | Hold Space to charge, release to jump | Hold south face button, release | Hold Jump, release |
| Dash | Shift | East face button | Dash |
| Knife / charge | Left mouse button / hold then release | West face button / hold then release | Sword / hold then release |
| Guide | Tab | Remappable in Settings | Guide |
| Nearby text / send | Enter; Escape cancels | Keyboard required | Keyboard required |
| Yell farther | Megaphone button in composer | — | Composer button |
| Nearby voice | Enable Mic, then hold V; Listen toggles reception | — | — |
| Pause menu | Escape | Start | — |
| Return to camp | R | Select / Back | Camp |
| Skip six hours | N | North face button | Keyboard/controller only |

RMB / right shoulder now holds directional knife guard. Desktop F punches with either slot, 1/2/3 selects knife/fists/soybean gun, Q drops the knife, and E picks it up nearby. The additional equipment/punch controls are desktop bindings; touch equipment controls are not yet implemented.

With the gun selected, LMB fires continuously and RMB tightens accuracy (20 body / 40 head damage). C toggles overhead and behind-character camera modes; mouse movement freely orbits in the latter while retaining actor aim. Holding LMB turns Fufu toward the camera target and tracks it while firing. RMB also refocuses Fufu and adds precise aim and zoom. Releasing both retains the latest aim for free orbit. Camera mode and gun slot are remappable desktop actions; dedicated touch/gamepad orbit controls are not implemented. Soybean gun friendly fire is enabled in co-op.

Use physical positions because Nintendo and Xbox label layouts differ. Godot's standard mapping calls south `JOY_BUTTON_A`, east `JOY_BUTTON_B`, west `JOY_BUTTON_X`. Verify the mapping on each target's controllers. Mouse movement/clicks reclaim pointer aim; deliberate controller input or touch selects directional aim. Stick deadzones are 0.20 for travel and 0.25 for aim. At rest, directional aim is retained; dash follows travel or retained aim. Movement, jumping and dashing retain their existing bindings. All connected pads currently control the single local player; this is not local multiplayer or controller assignment.

Touch controls appear on touchscreen devices and support simultaneous holds. Touch does not synthesize mouse clicks, avoiding accidental sword charges and mouse-facing changes. The touch layout uses directional buttons, not a virtual analog stick; independent touch aiming is not implemented.

Text reaches 12 world units, or 36 with Yell. Voice reaches 12 units and fades with distance. The corner history retains the last 50 received messages for this adventure session. Voice requires desktop co-op and OS microphone permission; use headphones. Physical microphone and cross-network voice quality remain to be verified.

## Rendering and display

Project choice: retain the Mobile renderer, Jolt, 60 Hz physics and existing 3D presentation. The UI scales from 1280×720 and expands for different aspect ratios; desktop window minimum is 960×540. Handheld orientation is sensor landscape. Desktop retains 2× MSAA; mobile disables MSAA as an initial performance baseline. ETC2/ASTC imports are enabled for mobile textures. These choices do not establish a minimum supported device or guarantee a frame rate.

Inspect display cutouts and safe areas on physical phones, especially HUD panels close to screen edges. Device-specific safe-area padding, quality selection, suspend/resume behavior, accessibility and native platform integration remain release work. The game menu provides keyboard/mouse and controller remapping, a stick deadzone slider, and resolution/fullscreen settings with a timed revert. Rendered desktop, wide phone and tablet layouts can be checked with `tests/preview_controls.gd`; this is not device validation.

## Exports

Open **Project → Export**. Presets exclude tests, docs, tools and build output. Builds go under ignored `builds/` subdirectories (create the destination directory before command-line export).

| Preset | Configuration | Required before distribution |
| --- | --- | --- |
| Windows | x86_64 executable | Matching templates; Windows hardware testing; optional publisher signing |
| Linux | x86_64 executable | Matching templates; Linux hardware/driver testing |
| macOS | Universal Intel/Apple Silicon ZIP, unsigned | Owned bundle ID, signing identity and notarization for normal distribution |
| Android | ARM64 APK, prebuilt template for device testing | JDK/Android SDK paths, matching templates, device |
| Android Store | ARM64 AAB, Gradle enabled | Install Android build template; SDK/JDK; release keystore; owned package ID; current store requirements |
| iOS | Xcode project export | macOS/Xcode, templates, owned bundle ID, Apple team ID, signing/provisioning and device |
| Switch / PlayStation | No public preset | Platform developer approval, SDKs, approved Godot port/export tooling, devkits and certification |

`com.example.tofufuadventure` is deliberately a placeholder: replace it with an identifier you own before establishing store listings. Version defaults are 0.1.0 / build 1. Never commit signing keys, passwords or provisioning profiles. Local credentials and common signing file extensions are ignored. This change does not enroll developer accounts, download proprietary SDKs or publish builds.

Example, after installing templates:

```sh
mkdir -p builds/windows
/path/to/godot --headless --path . --export-debug Windows builds/windows/Tofufu.exe
```

For release, configure target signing options and use `--export-release`. Android Store requires Gradle build support; the APK preset is the simpler device-test path. Use a physical iOS device with the Mobile renderer; Godot's iOS simulator supports Compatibility only.

Godot console templates use proprietary SDKs and are shared privately with approved developers. Arrange a porting provider or an approved in-house port for Switch and PlayStation. Keep platform services outside movement rules; the Node sidecar integration must separately prove console support and platform-policy compatibility before promising cross-platform co-op.

## Local validation status

Godot 4.7.2 imported the project and passed architecture, input, movement, combat, sword, sandbox and scene checks. Actual Godot viewport renders were inspected at 1280×720, 1560×720 and 960×720. Synthetic input tests include simultaneous three-finger movement/jump/charge and release cleanup; physical controllers and mobile hardware have not been tested.

A Windows resource pack exported successfully and launched headlessly outside the source project. A Windows debug executable export was attempted but the matching Windows export templates are not installed locally. No executable build, signed mobile build or console build has been validated.

## Upstream references

- [Godot console support](https://godotengine.org/consoles/)
- [Controller support and mappings](https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html)
- [Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- [Android export setup](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
- [iOS export setup](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)
- [macOS export and signing](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html)
