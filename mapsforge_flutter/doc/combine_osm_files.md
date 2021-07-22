#  Combining .osm files

If you have an indoor map there is an easy way to include the surrounding outdoor data in your osm file.

The outdoor data can be exported directly from [open street map](https://www.openstreetmap.org/) by using the Eport function in the top right corner. As proposed [here](https://gis.stackexchange.com/questions/242704/merging-osm-pbf-files) you can then use the [merge function](https://wiki.openstreetmap.org/wiki/Osmosis/Detailed_Usage_0.48#--merge_.28--m.29) of Osmosis to combine the osm files. If your files are located in the current command directory, this command should do the trick:
```
osmosis --rx file1.osm --rx file2.osm --merge --wx mergedFile.osm
```
If your original osm files had different boundary values, the merged file will not have the bounds property and you have to add it manually.

Be aware that merging files like this can possibly cause other problems, e.g. if some nodes have the same id value and are referenced multiple times.
