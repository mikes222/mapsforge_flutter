import 'package:flutter/material.dart';
import 'package:mapsforge_example/mapfileanalyze/blockpage.dart';
import 'package:mapsforge_example/mapfileanalyze/labeltextcustom.dart';
import 'package:mapsforge_example/mapfileanalyze/tileindex_page.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/mapfile/subfileparameter.dart';

class SubfileParamsPage extends StatelessWidget {
  final MapFile mapFile;

  final List<SubFileParameter> subFileParameters;

  final RenderTheme renderTheme;

  const SubfileParamsPage({Key? key, required this.mapFile, required this.subFileParameters, required this.renderTheme}) : super(key: key);

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
    print("analyzing ${subFileParameters.length} subfileParameter items, ${newList.length} different items");
    return ListView(
      children: newList
          .map((subfileParameter) => Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "SubfileParam for ZoomLevel ${subFileParameters.indexOf(subfileParameter)} and more",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      children: <Widget>[
                        LabeltextCustom(label: "BaseZoomLevel", value: "${subfileParameter.baseZoomLevel}"),
                        LabeltextCustom(label: ", Zoomlevel", value: " ${subfileParameter.zoomLevelMin} - ${subfileParameter.zoomLevelMax}"),
                      ],
                    ),
                    Wrap(
                      children: <Widget>[
                        LabeltextCustom(label: "boundaryTileHorizontal", value: "${subfileParameter.boundaryTileLeft} - ${subfileParameter.boundaryTileRight}"),
                        LabeltextCustom(label: ", boundaryTileVertical", value: "${subfileParameter.boundaryTileTop} - ${subfileParameter.boundaryTileBottom}"),
                      ],
                    ),
                    Wrap(
                      children: <Widget>[
                        LabeltextCustom(label: "blocksWidth", value: "${subfileParameter.blocksWidth}"),
                        LabeltextCustom(label: ", blocksHeight", value: "${subfileParameter.blocksHeight}"),
                        LabeltextCustom(label: ", numberOfBlocks", value: "${subfileParameter.numberOfBlocks}"),
                      ],
                    ),
                    Wrap(
                      children: <Widget>[
                        LabeltextCustom(label: "Tile startAddress", value: "0x${subfileParameter.startAddress.toRadixString(16)}"),
                        LabeltextCustom(label: ", subFileSize", value: "0x${subfileParameter.subFileSize.toRadixString(16)}"),
                      ],
                    ),
                    Wrap(
                      children: <Widget>[
                        InkWell(
                          child: Row(
                            children: <Widget>[
                              LabeltextCustom(
                                  label: "Tile index Start - End",
                                  value: "0x${subfileParameter.indexStartAddress.toRadixString(16)} - 0x${subfileParameter.indexEndAddress.toRadixString(16)}"),
                              const Icon(Icons.more_horiz),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) => TileindexPage(
                                  mapFile: mapFile,
                                  subFileParameter: subfileParameter,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    InkWell(
                      child: const Row(
                        children: <Widget>[
                          Text("Blocks"),
                          Icon(Icons.more_horiz),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) => BlockPage(
                              mapFile: mapFile,
                              subFileParameter: subfileParameter,
                            ),
                          ),
                        );
                      },
                    ),
                    // InkWell(
                    //   child: const Row(
                    //     children: <Widget>[
                    //       Text("Pois and ways"),
                    //       Icon(Icons.more_horiz),
                    //     ],
                    //   ),
                    //   onTap: () {
                    //     Navigator.of(context).push(
                    //       MaterialPageRoute(
                    //         builder: (BuildContext context) => PoiWayListPage(
                    //           mapFile: mapFile,
                    //           subFileParameter: e,
                    //           renderTheme: renderTheme,
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
