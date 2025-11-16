# Version 4.0.1

- Rotation works now with 3 fingers (configurable) to distinguish from zooming which works with 2 fingers
- Support for dy parameter in renderthemes

# To Version 4.0.0

Major rework.

Changes at a glance:

- No DisplayModel anymore
- MapModel and ViewModel are merged to MapModel
- No need to explicitely instantiate caches
- Some global configurations are now in MapsforgeSettingsMgr()
- Tiles are NOT cached to disk anymore (at least for now)
- Overlay handling is much simpler since everything is now a widget (flutter-style :-) ). Just create a Stack and add the widgets you want.
- Marker handling is also simpler. Add a MarkerDatastoreOverlay and add your markers as needed.
- ContextMenus are simpler to use and more configurable.

## Listen to tap, double-tap, long-tap events

Instead of 

```dart
viewModel.observeTap
```

use now

```dart
mapModel.tapStream
```

## Positioning

Old:
viewModel.setmapviewposition uses defaults if there is no position set. 

New:
mapModel assumes that a position is already set. Use mapModel.setPosition for setting an initial position. 


Old:

```dart
viewmodel.setmapviewposition
```

New:

```dart
mapModel.moveTo(lat, lon)
mapModel.setCenter(x, y)
```
