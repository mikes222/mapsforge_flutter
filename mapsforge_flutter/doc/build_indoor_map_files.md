#  How to build indoor .map files from .osm or .osm.pbf files

## Step 1: Get a tag_mapping.xml file and extend it

Mapsforge maps do not contain any indoor data when creating a map using the mapsforge writers default settings. Therefore you need this: [tag-mapping.xml](https://github.com/mapsforge/mapsforge/blob/master/mapsforge-map-writer/src/main/config/tag-mapping.xml).

Additionally, this file needs to be extended to include tags used for indoor maps. You must specify all key-value pairs that appear in your osm file and put it inside the `<tag-mapping>` block. Here is an example:
```
<!-- INDOOR TAGS -->
<ways>
    <osm-tag key="indoor" value="room" zoom-appear="18"/>
    <osm-tag key="indoor" value="area" zoom-appear="18"/>
    <osm-tag key="indoor" value="wall" zoom-appear="18"/>
    <osm-tag key="indoor" value="corridor" zoom-appear="18"/>
    <osm-tag key="indoor" value="level" zoom-appear="18"/>
</ways>
<ways>
	<osm-tag key="door" value="yes" zoom-appear="18"/>
	<osm-tag key="material" value="concrete" zoom-appear="18"/>
	<osm-tag key="material" value="glass" zoom-appear="18"/>
	<osm-tag key="material" value="wood" zoom-appear="18"/>
	<osm-tag key="amenity" value="table" zoom-appear="18"/>
	<osm-tag key="amenity" value="bench" zoom-appear="18"/>
	<osm-tag key="amenity" value="shelf" zoom-appear="18"/>
	<osm-tag key="amenity" value="glass_cabinet" zoom-appear="18"/>
</ways>

<pois>
	<osm-tag key="material" value="concrete" zoom-appear="18"/>
</pois>

<ways>
    <osm-tag key="level" value="%f" zoom-appear="18"/>
    <osm-tag key="level" value="%s" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="%f" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="%s" zoom-appear="18"/>
</ways>

<!-- problems with %s for pois in mapfile-writer -> need to specify every used level -->
<pois>
    <osm-tag key="level" value="%f" zoom-appear="18"/>
    <osm-tag key="level" value="-2" zoom-appear="18"/>
    <osm-tag key="level" value="-1" zoom-appear="18"/>
    <osm-tag key="level" value="0" zoom-appear="18"/>
    <osm-tag key="level" value="1" zoom-appear="18"/>
    <osm-tag key="level" value="2" zoom-appear="18"/>
    <osm-tag key="level" value="3" zoom-appear="18"/>
    <osm-tag key="level" value="4" zoom-appear="18"/>
    <osm-tag key="level" value="5" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="%f" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="-2" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="-1" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="0" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="1" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="2" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="3" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="4" zoom-appear="18"/>
    <osm-tag key="repeat_on" value="5" zoom-appear="18"/>
</pois>
```
With the first lines of code we include every `ways` with the `indoor` tag and the corresponding common values for [simple indoor tagging](https://wiki.openstreetmap.org/wiki/Simple_Indoor_Tagging). You can add other indoor related key-value pairs for ways here.

The second section defines special nodes or `pois` (points of interest) used while mapping. These can later be rendered e.g. as small circles or displayed as caption or icon and should be added here.

In the third section all ways with an `level` or `repeat_on` key are included. The value `%f` stands for every value that can be interpreted as number such as `2` or `2.0`. All other values are simply considered as String with the `%s` keyword.

Unfortunately the mapfile writer has problems with the `%s` keyword when parsing pois. Therefore you can only use the `%f` keyword and for safety reasons specify all values used for the `level` and `repeat_on` key in your osm file, as you can see in the fourth section. In this example we only used single levels from -2 to 5 as values, but also strings like `0; 1; 2; 3` are possible.


## Step 2: Download Osmosis and the Map-Writer-Plugin

Osmosis is the main tool to transform osm data. Look up the latest stable version [here](https://wiki.openstreetmap.org/wiki/Osmosis#Latest_stable_version), go to the download page on GitHub, download and install it. Remeber the installation folder.
If installed with homebrew via `brew install osmosis`, it can be found at `/usr/local/Cellar/osmosis/<VERSION>/bin/osmosis`.

In order to transform the data into a .map file, you need to install the map-writer plugin. Therefore create a folder called 'plugins' next to the bin and libexec folders. In the example above it should be:  `/usr/local/Cellar/osmosis/<VERSION>/plugins/`.

Now download the mapsforge-map-writer (select "jar-with-dependencies" when clicked the download icon) from [Maven Central](https://search.maven.org/search?q=a:mapsforge-map-writer). Move the jar file from your downloads folder into the plugins directory you just created.

If you have trouble installing the writer-plugin, you can read further information [here](https://github.com/mapsforge/mapsforge/blob/master/docs/Getting-Started-Map-Writer.md#plugin-installation).


## Step 3: Prepare your data

There are 2 formats of osm data you can use to create .map files: `.osm` and `.osm.pbf`.
Usually these data are downloaded from osm servers. For example you can download `.osm` files of specified areas from [openstreetmap](https://www.openstreetmap.org) or `.osm.pbf` files of whole states from [GEOFABRIK](https://download.geofabrik.de/).

These downloaded files are already ready for the conversion. So if you haven't touched/changed the file (you can change the filename, that is ok), you can skip this section and continue with step 4.

Otherwise if you added or modified any data manually, you have to follow the next sub-steps. It is recommended to copy your osm file before this step to prevent irreversible damage to the file as you will have to manually edit it.

### Step 3.1: Add missing attributes to modified files

OSM files are just more or less standardized xml files with a header for general information as well well as all nodes, ways, relations - each containing additional information (attributes). By uploading the osm file to an osm server, the file automatically receives a set of modified and additional attributs for all nodes, ways, and relations from the server which are required by the mapfile writer to convert properly. Here is a list of attributes that should be found in all nodes, ways, and relations:
- an id > 0   [`id="20465986"`]
- a visible statement   [`visible="true"`]
- a version number   [`version="1"`]
- a changeset number   [`changeset="475804"`]
- a timestamp   [`timestamp="2021-06-11T12:51:34Z"`]
- a username   [`user="JohnDoe"`]
- a user-id   [`uid="1234"`]
nodes only:
- a latitude   [`lat="50.8125743"`]
- a longitude   [`lon="12.9318745"`]

So if your data is missing some attributes the easiest way to add/modify them is by using the find-and-replace function of a text editor like [Xcode](https://apps.apple.com/de/app/xcode/id497799835?mt=12) (Mac) or [Notepad++](https://notepad-plus-plus.org/downloads/) (Windows). Therefor, change the name of your file from `myOsmFile.osm` to `myOsmFile.xml` at first to open it correctly. Look for some nodes or ways and check which attributes are missing. Via find-and-replace you can add them like in the following example.

In this example a node looks like this:
```
<node id="-104099" action="modify" visible="true" lat="50.84176020006" lon="12.92692686547" />
```
It does not matter whether the values have a single `'` or a double `"`.
We can remove the `action` key if the value is `"modify"` as it is of no use anymore. Therefore, find all ` action="modify"` with one blank space in front and replace it with nothing. This way we guarantee to keep one blank space between every attribute:
```
<node id="-104099" visible="true" lat="50.84176020006" lon="12.92692686547" />
```
Now to add the missing attributes we can for example simply replace the `visible` attritbute with itself and the rest: `timestamp="2021-05-23T07:16:19Z" uid="12345678" user="JohnDoe" visible="true" version="1" changeset="123456789"`. This way we keep the usual order of attributes. (The order does not matter for the mapfile writer, but it is good habit to keep information uniform.) Our example will look like this now:
```
<node id="-104099" timestamp='2021-05-23T07:16:19Z' uid='12345678' user='JonDoe' visible='true' version='1' changeset='123456789' lat="50.84176020006" lon="12.92692686547" />
```
Finally we have to make every id positive. This is actually divided into two parts. The fist part is replacing every `id="-` by `id="` to simply erase the negative sign:
```
<node id="104099" timestamp='2021-05-23T07:16:19Z' uid='12345678' user='JonDoe' visible='true' version='1' changeset='123456789' lat="50.84176020006" lon="12.92692686547" />
```
The second part is very similar: replace all `ref="-` by `ref="` to set all the node references of the ways and relations right.

### Step 3.1: Add the missing boundary box

Just like the version attributes your file could be missing one information, usually provided by a server when downloading. If the first 3 rows of your osm or respectivly xml file looks like this:
```
<?xml version="1.0" encoding="UTF-8"?>
<osm version="0.6" generator="JOSM">
    <node id="104099" timestamp='2021-05-23T07:16:19Z' uid='12345678' user='JonDoe' visible='true' version='1' changeset='123456789' lat="50.84176020006" lon="12.92692686547" />
```
, then you need to define the bounding box in here.
Find out the 4 boarders of your mapped area in terms of highest and lowest value of each longitude and latitude and add them in front of the first node like in the example below.
```
<?xml version="1.0" encoding="UTF-8"?>
<osm version="0.6" generator="JOSM">
    <bounds minlat="50.8412200" minlon="12.9259400" maxlat="50.8419200" maxlon="12.9280500"/>
    <node id="104099" timestamp='2021-05-23T07:16:19Z' uid='12345678' user='JonDoe' visible='true' version='1' changeset='123456789' lat="50.84176020006" lon="12.92692686547" />
```
Be generous and add a little more space to the boundary to avoid clipping. Floor a `minlat` of 50.8412220 to 50.8412200 and ceil a `maxlat` of 50.8419171 to 50.8419200!

These bounding box information can also be provided by a commandline parameter `bbox` as mentioned in step 4.

When you are done do not forget to undo the renaming, this time from `myOsmFile.xml` to `myOsmFile.osm`.


## Step 4: Build the command line

At first we want Osmosis to read the osm input file (which can be read as xml). So we start with the read-xml command: `osmosis --rx file="myOsmFile.osm"`.

Secondly we want the mapfile-writer to give us the .map file as output: `--mapfile-writer file=myMapFile.map`.

We can also tell the writer to use the hard drive for converting as we have limited RAM by default. This option is crucial for larger files (e.g. most .osm.pbf files): `type=hd` 

Furthermore we have to give information about the tagged indoor data (which we already specified in the tag-mapping.xml file) using two additional parameters: `tag-conf-file=tag-mapping.xml tag-values=true`.

If you have not defined a bounding box in your osm/xml file like described in step 3.2, you have to pass it as a parameter within the command. The parameter must look like this `bbox=minLat,minLon,maxLat,maxLon` in exactly this order as degrees.

To play save with osmosis finding the map-writer-plugin, you should navigate to your osmosis directory at first and start the conversion from there. In the example of step 2 the command should be: `cd /usr/local/Cellar/osmosis/<VERSION>`

If you have also moved your .osm file as well as the tag-mapping.xml in this directory, this is the complete command to build your map file: 
```
bin/osmosis --rx file="myOsmFile.osm" --mapfile-writer file=myMapFile.map type=hd tag-conf-file=tag-mapping.xml tag-values=true
```



# Some common Errors and Fixes

## Error: The operation couldn’t be completed. Unable to locate a Java Runtime.

It seems like your system is missing a java runtime environment. Usually this problem is fixed by installing a [recommended java jre (e.g. version 8)](https://www.java.com/de/download/manual.jsp) or a [jdk](https://www.oracle.com/de/java/technologies/javase/javase-jdk8-downloads.html) which includes the corresponding jre.

If you are on Mac and using homebrew, follow [these steps (1.1 to 1.7)](https://mkyong.com/java/how-to-install-java-on-mac-osx/#homebrew-install-latest-java-on-macos) to install and link the necessary jre.


## Error: Task type mapfile-writer doesn't exist.

Osmosis couldn't find the map-writer plugin. So the plugins folder from Step 2 seems to be in a wrong directory. Try to move the plugins folder one level up or down. If the error still exists you have to set your working directory to the original osmosis, e.g. /usr/local/Cellar/osmosis/0.48.3/ like in the example from step 2. Then you must call osmosis via bin/osmosis in the command line and have the plugins folder as well as your files in here (0.48.3).


## Error: Cannot begin reading in Add stage, must call complete first.

If you have the parameter `type=hd` set to the mapfile-writer, remove it and try again.


## Error: Node X does not have a version attribute as OSM 0.6 are required to have. Is this a 0.5 file?

There are still nodes which are missing some attributes. Check step 3.1.


## Error: No valid bounding box found in input data. / tile based data store not initialized, missing bounding box information in input data'.

There is still a bounding box missing in your osm/xml file or your command line. Check step 3.2.
