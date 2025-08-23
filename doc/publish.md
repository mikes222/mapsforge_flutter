# Publish the project to pub.dev


[ ] Test the example in the emulator
[ ] Test the example in the Webbrowser
[ ] Perform unittests

    melos run dart_test
    melos run flutter_test

[ ] Update documentation
[ ] Format source

    flutter format .

[ ] Increase version in pubspec.yaml
[ ] Analyze package quality with pana (https://pub.dev/packages/pana)

    dart pub global activate pana
    C:\Users\micro\AppData\Local\Pub\Cache\bin\pana

(git must be installed and accessible via path)

[ ] flutter publish dry run

    dart pub publish --dry-run

[ ] Checkin into git
[ ] Create a tag for the new version
[ ] flutter publish

    dart pub publish

Watch the thousands of users downloading the project :-)
