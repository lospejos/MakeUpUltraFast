# testclient: automated in-game shader screenshots

Gradle project (Fabric Loom, Minecraft 26.3, Fabric API, Iris, Sodium) that launches a real
client, loads a pack from `../shaders`, and takes screenshots with the Fabric client gametest API.
It needs a real GPU/window (a window appears for ~1 min per run). Requires Java 25 and Gradle.

## Usage

    cd testclient
    gradle runClientGameTest                 # MakeUp only; shots in build/run/clientGameTest/screenshots/
    ./compare.sh                             # MakeUp vs Complementary Unbound; shots in build/compare/<pack>/

- `-Ppack=<zip name>` picks the Iris pack (default `MakeUp.zip`, built by the `packShaders` task).
- Reference packs: put zips in `testclient/refpacks/` (git-ignored). Complementary Unbound r5.9.3 was
  downloaded from Modrinth (`R6NEzAwj`) as `refpacks/ComplementaryUnbound.zip`.
- Logs: `build/run/clientGameTest/logs/latest.log` (shader compile errors show up here).

## How it works

- The run dir is `build/run/clientGameTest` and is wiped by the run task, so the zip and
  `config/iris.properties` are installed in a `doFirst` of `runClientGameTest` (see `build.gradle`).
  The task name is `runClientGameTest` (capital T).
- `ShaderTest.java` creates a world, sets time/weather via server commands, and auto-aims the camera:
  it sweeps yaw/pitch, finds the brightest large blob (box-blurred luma, ignores stars and the
  bottom 25% of the frame), and re-centers on it. Needed because packs tilt the sun path differently
  (`sunPathRotation`), so fixed angles do not hit the sun/moon in every pack.
- Moon phase k is shown at time `24000 * k + 15000`. Screenshots named `*_aim*` are
  intermediate and are dropped by `compare.sh`.
- `hideGui` is not available in 26.3 (`options.hideGui` does not exist), so the HUD stays in shots.
