# Structure of this library

## Mapfiles

A mapfile is a file containing condenced informations about maps. There are 2 types of items available. _PointsOfInterest_ and _Way_. 
Both can contain a list of Tags. A _Tag_ is a simple key-value pair. 

Note: Login to OpenStreetmap (https://www.openstreetmap.org) and make yourself familiar with usual key-value pairs for pois and ways. 

## Reading mapfiles

The class ```MapFile``` is used to read the mapfile from disc. The actual read-process is done by ```ReadBufferSource```. It is performed with
```RandomAccessFile```. 

A mapFile is organized in _Blocks_. We need to read data for a _Tile_. 
In order to do that the system calculates the blocks needed for a tile. 

## Specifying how the data should be rendered

We use a xml file to specify how the poi and map data should be rendered to screen. 
The xml file contains of _Rules_ and _Instructions_. Rules specifies if the way/poi currently under investigation applies to the contained instructions. If so the way/poi will be rendered accordingly. One way/poi can apply to several rules. An example is a way with the following tag:

<code>
Tag('highway', 'motorway'), Tag('ref', 'Route 66')
</code>

According to the file ```rendertheme.xml``` the following rules apply:

    <rule e="way" k="highway" v="motorway">
        <line stroke="#FF0000" stroke-width="2.5" />
    </rule>

    <rule e="way" k="highway" v="motorway">
        <line stroke="#FFFF00" stroke-width="1.7" />
    </rule>

    <rule e="any" k="highway" v="motorway" zoom-min="12">
        <pathText fill="#FF0000" font-size="14" font-style="bold" k="ref" priority="-4"
            stroke="#FFFF00" stroke-width="3.0" />
    </rule>

This means we draw a thick line in red (FF0000), then a line in yellow (FFFF00) and for zoomLevel >= 10 we draw the name of the motorway (k="ref") in red and yellow.

## Preparing the graphics

After the Ways and Pois are read from the mapfile the renderinstructions are applied according to the rules of the xml file described above. 
The properties of the mapfile are stored in ``Shape`` objects (one for each zoomLevel). 

Later on we instantiate ``PaintShape`` objects. These objects will perform the actual drawing onto the canvas. 

## Drawing into tiles

The canvas where the map should be drawn is split into tiles. The size of the tiles are always of the same height/width.  
The renderer ``MapDatastoreRenderer`` coordinates the reading of the mapfile, applies the rules of the rendertheme and draws the result to the canvas. The canvas will then be converted to a png-file with the size of a tile and used as a part of the widget to draw the map. The png file is also cached to memory and/or to file. 

## ZoomLevel

With zoomLevel 0 the whole world fits into one tile. Therefore the size of a tile also determines how big the world will be shown at a certain zoomLevel. 
ZoomLevel 1 means that the whole world will fit onto 4 tiles (2*2) and so on. Each increase of the zoomlevel doubles the size of the world and hence performs a zoom-in for the user. 
Usually zoomLevel 24-ish has a quite large resolution of about 30 cm of the map per 1 cm on screen. 

## IndoorLevel

Some mapfiles also support indoor levels. This library also supports that feature. See example for more infos. 

