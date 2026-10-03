# Ore glow: adding ores from other mods

Ore glow makes the colorful pixels of ore blocks (diamonds, gold, redstone, etc.) shine in the dark. The surrounding stone does not glow.

Ores from mods do not glow by default. The shader pack only treats a block as an ore if its ID is listed in `shaders/block.properties`. You do not need to change the mods themselves.

## How to add a modded ore

1. Find the block ID in game: press `F3` and look at the targeted block. The ID is shown as `modid:block_name`, for example `examplemod:ruby_ore`.
2. Open `shaders/block.properties`.
3. Find the line that starts with `block.10091 =`. It is under the `# ORES` comment.
4. Append the block ID to the end of that line, separated by a space:

   ```
   block.10091 = coal_ore iron_ore ... examplemod:ruby_ore examplemod:deepslate_ruby_ore
   ```
5. Save the file and reload shaders in game (`R` in the shader screen, or re-select the pack).

## Rules

- Blocks from mods need the namespace: `modid:name`. Only vanilla blocks may be written without it.
- `block.properties` has two sections, split by `#if MC_VERSION >= 11300` / `#else`. The first is for Minecraft 1.13 and newer, the second for 1.12 and older. Edit the section that matches your Minecraft version. In the 1.12 section, blocks with variants use `modid:block:variant=value`.
- Block states can be given as `modid:block:property=value`.
- Wildcards such as `*_ore` are not supported. Each block must be listed by its full ID.
- Each ID must appear in only one `block.XXXXX` line. If a block is already in another group (for example the metal group `block.10400`), remove it from there first.

## Tuning

- `ORE_GLOW` in `shaders/lib/config.glsl` sets the glow strength. `0.0` turns it off. The default is `0.8`.
- Only pixels with enough color saturation glow. If a modded ore has a mostly gray texture, its glow will be weak. Lower the threshold in `smoothstep(0.12, 0.25, ...)` in `shaders/common/solid_blocks_fragment.glsl` to make more pixels glow.

## Limits

- Ores in Voxy and Distant Horizons distant terrain do not glow.
- The pack has no in-game menu option for ore glow yet.
