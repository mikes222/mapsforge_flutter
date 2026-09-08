# Publish the project to pub.dev

[ ] Format source

````bash
    flutter format .
````

[ ] Fix issues

````bash
    dart fix --apply
````

[ ] Make sure all pubspec.yaml are in sync

```bash
melos bootstrap
```

[ ] Test the ``simple_example`` in the emulator

[ ] Test the ``simple_example`` in the Webbrowser

[ ] Perform unittests

````bash
    melos run dart_test
    melos run flutter_test
````

[ ] Update documentation

especially ``changes.md``

[ ] Increase version in pubspec.yaml

automatic:

```bash
melos version
```

manual:

```bash
melos version -V mapsforge_flutter:4.1.0 -V mapsforge_flutter_core:4.1.0 -V mapsforge_flutter_mapfile:4.1.0 -V mapsforge_flutter_renderer:4.1.0 -V mapsforge_flutter_rendertheme:4.1.0
```

[ ] Analyze package quality with pana (https://pub.dev/packages/pana)

````bash
    dart pub global activate pana
    C:\Users\micro\AppData\Local\Pub\Cache\bin\pana packages/mapsforge_flutter_core
    C:\Users\micro\AppData\Local\Pub\Cache\bin\pana packages/mapsforge_flutter_mapfile
    C:\Users\micro\AppData\Local\Pub\Cache\bin\pana packages/mapsforge_flutter_rendertheme
    C:\Users\micro\AppData\Local\Pub\Cache\bin\pana packages/mapsforge_flutter_renderer
    C:\Users\micro\AppData\Local\Pub\Cache\bin\pana packages/mapsforge_flutter
    ...
````

Note: git must be installed and accessible via path

[ ] publish dry run

````bash
    dart pub publish --directory=packages/mapsforge_flutter_core --dry-run
````

[ ] Checkin into git

[ ] Create a tag for the new version

[ ] flutter publish

````bash
    dart pub publish --directory=packages/mapsforge_flutter_core
````
