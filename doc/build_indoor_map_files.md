# Building Indoor Map Files from OSM Data

A comprehensive guide for creating indoor-enabled Mapsforge map files from OpenStreetMap data sources.

## Overview

This guide walks you through the complete process of converting OSM or OSM.PBF files into Mapsforge map files with indoor mapping support. The process involves configuring tag mappings, setting up the conversion tools, and handling common issues that may arise.

**What you'll need:**
- OSM or OSM.PBF source data
- Osmosis with Map-Writer plugin
- Custom tag mapping configuration
- Java Runtime Environment

## Step 1: Configure Tag Mapping for Indoor Data

### Understanding the Requirements

Mapsforge maps exclude indoor data by default. To include indoor mapping features, you need to extend the standard tag mapping configuration with indoor-specific tags.

**Download the base configuration:**
[tag-mapping.xml](https://github.com/mapsforge/mapsforge/blob/master/mapsforge-map-writer/src/main/config/tag-mapping.xml)

### Adding Indoor Tag Mappings

Extend the base configuration by adding indoor-specific tags within the `<tag-mapping>` block:
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

### Configuration Sections Explained

**Indoor Ways Section:**
The first section includes all `ways` with the `indoor` tag and common values for [Simple Indoor Tagging](https://wiki.openstreetmap.org/wiki/Simple_Indoor_Tagging). Add additional indoor-related key-value pairs for ways as needed.

**Points of Interest (POIs):**
The second section defines special nodes used in indoor mapping. These can be rendered as circles, captions, or icons in your final map.

**Level and Repeat Tags:**
The third section handles `level` and `repeat_on` keys:
- `%f` matches numeric values like `2` or `2.0`
- `%s` matches string values (has limitations with POIs)

**Important Limitation:**
The mapfile writer has issues with `%s` for POIs. Use `%f` for numeric values and explicitly specify all string values used in your OSM file, as shown in the fourth section. This example covers levels -2 to 5, but complex strings like `0; 1; 2; 3` are also supported.


## Step 2: Install Osmosis and Map-Writer Plugin

### Installing Osmosis

Osmosis is the primary tool for transforming OSM data. Choose your installation method:

**Option A: Direct Download**
1. Check the [latest stable version](https://wiki.openstreetmap.org/wiki/Osmosis#Latest_stable_version)
2. Download from the GitHub releases page
3. Install and note the installation directory

**Option B: Package Manager (Recommended)**
```bash
# macOS with Homebrew
brew install osmosis

# Ubuntu/Debian
sudo apt-get install osmosis
```

**Installation Path Examples:**
- Homebrew: `/usr/local/Cellar/osmosis/<VERSION>/bin/osmosis`
- Manual install: `<install_dir>/bin/osmosis`

### Installing the Map-Writer Plugin

**Create Plugin Directory:**
Create a `plugins` folder alongside the `bin` and `libexec` directories:
```
/usr/local/Cellar/osmosis/<VERSION>/plugins/
```

**Download the Plugin:**
1. Visit [Maven Central](https://search.maven.org/search?q=a:mapsforge-map-writer)
2. Select the latest version
3. Download the "jar-with-dependencies" file
4. Move the JAR file to your plugins directory

**Troubleshooting:**
If you encounter plugin installation issues, consult the [official installation guide](https://github.com/mapsforge/mapsforge/blob/master/docs/Getting-Started-Map-Writer.md#plugin-installation).


## Step 3: Prepare Your OSM Data

### Supported Data Formats

You can use two OSM data formats for map creation:
- **`.osm`** - XML format, suitable for smaller areas
- **`.osm.pbf`** - Binary format, efficient for larger datasets

### Data Sources

**Download Options:**
- [OpenStreetMap](https://www.openstreetmap.org) - Specific areas in `.osm` format
- [GEOFABRIK](https://download.geofabrik.de/) - Regional extracts in `.osm.pbf` format

### Data Preparation Requirements

**Ready-to-use Data:**
If you downloaded unmodified files from OSM servers, they're ready for conversion. You can rename files if needed, then proceed to Step 4.

**Modified Data:**
If you've manually edited OSM data, additional preparation is required. **Important:** Create a backup copy before proceeding, as you'll need to manually edit XML attributes.

### Step 3.1: Add Missing Attributes to Modified Files

OSM files are standardized XML files containing nodes, ways, and relations with specific attributes. When files are uploaded to OSM servers, they automatically receive required attributes for proper conversion.

**Required Attributes for All Elements:**
- **ID (positive):** `id="20465986"`
- **Visibility:** `visible="true"`
- **Version:** `version="1"`
- **Changeset:** `changeset="475804"`
- **Timestamp:** `timestamp="2021-06-11T12:51:34Z"`
- **Username:** `user="JohnDoe"`
- **User ID:** `uid="1234"`

**Additional Node Attributes:**
- **Latitude:** `lat="50.8125743"`
- **Longitude:** `lon="12.9318745"`

**Editing Process:**

1. **Rename for editing:** Change `myOsmFile.osm` to `myOsmFile.xml` for proper text editor handling
2. **Choose your editor:**
   - **macOS:** [Xcode](https://apps.apple.com/de/app/xcode/id497799835?mt=12) or any text editor
   - **Windows:** [Notepad++](https://notepad-plus-plus.org/downloads/) or similar
   - **Linux:** vim, nano, or gedit

**Example Transformation:**

**Original node:**
```xml
<node id="-104099" action="modify" visible="true" lat="50.84176020006" lon="12.92692686547" />
```

**Step 1 - Remove unnecessary action attribute:**
Find: ` action="modify"` → Replace with: (nothing)
```xml
<node id="-104099" visible="true" lat="50.84176020006" lon="12.92692686547" />
```

**Step 2 - Add missing attributes:**
Replace `visible="true"` with complete attribute set:
```xml
<node id="-104099" timestamp="2021-05-23T07:16:19Z" uid="12345678" user="JohnDoe" visible="true" version="1" changeset="123456789" lat="50.84176020006" lon="12.92692686547" />
```

**Step 3 - Fix negative IDs:**
- Find: `id="-` → Replace with: `id="`
- Find: `ref="-` → Replace with: `ref="`

**Final result:**
```xml
<node id="104099" timestamp="2021-05-23T07:16:19Z" uid="12345678" user="JohnDoe" visible="true" version="1" changeset="123456789" lat="50.84176020006" lon="12.92692686547" />
```

### Step 3.2: Add Missing Boundary Box

OSM files require bounding box information for proper conversion. If your file header looks like this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<osm version="0.6" generator="JOSM">
    <node id="104099" timestamp="2021-05-23T07:16:19Z" uid="12345678" user="JohnDoe" visible="true" version="1" changeset="123456789" lat="50.84176020006" lon="12.92692686547" />
```

You need to add a bounds element before the first node:

**Calculate Boundaries:**
1. Find the minimum and maximum latitude values in your data
2. Find the minimum and maximum longitude values in your data
3. Add a small buffer to prevent clipping

**Example with bounds:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<osm version="0.6" generator="JOSM">
    <bounds minlat="50.8412200" minlon="12.9259400" maxlat="50.8419200" maxlon="12.9280500"/>
    <node id="104099" timestamp="2021-05-23T07:16:19Z" uid="12345678" user="JohnDoe" visible="true" version="1" changeset="123456789" lat="50.84176020006" lon="12.92692686547" />
```

**Boundary Calculation Tips:**
- **Floor minimum values:** 50.8412220 → 50.8412200
- **Ceil maximum values:** 50.8419171 → 50.8419200
- **Alternative:** Use command-line `bbox` parameter (see Step 4)

**Final Step:** Rename `myOsmFile.xml` back to `myOsmFile.osm`


## Step 4: Build and Execute the Conversion Command

### Command Structure

The Osmosis command consists of several components that work together to convert your OSM data into a Mapsforge map file.

### Basic Command Components

**1. Input Reader:**
```bash
osmosis --rx file="myOsmFile.osm"
```
- `--rx` reads XML format (.osm files)
- For .osm.pbf files, use `--rbf` instead

**2. Output Writer:**
```bash
--mapfile-writer file=myMapFile.map
```

**3. Performance Options:**
```bash
type=hd
```
- Uses hard drive for processing (essential for large files)
- Prevents memory overflow with large datasets

**4. Indoor Data Configuration:**
```bash
tag-conf-file=tag-mapping.xml tag-values=true
```
- References your custom tag mapping file
- Enables indoor tag processing

**5. Optional Bounding Box:**
```bash
bbox=minLat,minLon,maxLat,maxLon
```
- Use if not defined in your OSM file
- Values in decimal degrees

### Complete Command Examples

**For .osm files:**
```bash
cd /usr/local/Cellar/osmosis/<VERSION>
bin/osmosis --rx file="myOsmFile.osm" --mapfile-writer file=myMapFile.map type=hd tag-conf-file=tag-mapping.xml tag-values=true
```

**For .osm.pbf files:**
```bash
cd /usr/local/Cellar/osmosis/<VERSION>
bin/osmosis --rbf file="myOsmFile.osm.pbf" --mapfile-writer file=myMapFile.map type=hd tag-conf-file=tag-mapping.xml tag-values=true
```

**With bounding box parameter:**
```bash
bin/osmosis --rx file="myOsmFile.osm" --mapfile-writer file=myMapFile.map type=hd tag-conf-file=tag-mapping.xml tag-values=true bbox=50.8412200,12.9259400,50.8419200,12.9280500
```

### Execution Tips

**Directory Setup:**
1. Navigate to your Osmosis installation directory
2. Place your OSM file and tag-mapping.xml in the same directory
3. Run the command from this location to ensure plugin detection



# Troubleshooting Common Issues

## Java Runtime Issues

**Error:** "The operation couldn't be completed. Unable to locate a Java Runtime."

**Solution:**
Your system is missing a Java Runtime Environment. Install one of the following:

- **Java JRE:** [Download Java 8 or later](https://www.java.com/de/download/manual.jsp)
- **Java JDK:** [Download from Oracle](https://www.oracle.com/de/java/technologies/javase/javase-jdk8-downloads.html) (includes JRE)

**macOS with Homebrew:**
Follow [these installation steps](https://mkyong.com/java/how-to-install-java-on-mac-osx/#homebrew-install-latest-java-on-macos) to install and configure Java.

## Plugin Detection Issues

**Error:** "Task type mapfile-writer doesn't exist."

**Cause:** Osmosis cannot locate the map-writer plugin.

**Solutions:**
1. **Check plugin directory:** Ensure the `plugins` folder is in the correct location relative to your Osmosis installation
2. **Verify working directory:** Navigate to your Osmosis installation directory before running commands
3. **Use relative paths:** Call osmosis using `bin/osmosis` from the installation directory
4. **File placement:** Ensure both the plugin JAR and your files are in the correct directories

## Processing Issues

**Error:** "Cannot begin reading in Add stage, must call complete first."

**Solution:** Remove the `type=hd` parameter from your mapfile-writer command and retry.

## Data Validation Errors

**Error:** "Node X does not have a version attribute as OSM 0.6 are required to have. Is this a 0.5 file?"

**Solution:** Your OSM file has missing attributes. Review and complete Step 3.1 to add all required node, way, and relation attributes.

**Error:** "No valid bounding box found in input data" / "tile based data store not initialized, missing bounding box information in input data"

**Solution:** Your OSM file lacks bounding box information. Either:
- Add a `<bounds>` element to your OSM file (Step 3.2)
- Include the `bbox` parameter in your command line

## Verification Steps

After completing the documentation updates, verify the process works by:

1. **Test with sample data:** Use a small OSM extract to validate the complete workflow
2. **Check all file paths:** Ensure tag-mapping.xml, OSM files, and plugins are correctly located
3. **Validate output:** Confirm the generated .map file can be loaded in your mapping application
4. **Test indoor features:** Verify that indoor elements appear correctly in the rendered map
