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

# Testing

## Unit Tests

### Creating Unit Tests

Unit tests in the mapsforge_flutter project follow standard Dart/Flutter testing conventions. Tests are located in the `test/` directory of each package and use the `test` package.

#### Basic Unit Test Structure

```dart
import 'package:test/test.dart';
import 'package:mapsforge_flutter_core/model.dart';

void main() {
  group('BoundingBox Tests', () {
    test('should intersect with line when line crosses boundary', () {
      // Arrange
      var lineStart = LatLong(47.0, 8.0);
      var lineEnd = LatLong(49.0, 10.0);
      var rectangle = BoundingBox(46.0, 7.0, 48.0, 9.0);
      
      // Act
      bool result = rectangle.intersectsLine(lineStart, lineEnd);
      
      // Assert
      expect(result, isTrue);
    });
    
    test('should not intersect when line is outside boundary', () {
      // Arrange
      var lineStart = LatLong(50.0, 11.0);
      var lineEnd = LatLong(52.0, 13.0);
      var rectangle = BoundingBox(46.0, 7.0, 52.0, 10.0);
      
      // Act
      bool result = rectangle.intersectsLine(lineStart, lineEnd);
      
      // Assert
      expect(result, isFalse);
    });
  });
}
```

#### Running Unit Tests

Run tests for all packages:
```bash
melos run flutter_test
melos run dart_test
```

Run tests for a specific package:
```bash
cd packages/mapsforge_flutter_core
flutter test
```

Run a specific test file:
```bash
flutter test test/boundingbox_test.dart
```

### Test Organization

- **Group related tests** using `group()` to organize test suites
- **Use descriptive test names** that explain what is being tested
- **Follow AAA pattern**: Arrange, Act, Assert
- **Test edge cases** and error conditions
- **Mock dependencies** when testing units in isolation

## Golden Tests

Golden tests (also known as snapshot tests) are used to verify that UI components render correctly by comparing against reference images.

### Creating Golden Tests

#### Basic Golden Test Structure

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Map Widget Golden Tests', () {
    testWidgets('renders basic map correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapWidget(
              // Configure your widget
            ),
          ),
        ),
      );
      
      // Act
      await tester.pumpAndSettle();
      
      // Assert
      await expectLater(
        find.byType(MapWidget),
        matchesGoldenFile('golden_tests/map_widget_basic.png'),
      );
    });
    
    testWidgets('renders map with markers correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapWidget(
              markers: [
                PoiMarker(
                  position: LatLong(47.0, 8.0),
                  displayName: 'Test Marker',
                ),
              ],
            ),
          ),
        ),
      );
      
      // Act
      await tester.pumpAndSettle();
      
      // Assert
      await expectLater(
        find.byType(MapWidget),
        matchesGoldenFile('golden_tests/map_widget_with_markers.png'),
      );
    });
  });
}
```

#### Golden Test Directory Structure

```
test/
├── golden_tests/
│   ├── map_widget_basic.png
│   ├── map_widget_with_markers.png
│   └── overlay_zoom_controls.png
├── widget_test.dart
└── unit_test.dart
```

### Running Golden Tests

#### Generate New Golden Files

When creating new golden tests or when the UI intentionally changes:

```bash
flutter test --update-goldens
```

#### Run Golden Tests

```bash
flutter test test/widget_test.dart
```

### Handling Golden Test Discrepancies

When golden tests fail due to visual differences, follow these steps:

#### 1. Investigate the Failure

```bash
flutter test test/widget_test.dart --reporter=expanded
```

The test output will show which golden files have mismatches.

#### 2. Review the Differences

Golden test failures generate comparison images in the `test/failures/` directory:

```
test/failures/
├── golden_tests_map_widget_basic_masterImage.png    # Expected
├── golden_tests_map_widget_basic_testImage.png      # Actual
└── golden_tests_map_widget_basic_isolatedDiff.png   # Difference
```

#### 3. Analyze the Discrepancy

**Visual Inspection:**
- Open the three generated images
- Compare expected vs actual
- Review the difference image to identify changes

**Common Causes:**
- **Intentional UI changes**: New features, styling updates
- **Platform differences**: Font rendering, pixel density variations
- **Dependency updates**: Flutter SDK, package updates affecting rendering
- **Test environment**: Different OS, graphics drivers
- **Timing issues**: Animations not fully settled

#### 4. Decide on Action

**If changes are intentional:**
```bash
# Update specific golden files
flutter test --update-goldens test/widget_test.dart

# Update all golden files in the project
flutter test --update-goldens
```

**If changes are unintentional:**
- Fix the underlying code issue
- Re-run tests to verify fix
- Do not update golden files

#### 5. Best Practices for Golden Tests

**Consistent Test Environment:**
```dart
testWidgets('golden test', (WidgetTester tester) async {
  // Set consistent screen size
  await tester.binding.setSurfaceSize(const Size(800, 600));
  
  // Disable animations for consistent rendering
  await tester.binding.setSurfaceSize(const Size(800, 600));
  
  // Your test code here
  
  // Clean up
  await tester.binding.setSurfaceSize(null);
});
```

**Platform-Specific Golden Files:**
```dart
await expectLater(
  find.byType(MapWidget),
  matchesGoldenFile('golden_tests/map_widget_${defaultTargetPlatform.name}.png'),
);
```

**Handling Fonts:**
```dart
testWidgets('golden test with custom fonts', (WidgetTester tester) async {
  // Load custom fonts for consistent rendering
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: YourWidget(),
    ),
  );
  
  await tester.pumpAndSettle();
  
  await expectLater(
    find.byType(YourWidget),
    matchesGoldenFile('golden_tests/your_widget.png'),
  );
});
```

### Golden Test Maintenance

#### Regular Review Process

1. **Before releases**: Run all golden tests to ensure UI consistency
2. **After dependency updates**: Check for rendering changes
3. **Platform testing**: Verify golden tests on different platforms
4. **CI/CD integration**: Include golden tests in automated testing pipeline

#### Version Control

- **Commit golden files**: Include `.png` files in version control
- **Review changes**: Carefully review golden file changes in PRs
- **Document updates**: Note reasons for golden file updates in commit messages

#### Troubleshooting Common Issues

**Golden tests pass locally but fail in CI:**
- Ensure consistent Flutter version
- Use same platform for golden generation and CI
- Consider platform-specific golden files

**Flaky golden tests:**
- Add proper `pumpAndSettle()` calls
- Disable animations during testing
- Use consistent screen sizes and pixel ratios

**Large golden file sizes:**
- Optimize test widget size
- Consider testing smaller components
- Use appropriate image compression

