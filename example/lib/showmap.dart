import 'package:example/constants.dart';
import 'package:example/mapfileanalyze/mapheaderpage.dart';
import 'package:example/mapmodelhelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';


class Showmap extends StatelessWidget {

  MapModel mapModel;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: MapModelHelper.prepareMapModel(),
      builder: (context, snapshot) {
        // show loading if future not fullfilled
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        // keep reference to mapModel
        this.mapModel = snapshot.data;

        return Scaffold(
          appBar: _buildHead(context),
          body: _buildBody(context, this.mapModel),
        );
      }
    );
  }

  Widget _buildHead(BuildContext context) {
    return AppBar(
      title: const Text('Mapsforge Indoor App'),
      actions: <Widget>[
        PopupMenuButton<String>(
          offset: Offset(0,100),
          onSelected: (choice) => handleMenuItemSelect(choice, context),
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: "start_location",
              child: Text("Back to Start"),
            ),
            PopupMenuItem<String>(
              value: "analyse_mapfile",
              child: Text("Analyse Mapfile"),
            ),
            PopupMenuItem<String>(
              enabled: false,
              value: "current_zoom_level",
              child:  Text("Zoom level: ${this.mapModel.mapViewPosition.zoomLevel}")
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, MapModel mapModel) {
    return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          FlutterMapView(
              mapModel: mapModel
          ),
          Positioned(
              bottom: 15.0,
              right: 15.0,
              top: 15.0,
              child:  Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Wrap(
                      direction: Axis.vertical,
                      spacing: 15,
                      children: <Widget>[
                        RawMaterialButton(
                          onPressed: () {
                            mapModel.indoorLevelUp();
                          },
                          elevation: 2.0,
                          fillColor: Colors.white,
                          child: Icon(
                              Icons.arrow_drop_up
                          ),
                          padding: EdgeInsets.all(10.0),
                          shape: CircleBorder(),
                          constraints: BoxConstraints(),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        RawMaterialButton(
                          elevation: 2.0,
                          fillColor: Colors.white,
                          child: StreamBuilder(
                            stream: mapModel.observePosition,
                            builder: (BuildContext context, AsyncSnapshot<MapViewPosition> snapshot) {
                              String output = snapshot.hasData ? snapshot.data.indoorLevel.toString() : "0";
                              return Text(
                                output,
                                style: TextStyle(fontSize: 20),
                              );
                            },
                          ),
                          padding: EdgeInsets.all(15.0),
                          shape: CircleBorder(),
                          constraints: BoxConstraints(),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        RawMaterialButton(
                          onPressed: () {
                            mapModel.indoorLevelDown();
                          },
                          elevation: 2.0,
                          fillColor: Colors.white,
                          child: Icon(
                              Icons.arrow_drop_down
                          ),
                          padding: EdgeInsets.all(10.0),
                          shape: CircleBorder(),
                          constraints: BoxConstraints(),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ]
                  ),
                  Wrap(
                      direction: Axis.vertical,
                      spacing: 15,
                      children: <Widget>[
                        RawMaterialButton(
                          onPressed: () {
                            mapModel.zoomIn();
                          },
                          elevation: 2.0,
                          fillColor: Colors.white,
                          child: Icon(
                              Icons.add
                          ),
                          padding: EdgeInsets.all(10.0),
                          shape: CircleBorder(),
                          constraints: BoxConstraints(),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        RawMaterialButton(
                          onPressed: () {
                            mapModel.zoomOut();
                          },
                          elevation: 2.0,
                          fillColor: Colors.white,
                          child: Icon(
                              Icons.remove
                          ),
                          padding: EdgeInsets.all(10.0),
                          shape: CircleBorder(),
                          constraints: BoxConstraints(),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ]
                  )
                ]
              )
          )
        ]
    );
  }

  void handleMenuItemSelect (String value, BuildContext context) {
    switch (value) {
      case 'start_location':
        this.mapModel.setMapViewPosition(Constants.MAP_POSITION_LAT, Constants.MAP_POSITION_LON);
        this.mapModel.setZoomLevel(Constants.MAP_ZOOM_LEVEL);
        break;

      case 'analyse_mapfile':
        Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => MapHeaderPage()));
        break;
    }
  }
}