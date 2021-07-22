## Openstreetmap

Please register at openstreetmap and examine the map. OSM is a great project. 

The whole world consists of either POIs or WAYs. 

A Poi is a "Point of interest" which refers to a single point in the map. 
A Way is a line or multiple lines which are connected to each other and are considered as "closed" (e.g. buildings) or "open" (e.g. rivers).

Each poi and each way may have multiple tags which are technically a collection of key-value pairs. 
The key-value pairs are relatively strict in their naming convention. If you try to edit the OSM map
or examine their documentation you can see suggested key-value pairs. This helps us (and OSM) to
understand the meaning of the entry and render it accordingly. 

## Mapsforge map

The mapfiles of mapsforge are a condensed form of an area consisting of the above OSM information. 
Please consult the mapsforge documentation on how to create mapfiles from osm data. 

This project is able to read mapfiles and render them visually.

Mapfiles contains the poi's and way's along with their tags. They are separated by zoom levels (grouped together) and are consisting
of several block's. Each mapfile has header information about the internal structure as well as metadata.  

## Structure of the program

### Reading from mapfiles

Mapfiles are read with ReadBuffer and MapFile classes. The portion which has been read is stored in MapReadResult classes which are nothing more than
a collection of points and ways for the area read from the MapFile. 

### Rendering process part 1

How to render these information is described in an xml file. Check the example defaultrender.xml file. 
The file consists of several (nested) rules. Each rule describes which poi's or way's are matching the 
rule (based on their tags). The rule then contains several instructions how to render the matching data. 

The same applies to the source. See RenderInstruction and its inherited classes. These classes have 
two purposes. On the one hand to read the xml file (renderinstruction) and parse it into the source class structure. 
On the other hand to receive the actual data from the MapReadResult and perform the drawing of the tile-image (see below). 

The whole world is split into tiles (bitmaps) which quadratical size of 512 pixel (see DisplayModel.tileSize). 
So in order to view a portion of the map you need to know which area (lat/lon) you want to see and at which zoom level. 
At zoom level 0 there is only one tile which contains the whole world (in 512 pixels). 
At zoom level 1 there are 4 tiles (2*2), at zoom level 2 there are 16 (4*4) and so on (power of 2). 

### Flutter view

The MapView class together with the TileLayerImpl class does the basic job of presenting the map to the user. 
The TileLayerImpl calculates the necessary tiles based on the current view and zoomlevel and checks the cache 
if the corresponding tile-bitmap is available and presents it to the user (if found). 

If the image is not available it asks JobQueue to create the missing images. As soon as JobQueue has 
created at least one image it informs tileLayer and the view is rendered again with the new image 
included and so on until all images are created. 

### Rendering process from the other side

JobQueue by itself calls the DataStoreRenderer to perform the actual rendering. The MapOnlineRenderer 
performs a http call to retrieve the image in question from the internet whereas the 
(more interesting) mapdatastoreRenderer performs the rendering by using the MapFiles.

It Reads the MapFile and retrieves the area of the map as MapReadResult structure. It then calls 
the RenderInstruction classes structures to analyze the POIs and WAYs from the MapReadResult and to 
let them render the actual bitmap. 

When the bitmap is finished it will be stored in the cache and returned to the JobQueue which in turn 
informs the tileLayer as described above. 


That's all folks, easy, isn't it?
