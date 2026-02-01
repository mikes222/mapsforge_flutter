# MenuOverlays (StyleMenuOverlay)

## Purpose
`MenuOverlay` / `MenuOverlays` refers to the **UI overlay** that lets the user select a *style/layer* defined in a Mapsforge RenderTheme `<stylemenu>`.

In this codebase the concrete widget is:

- `StyleMenuOverlay` (`packages/mapsforge_flutter/lib/src/overlay/style_menu_overlay.dart`)
- It renders a `StyleMenuBar` (`packages/mapsforge_flutter/lib/src/overlay/style_menu_bar.dart`) with selectable layers.

The overlay itself is **pure UI**. It does **not** automatically change the map theme. Instead it informs your app which layer was selected.

## Where the data comes from
A Mapsforge RenderTheme can contain a `<stylemenu>` section. It is parsed into:

- `StyleMenu` (`packages/mapsforge_flutter_rendertheme/lib/src/model/style_menu.dart`)
- `StyleMenuLayer` (`packages/mapsforge_flutter_rendertheme/lib/src/model/style_menu_layer.dart`)

Parsing is done in:

- `RenderThemeBuilder._parseStyleMenu()` / `_parseStyleMenuLayer()`
  (`packages/mapsforge_flutter_rendertheme/lib/src/xml/renderthemebuilder.dart`)

## XML configuration (`<stylemenu>`)
A style menu looks like this (simplified):

```xml
<stylemenu id="styles" defaultvalue="day" defaultlang="en">
  <layer id="day" enabled="true" visible="true">
    <name lang="en" value="Day" />
    <cat id="roads" />
    <cat id="pois" />
  </layer>

  <layer id="night" enabled="false" visible="true">
    <name lang="en" value="Night" />
    <cat id="roads_night" />
  </layer>

  <layer id="base" enabled="true" visible="false">
    <cat id="base" />
  </layer>
</stylemenu>
```

### `visible="true|false"`
Controls whether a layer is **shown to the user**.

Implementation details:

- `StyleMenu.visibleLayers` returns all layers with `visible == true`.
- If no layer has `visible="true"`, then **all layers are treated as visible**.

Relevant code:

- `StyleMenu.visibleLayers` (`packages/mapsforge_flutter_rendertheme/lib/src/model/style_menu.dart`)

### `enabled="true|false"`
Indicates whether a layer should be **enabled by default**.

Important:

- The `StyleMenuOverlay` / `StyleMenuBar` currently uses `StyleMenu.defaultValue` (or the first visible layer) to select an initial layer.
- The `enabled` flag is still valuable for your application logic when applying categories/overlays (see below).

Parsing:

- Attributes are parsed as optional `bool?` values in `_parseStyleMenuLayer()`.

## Using the overlay in your app
### 1) Obtain a `StyleMenu`
Load and parse a render theme that contains `<stylemenu>`. After parsing you should have access to a `StyleMenu` instance.

### 2) Show the overlay
Embed `StyleMenuOverlay` inside a `Stack` above your map widget:

```dart
Stack(
  children: [
    /* map widget */, 
    StyleMenuOverlay(
      styleMenu: styleMenu,
      initialLayerId: styleMenu.defaultValue,
      lang: 'en',
      onChange: (StyleMenuLayer layer) {
        // apply selection (see next section)
      },
    ),
  ],
)
```

Notes:

- The overlay positions itself at `top/left` using `Positioned`.
- There is a fade-in animation.

### 3) Apply the selected layer to rendering
When the user selects a layer, `onChange` is called with a `StyleMenuLayer`.

Your application should then decide how to apply it. Common approaches:

- **Compute active categories** via:
  - `styleMenu.categoriesForLayer(layer)`
  - This includes the layer’s categories plus categories from its `parent` and referenced `overlay` layers.
- Rebuild / reload your map rendering pipeline with the new active category set.

(Exactly how categories affect rendering depends on how you integrate the RenderTheme in your map renderer.)

## Reference: original Mapsforge documentation
Mapsforge RenderTheme documentation for style menus:

- https://github.com/mapsforge/mapsforge/blob/master/docs/Rendertheme.md#stylemenus

## Reference: style_menu_overlay
Implementation entry point in this repository:

- `StyleMenuOverlay`:
  `packages/mapsforge_flutter/lib/src/overlay/style_menu_overlay.dart`

Supporting widget:

- `StyleMenuBar`:
  `packages/mapsforge_flutter/lib/src/overlay/style_menu_bar.dart`
