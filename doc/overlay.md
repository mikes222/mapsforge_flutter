# Overlays

# Abstract

Overlays are just Widgets which are drawn on top of the map. 
The behavior, location and size of the widget is up to the widget creator. 

To add an overlay to a map call the viewmodel and add an overlay like so:

    viewModel.addOverlay(ZoomOverlay(viewModel));

## DistanceOverlay

This overlay displays a small meter bar in the bottom left corner of the map. 
The bar vanishes automatically after 10 Seconds. If the map is updated inbetween 30 seconds
the meter bar is NOT shown again. 

## IndoorlevelZoomOverlay

This widget provides buttons for indoorlevels and for zoom. 
The position of the widget is in the right-lower corner of the map.
You should not use ZoomOverlay and IndoorlevelZoomOverlay concurrently.

## ZoomOverlay

This widget provides buttons for zooming-in and out.
The position of the widget is in the right-lower corner of the map.
You should not use ZoomOverlay and IndoorlevelZoomOverlay concurrently.

# RotationOverlay

This widget provides manual rotation of the map with 3 finger-touches. 
It is transparent to the user. 