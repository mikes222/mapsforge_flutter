# Including mapsforge_flutter in your application

Include the needed mapsforge packages into your pubspec.yaml

```yaml
dependencies:
  # UI code
  mapsforge_flutter: ^1.0.0

  # core code, always needed
  mapsforge_flutter_core: ^1.0.0

  # When working with local mapfiles
  mapsforge_flutter_mapfile: ^1.0.0

  # Online and offline renderers
  mapsforge_flutter_renderer: ^1.0.0

  # When working with local mapfiles
  mapsforge_flutter_rendertheme: ^1.0.0
```

When working with a local copy of mapsforge_flutter (see below), override the packages:

```yaml
dependency_overrides:

  mapsforge_flutter:
    #    git:
    #      url: https://github.com/mikes222/mapsforge_flutter_renderer/tree/refactoring_2025/packages/dart_common
    #      branch: refactoring_2025
    path: ../../mapsforge_flutter_refactoring_2025/packages/mapsforge_flutter

  mapsforge_flutter_core:
    path: ../../mapsforge_flutter_refactoring_2025/packages/mapsforge_flutter_core

  mapsforge_flutter_mapfile:
    path: ../../mapsforge_flutter_refactoring_2025/packages/mapsforge_flutter_mapfile

  mapsforge_flutter_renderer:
    path: ../../mapsforge_flutter_refactoring_2025/packages/mapsforge_flutter_renderer

  mapsforge_flutter_rendertheme:
    path: ../../mapsforge_flutter_refactoring_2025/packages/mapsforge_flutter_rendertheme
```

🚧Do not forget to remove the dependency_overrides when switching back to pub.dev


# Maintaining a local copy of mapsforge_flutter

## Installation of mevos

```bash
dart pub global activate melos
```

### Bootstrapping:

do this whenever the structure changes, see https://melos.invertase.dev/commands/bootstrap

```bash
melos bootstrap
```

### Run tests

```bash
melos run flutter_test
melos run dart_test
```

## Adding a new app/package

``cd apps`` or ``cd packages``

``flutter create <package_name>`` or ``dart create <package_name>``

replace ``analysis_options.yaml`` with

```yaml
  include: ../../analysis_options.yaml
```

edit the new ``pubspec.yaml`` and insert into the second line:

```yaml
resolution: workspace
```

in pubspec.yaml of the root directory:

```yaml
workspace:
  - apps/<package_name>
```

Afterwards:

```bash
melos bootstrap
```

# Test your mapfile with complete_example

Complete example provides useful tools such as 

- Debug-info to see the contents of a mapfile for a certain location
- Debug-info to examine the structure of a mapfile
- Performance profiles to see potential memory- and timing issues

Step 1: Download the project from git

Step 2: Activate melos and perform ``melos bootstrap``. See section above.

Step 3: Start complete_example in your emulator or at your device to see if everything works

Step 4: To use a custom rendertheme perform the following steps:

- Copy the rendertheme to complete_example/assets/render_theme
- add the rendertheme to pubspec.yaml
- open complete_example/lib/models/app_models.dart and add the new rendertheme to ``RenderTheme``
- Start the application again and choose the new rendertheme in the configuration section.

Step 5: To use a custom mapfile perform the following steps:

- open complete_example/lib/models/app_models.dart and add a new ``MapLocation`` to ``MapLocations``
- Start the application again and choose the new mapfile in the configuration section.

