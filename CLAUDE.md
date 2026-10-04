# MakeUp Ultra Fast (lospejos fork)

Minecraft shader pack (GLSL, OptiFine/Iris format) in `shaders/`. Target: Minecraft 26.3 with Fabric + Iris.

## Verifying shader changes in game

Do not guess: run the automated client in `testclient/` (see `testclient/README.md`).
`testclient/compare.sh` renders the same camera/time with MakeUp and Complementary Unbound.
The user's own Prism instance may load a stale copy of the pack, so judge by the testclient shots.

## Sun / moon rendering (shaders/common/skytextured_*.glsl)

- In 26.3 the sun/moon sprite is a small square in the middle of a larger quad; a round alpha mask
  on the quad does not help. The pack draws a procedural disk instead (quad geometry via
  `quad_xy` / `quad_corner` varyings, sizes `SUN_SIZE` / `MOON_SIZE`, both tuned to match the
  Complementary Unbound angular size).
- Moon: lit sphere driven by `moonPhase`, procedural maria and craters. Sun: flat warm disk.
- `gl_FragDepth = 1.0` is written so the sky-only cloud pass in `deferred_fragment.glsl`
  (`linearDepth > 0.9999`) also covers the sun/moon (clouds must hide the sun).
- Stars (`skybasic_fragment.glsl`): use their own light color; before, they took the sky color and were invisible.
- The `world1` / `world-1` skytextured files include the same common files (not visually tested there).
