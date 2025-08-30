#Melos Documentation for Flutter Projects

This guide provides a clear overview of using Melos, a powerful tool for managing multi-package Dart and Flutter projects, also known as monorepos. It outlines two common use cases and best practices to ensure your project remains scalable and maintainable.

## Use Case 1: Splitting a Large Application into Smaller Packages

If you have a large, monolithic Flutter application and want to break it down into smaller, more manageable packages, Melos is the perfect solution. This approach improves code organization, reusability, and development efficiency.

**Project Structure**

Set up a Melos project with the following directory structure:

- apps/: This directory contains your main Flutter application.
- packages/: This directory is for all the smaller, reusable packages that your main application and other packages will use.

**Melos Configuration**

Your melos.yaml file should define the location of your packages. See melos docu for more info:

````yaml
name: my_app_monorepo

packages:
- 'packages/**'
- 'apps/**'
````

**Dependency Management**

Each package, including your main application, must declare its dependencies in its own pubspec.yaml file. This ensures a clear and controlled dependency graph.

For the application in apps/my_app, you would include your packages as regular dependencies:

````yaml
# apps/my_app/pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  my_feature_package: ^1.0.0
  my_data_package: ^1.0.0
````

Note: Melos automatically handles the path dependencies for you, linking local packages within the monorepo. This allows your main application to compile without any issues, as if the packages were standard, separate projects.

## Use Case 2: Splitting a Complex Library into Functional Parts

If you have a single, monolithic library that is becoming too complex or provides more functionality than a single consumer needs, you should split it into a set of smaller, focused packages.

**Design Principles for Packages**

- Meaningful Naming: Give each new package a clear, official name that reflects its specific purpose (e.g., data_access_layer, ui_components).
- Independent Projects: Treat each package as a separate project. This means each package should have its own pubspec.yaml, tests, and documentation.
- Separate Publishing: Each package can be independently published to pub.dev, allowing external projects to consume only the functionality they need.

**Dependency Management in External Projects**
In an external project that uses your new packages, each part of the library is included as a regular dependency in the pubspec.yaml file:

````yaml
# external_project/pubspec.yaml
dependencies:
  my_cool_library_core: ^1.0.0
  my_cool_library_ui: ^1.0.0
````

**Local Testing with Dependency Overrides**

During development, you can easily test your local changes to the packages within an external project without publishing them. The dependency_overrides section in your pubspec.yaml allows you to point to the local path of the package.

````yaml
# external_project/pubspec.yaml
dependencies:
  my_cool_library_core: ^1.0.0
  my_cool_library_ui: ^1.0.0

dependency_overrides:
  my_cool_library_core:
  path: ../../path/to/my_cool_library_monorepo/packages/my_cool_library_core
````

This setup ensures that you are working with your local, un-published changes while testing, which streamlines the development workflow. When you are ready to use the stable, published version, you simply remove the dependency_overrides block.

## Use Case 3: Single package projects

See https://melos.invertase.dev/getting-started

This is for default single package projects but you want some of the features of melos like changelog generation. 