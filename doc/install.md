##Installation of mevos

```bash
dart pub global activate melos
```

Bootstrapping:

do this whenever the structure changes, see https://melos.invertase.dev/commands/bootstrap

```bash
melos bootstrap
```

Run dart analyzer in each package:

melos generate

## Run tests

```bash
melos run flutter_test
melos run dart_test
```


## New app/package

cd apps or cd packages

flutter create <package_name> or dart create <package_name>

edit analysis_options.yaml

```yaml
  include: ../../analysis_options.yaml
```

edit pubspec.yaml

in the second line:

```yaml
resolution: workspace
```

in the root:

```bash
melos bootstrap
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
