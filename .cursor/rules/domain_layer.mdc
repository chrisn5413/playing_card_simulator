# Domain Layer Guidelines

## Directory Structure

```
lib/
  └── feature_name/
      └── domain/
          ├── i_feature_service.dart
          └── feature_model.dart
```

## Domain Layer Conventions

### Model Structure

1. Models must:
   - Be immutable
   - Use freezed annotation
   - Have an empty constructor with default values

2. Model Properties:
   - Use proper types (no dynamic)
   - Include proper documentation

### Interface Structure

1. Interfaces must:
   - Define clear contract for implementations
   - Be prefixed with 'I'
   - Include method documentation
   - Define error cases and types
   - Return Result<T, E> for operations that can fail (using result_type: ^0.0.1 package)

2. Interface Methods:
   - Should be future-based for async operations
   - Have clear parameter names
   - Use Result<T, E> as return type
   - Document possible error types in E

## Naming Conventions

### Files

1. Model files:
   - Use `_model.dart` suffix
   - Use snake_case
   - Be descriptive of the model content

2. Interface files:
   - Use `i_` prefix
   - Use `_service.dart` suffix for services
   - Use snake_case

### Classes

1. Model classes:
   - Use PascalCase
   - End with 'Model'
   - Match their file names

2. Interface classes:
   - Use PascalCase
   - Start with 'I'
   - End with 'Service' for services

## Code Organization

1. Models:
   - One model per file
   - Group related models in same directory

2. Interfaces:
   - One interface per file
   - Define clear method contracts
   - Include error types
   - Document all methods

## Best Practices

1. Domain Models:
   - Keep models focused and specific
   - Use proper value types
   - Include validation logic
   - Use empty constructor with defaults

2. Interfaces:
   - Define clear method contracts
   - Use Result type for error handling
   - Keep methods focused
   - Document error types

## Testing Guidelines

1. Directory Structure:
   ```
   test/
     └── feature_name/
         └── domain/
             ├── feature_model_test.dart
             └── feature_service_test.dart
   ```

2. Model Testing:
   - Test empty constructor defaults
   - Test copyWith methods
   - Test equality comparisons
   - Test validation logic

3. Testing Conventions:
   - Group tests logically
   - Test success cases (Result.success)
   - Test failure cases (Result.failure)
   - Use meaningful test names

## Code Example

```dart

@freezed
class FeatureModel with _$FeatureModel {
  const factory FeatureModel({
    @Default('') String id,
    @Default('') String name,
    @Default(false) bool isActive,
  }) = _FeatureModel;
}
import 'package:result_type/result_type.dart';

abstract class IFeatureService {
  /// Fetches feature by ID.
  /// 
  /// Returns [Result.failure] with [FeatureError.notFound] if feature doesn't exist.
  Future<Result<FeatureModel, FeatureError>> getFeature(String id);

  /// Creates a new feature.
  /// 
  /// Returns [Result.failure] with [FeatureError.validation] if validation fails.
  Future<Result<FeatureModel, FeatureError>> createFeature(FeatureModel feature);
} 