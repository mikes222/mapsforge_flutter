import 'package:flutter/material.dart';
import 'package:mapsforge_example/mapfileanalyze/blockpage.dart';
import 'package:mapsforge_example/mapfileanalyze/labeltextcustom.dart';
import 'package:mapsforge_example/mapfileanalyze/tagcountpage.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/mapfile/subfileparameter.dart';

class SubfileParamsPage extends StatelessWidget {
  final MapFile mapFile;

  final List<SubFileParameter> subFileParameters;

  const SubfileParamsPage(
      {Key? key, required this.mapFile, required this.subFileParameters})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    List<SubFileParameter> newList = [];
    subFileParameters.forEach((element) {
      if (newList.contains(element)) {
      } else {
        newList.add(element);
      }
    });
    print(
        "analyzing ${subFileParameters.length} subfileParameter items, ${newList.length} different items");
    return ListView(
      children: newList
          .map((e) => Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "SubfileParam for ZoomLevel ${subFileParameters.indexOf(e)} and more",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      children: <Widget>[
                        LabeltextCustom(
                            label: "BaseZoomLevel",
                            value: "${e.baseZoomLevel}"),
                        LabeltextCustom(
                            label: ", Zoomlevel",
                            value: " ${e.zoomLevelMin} - ${e.zoomLevelMax}"),
                      ],
                    ),
                    Wrap(
                      children: <Widget>[
                        LabeltextCustom(
                            label: "boundaryTileVertical",
                            value:
                                "${e.boundaryTileTop} - ${e.boundaryTileBottom}"),
                        LabeltextCustom(
                            label: ", boundaryTileHorizontal",
                            value:
                                "${e.boundaryTileLeft} - ${e.boundaryTileRight}"),
                      ],
                    ),
                    Wrap(
                      children: <Widget>[
                        LabeltextCustom(
                            label: "blocksHeight", value: "${e.blocksHeight}"),
                        LabeltextCustom(
                            label: ", blocksWidth", value: "${e.blocksWidth}"),
                        LabeltextCustom(
                            label: "numberOfBlocks",
                            value: "${e.numberOfBlocks}"),
                      ],
                    ),
                    Wrap(
                      children: <Widget>[
                        LabeltextCustom(
                            label: "Index Start - End",
                            value:
                                "${e.indexStartAddress} - ${e.indexEndAddress}"),
                        LabeltextCustom(
                            label: ", startAddress",
                            value: "${e.startAddress}"),
                        LabeltextCustom(
                            label: ", subFileSize", value: "${e.subFileSize}"),
                      ],
                    ),
                    InkWell(
                      child: Row(
                        children: <Widget>[
                          const Text("Blocks"),
                          const Icon(Icons.more_horiz),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) => BlockPage(
                              mapFile: mapFile,
                              subFileParameter: e,
                            ),
                          ),
                        );
                      },
                    ),
                    InkWell(
                      child: Row(
                        children: <Widget>[
                          const Text("Count tags"),
                          const Icon(Icons.more_horiz),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) => TagsCountPage(
                              mapFile: mapFile,
                              subFileParameter: e,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
