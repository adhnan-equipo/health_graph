# CLAUDE.md - Health Graph Flutter Package

## Commands
```bash
# Build and run
flutter run
flutter build apk
flutter build ios

# Code quality
flutter format lib/
flutter analyze
flutter test
flutter test test/specific_test_file.dart

# Package commands
flutter pub get
flutter pub upgrade
```

## Style Guidelines
- **Imports**: Group related imports, use relative paths for library imports
- **Naming**: `CamelCase` for classes/enums, `lowerCamelCase` for methods/variables
- **Types**: Strong typing everywhere, mark nullable types with `?`
- **Parameters**: Use named parameters with required annotation where needed
- **Structure**: Follow MVC-like pattern with controllers, models, and widgets
- **Organization**: Group related functionality in dedicated directories
- **Error handling**: Use assertions for constructor validation, leverage null safety
- **Documentation**: Add doc comments to public APIs

## Module Structure
Each health metric (BP, BMI, etc.) follows consistent organization with controllers, models, services, styles, and widgets in dedicated folders.