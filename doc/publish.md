# Publish the project to pub.dev


[ ] Test the ``simple_example`` in the emulator

[ ] Test the ``simple_example`` in the Webbrowser

[ ] Perform unittests

````bash
    melos run dart_test
    melos run flutter_test
````

[ ] Update documentation

[ ] Format source

````bash
    flutter format .
````

[ ] Increase version in pubspec.yaml

[ ] Analyze package quality with pana (https://pub.dev/packages/pana)

````bash
    dart pub global activate pana
    C:\Users\micro\AppData\Local\Pub\Cache\bin\pana
````

Note: git must be installed and accessible via path

[ ] flutter publish dry run

````bash
    dart pub publish --dry-run
````

[ ] Checkin into git

[ ] Create a tag for the new version

[ ] flutter publish

````bash
    dart pub publish
````
