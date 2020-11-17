# Indoor Rendering

## How to create a map file with indoor data

Mapsforge maps do not contain any indoor data when creating a map using the mapsforge writers default settings. Therefore the [tag-mapping.xml](https://github.com/mapsforge/mapsforge/blob/master/mapsforge-map-writer/src/main/config/tag-mapping.xml) needs to be extended by the following lines of code:
```
<ways>
    <osm-tag key="indoor" value="room" zoom-appear="18"/>
    <osm-tag key="indoor" value="area" zoom-appear="18"/>
    <osm-tag key="indoor" value="wall" zoom-appear="18"/>
    <osm-tag key="indoor" value="corridor" zoom-appear="18"/>
    <osm-tag key="indoor" value="level" zoom-appear="18"/>
</ways>

<ways>
    <osm-tag key="level" value="%f" zoom-appear="18"/>
    <osm-tag key="level" value="%s" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="%f" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="%s" zoom-appear="18"/>
</ways>

<pois>
    <osm-tag key="level" value="%f" zoom-appear="18"/>
    <osm-tag key="level" value="%s" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="%f" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="%s" zoom-appear="18"/>
</pois>
```
When using Osmosis to generate a new map file containing indoor data the extended tag-mapping.xml file should be specified with the `tag-conf-file` parameter. The `tag-values=true` parameter is required as well in order to extract the variable values of the level and repeat_on key.

Example command:
`bin/osmosis --rx file="map.osm" --mapfile-writer file=map.map type=hd tag-conf-file=tag-mapping.xml tag-values=true`

## How to render indoor elements
The rendering is defined via the render theme. In order to display indoor elements the render theme has to be extended as well. The example code below will display all indoor rooms and areas in blue while walls will be colored in gray.
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

More information about indoor tags can be found here: [Simple Indoor Tagging](https://wiki.openstreetmap.org/wiki/Simple_Indoor_Tagging#Multi-level_features_and_repeated_features).