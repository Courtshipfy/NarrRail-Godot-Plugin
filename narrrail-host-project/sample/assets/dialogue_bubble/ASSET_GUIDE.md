# Dialogue Bubble Art Handoff

The sample uses replaceable SVG artwork. Production art can use transparent PNG files with the same split: one body texture plus independent left and right tails.

## Body

- Reference canvas: `192 x 128 px`
- Godot nine-patch margins: left `34`, top `30`, right `34`, bottom `30`
- Minimum rendered body size: about `174 x 104 px`
- Keep corners, outline joins, and decorative border marks outside the stretchable center.
- Keep the center mostly flat. Put paper grain in a tiled overlay or shader instead of baking large unique marks into the stretched center.
- Current text safe area: `31 px` from the left/right edge, `54 px` above the dialogue text, and `30 px` below it.

## Tails

- Reference canvas: `64 x 52 px`
- Provide left- and right-pointing variants.
- The top `8 px` overlap the body so scaling does not reveal a seam.
- Keep the connection width compatible with a flat section of the body border.
- The code positions the tail within the middle 56% of the body width, away from the corners.

## Recommended Delivery

- Transparent body PNG or SVG with no text
- Left and right tail PNG/SVG files
- A marked nine-patch guide showing the four cut lines
- Minimum-size preview
- Text safe-area preview
- One short-line and one wrapped long-line mockup
- 1x and 2x exports if PNG is used

The component sizing values live in
`res://sample/scripts/dialogue_bubble/dialogue_bubble.gd`. Replace the textures first; only adjust padding and patch margins when the new silhouette requires it.

`resize_duration` controls the width/height transition time and defaults to `0.42` seconds. The component emits `layout_changed` throughout the transition so the containing scene can keep the tail tip aligned with the speaker.
