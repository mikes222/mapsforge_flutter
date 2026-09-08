## 4.1.0

 - **PERF**: Marker generation improved, tile generation improved, parallel multimap handling. ([6b9b954d](https://github.com/mikes222/mapsforge_flutter/commit/6b9b954d5d31ad11dbdf06470fa4dc1bcab55665))
 - **PERF**: Increase performance for hillshading. ([23e622ee](https://github.com/mikes222/mapsforge_flutter/commit/23e622eeed27e28088d378bbe59ec5ee573f0a21))
 - **PERF**: ecache updated, simplified boundary check for ways,cache for rendertheme. ([12e58133](https://github.com/mikes222/mapsforge_flutter/commit/12e5813367aa5d9d586986a586c1374e41dcf1b6))
 - **PERF**: spill data to filesystem to reduce memory footprint. ([d07ccda3](https://github.com/mikes222/mapsforge_flutter/commit/d07ccda3aed3a9144971196666ccad5734d7b6e3))
 - **FIX**: dart fix. ([fd1405a1](https://github.com/mikes222/mapsforge_flutter/commit/fd1405a1abb013555ccbd9a174f48123832e679f))
 - **FIX**: Correct response when closing the contextMenu. ([b654453b](https://github.com/mikes222/mapsforge_flutter/commit/b654453b78d61218cba91a211c3415993bdf6f8a))
 - **FIX**: make sure to respect visible areas. ([af87d70a](https://github.com/mikes222/mapsforge_flutter/commit/af87d70afcc31ae1df144dd3a1ce1e180cc8638f))
 - **FIX**: Dealing with move/double-tap events in rapid succession. ([9c52e714](https://github.com/mikes222/mapsforge_flutter/commit/9c52e71492418884e590c0c4834c4317cc3dd6ca))
 - **FIX**: Bug when moving in zoomlevel 0 fixed, distance overlay showed wrong distance when using deviceScaleFactor != 1. ([e5ec408e](https://github.com/mikes222/mapsforge_flutter/commit/e5ec408ea8a7b4889590f426db60ab4666aabf46))
 - **FIX**: Fixed a few suggested issues. ([ed426644](https://github.com/mikes222/mapsforge_flutter/commit/ed426644ee84c0fef1591e6856f266e9bb78ef5b))
 - **FIX**: lagging of labels. ([0ef0cefa](https://github.com/mikes222/mapsforge_flutter/commit/0ef0cefa5ef4d01781923d114aa8dafb2651fb20))
 - **FIX**: exception when using double-click for zoom-in. ([30c5bbc8](https://github.com/mikes222/mapsforge_flutter/commit/30c5bbc8dac94bb3eba7c3bbd2077fed711d7204))
 - **FIX**: solving lagging tiles while moving map. ([5644af24](https://github.com/mikes222/mapsforge_flutter/commit/5644af24f722acc162bf4e75655791550608e050))
 - **FIX**: labelJobQueue and tileJobQueue refactored to improve performance. ([b6134af1](https://github.com/mikes222/mapsforge_flutter/commit/b6134af1d152240694fd5a1967f8a28a8112ef12))
 - **FIX**: Debug rendertheme in contextMenu, support for dy, preparation for unzip service without memory problems. ([589eba68](https://github.com/mikes222/mapsforge_flutter/commit/589eba68abbb9172c6ad8e2d5f157121b77820f7))
 - **FEAT**: support text-transform in rendertheme xml. ([e4b4a4e0](https://github.com/mikes222/mapsforge_flutter/commit/e4b4a4e0ef79aff984f4e28adfd982fc29a9510f))
 - **FEAT**: multiple renderers. ([748a3499](https://github.com/mikes222/mapsforge_flutter/commit/748a3499c2aebd41d3acc7285c5f4291a735aa80))
 - **FEAT**: StyleMenus. ([aa66e40d](https://github.com/mikes222/mapsforge_flutter/commit/aa66e40d06110c7ae0b453263bdd9a9364203b13))
 - **FEAT**: Working with stylemenus (not fully implemented yet). ([9d44de69](https://github.com/mikes222/mapsforge_flutter/commit/9d44de698d309597dcfb9310da9dfae8822b1731))
 - **FEAT**: introducing MapModel.moveRotateTo(). ([62a80353](https://github.com/mikes222/mapsforge_flutter/commit/62a80353fd0116d498fdbf220e3eea03e09293bc))
 - **FEAT**: prevent overriding zoomlevel in mapfile. ([244f0a10](https://github.com/mikes222/mapsforge_flutter/commit/244f0a1081b4aa9d500cea801f0c4a63cfd6843a))
 - **FEAT**: RotationHandler supports 2 or 3 finger rotation to distinguish it from zoomHandler which supports only 2 finger zooming. ([ee71c36d](https://github.com/mikes222/mapsforge_flutter/commit/ee71c36d6cf11425f9ddafe8f5241765cbec9254))
 - **DOCS**: Documentation updated. ([5cf9fbd8](https://github.com/mikes222/mapsforge_flutter/commit/5cf9fbd844e8fae52e913cdacfc971e054c4ee08))

## 4.0.0 - 2025-09-20

 - Refactored code

## 3.0.2 - 2025-06-11

* Introducing mapfile-converter
* manual map rotation

## 3.0.1 - 2025-02-14

* Support for mapfiles running in isolates
* Multiple concurrent generations of tiles

## 3.0.0 - 2024-01-20

* Improved performance
* Moved code to root according to flutter standards
* Bugfixes
* Multiple captions for markers

## 2.0.3 - 2023-11-18

* Add Alignment property to BasicPointMarker + use Alignment when painting PoiMarker. Default is Alignment.bottomCenter.
* Many bugfixes
* Improved performance
* Rotational maps

## 2.0.2 - 2022-10-26

* Improved speed
* Improved image quality
* drag'n'drop support

## 2.0.1 - 2021-12-01

* Fling/Swipe-Support
* Support for Satellite-Views
* Major speed-improvements
* Numerous Bugfixes

## 2.0.0 - 2021-06-15

* Implementation for Flutter nullSafety
* Major improvements and bugfixes

## 1.1.0 - 2021-01-20

* Major speed improvements
* API slightly changed to increase speed

## 1.0.0 - 2020-08-14

* initial release.
