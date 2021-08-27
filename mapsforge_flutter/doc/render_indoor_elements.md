# How to render indoor elements

If you build a `.map` file with uncommon indoor tags (see the [How to build indoor .map files](https://github.com/mikes222/mapsforge_flutter/blob/master/mapsforge_flutter/doc/create_indoor_map_files.md) instruction) and test it in the example app, you might miss some data.
That's because the renderer is missing the commands how to render specific objects.

The rendering is defined via the render theme.
In order to display specific indoor elements the render theme has to be extended by them.
This theme is defined within a `.xml` file.
An already customized render theme file for indoor rendering is located [here](https://github.com/mikes222/mapsforge_flutter/blob/master/example/assets/custom.xml].

The example code below will display all indoor rooms and areas in blue while walls will be colored in gray.
```
<rule e="any" k="indoor" v="*" zoom-min="18">
    <rule e="way" k="indoor" v="*" closed="yes">
        <area fill="#0000FF" stroke="#888888" stroke-width="0.1" />

        <rule e="way" k="indoor" v="wall">
            <area fill="#888888"/>
        </rule>
    </rule>
</rule>
```

Note that the renderer parses the file top-down.
Areas further down in the file will be rendered later and thus over areas further up.
In the example above the walls will cover over the rooms.

More information about indoor tags can be found here: [Simple Indoor Tagging](https://wiki.openstreetmap.org/wiki/Simple_Indoor_Tagging#Multi-level_features_and_repeated_features).
