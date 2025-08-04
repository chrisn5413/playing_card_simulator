# Infrastructure Layer Guidelines

## Directory Structure

```
lib/
  └── feature_name/
      └── infrastructure/
          ├── dtos/
          │   └── feature_dto.dart
          ├── constants/
          │   └── feature_api_keys.dart
          └── feature_service.dart
```

## Infrastructure Layer Conventions

### DTO Structure

1. DTOs must:
   - Be immutable
   - Use freezed annotation
   - Have an empty constructor with default values
   - Include fromJson/toJson methods
   - Have toDomain() method to convert to domain model

2. DTO Properties:
   - Match API response structure
   - Use proper types (no dynamic)
   - Include proper documentation
   - Handle null values appropriately

### API Keys Structure

1. API Keys must:
   - Be in a separate constants file
   - Use static const strings
   - Follow proper naming convention
   - Include proper documentation

2. API Keys file should:
   - Be named `feature_api_keys.dart`
   - Group related keys together
   - Include endpoint paths
   - Document key usage

### Service Implementation Structure

1. Services must:
   - Implement domain interface
   - Handle all error cases
   - Convert DTOs to domain models
   - Use Result type for error handling
   - Include proper error mapping
   - Use API keys from constants

2. Service Methods:
   - Handle network errors
   - Map API errors to domain errors
   - Convert DTOs to domain models
   - Return Result<T, E> types

## Naming Conventions

### Files

1. DTO files:
   - Use `_dto.dart` suffix
   - Use snake_case
   - Match API resource names

2. Service files:
   - Remove 'i_' prefix from interface name
   - Use `_service.dart` suffix
   - Use snake_case

3. API Keys files:
   - Use `_api_keys.dart` suffix
   - Use feature name prefix
   - Use snake_case

### Classes

1. DTO classes:
   - Use PascalCase
   - End with 'Dto'
   - Match their file names

2. Service classes:
   - Use PascalCase
   - Remove 'I' prefix from interface name
   - End with 'Service'

## Code Organization

1. DTOs:
   - One DTO per file
   - Group in dtos folder
   - Include JSON serialization
   - Include domain conversion

2. Services:
   - One service per file
   - Handle all error cases
   - Include proper logging
   - Document error handling

3. API Keys:
   - Group by feature
   - Include endpoints
   - Document usage
   - Keep in constants folder

## Best Practices

1. DTOs:
   - Match API structure exactly
   - Handle null values safely
   - Include proper JSON serialization
   - Provide domain model conversion

2. Services:
   - Handle all network errors
   - Map to domain errors
   - Use Result type consistently
   - Log important events
   - Use API keys from constants

## Code Example

```dart
import 'package:result_type/result_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import './constants/feature_api_keys.dart';

// API Keys
abstract class FeatureApiKeys {
  static const baseUrl = 'https://api.example.com';
  static const featureEndpoint = '/features';
  static const apiKey = 'your_api_key';
  
  // Endpoints
  static String getFeatureById(String id) => '$featureEndpoint/$id';
  static String createFeature() => featureEndpoint;
}

@freezed
class FeatureDto with _$FeatureDto {
  const factory FeatureDto({
    @Default('') String id,
    @Default('') String name,
    @Default(false) @JsonKey(name: 'is_active') bool isActive,
  }) = _FeatureDto;

  factory FeatureDto.fromJson(Map<String, dynamic> json) => 
      _$FeatureDtoFromJson(json);

  FeatureModel toDomain() => FeatureModel(
    id: id,
    name: name,
    isActive: isActive,
  );
}

class FeatureService implements IFeatureService {
  final ApiClient _apiClient;

  FeatureService(this._apiClient);

  @override
  Future<Result<FeatureModel, FeatureError>> getFeature(String id) async {
    try {
      final response = await _apiClient.get(
        FeatureApiKeys.getFeatureById(id),
        headers: {'Authorization': 'Bearer ${FeatureApiKeys.apiKey}'},
      );
      final dto = FeatureDto.fromJson(response.data);
      return Success(dto.toDomain());
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return Failure(FeatureError.notFound);
      }
      return Failure(FeatureError.unknown);
    }
  }

  @override
  Future<Result<FeatureModel, FeatureError>> createFeature(FeatureModel feature) async {
    try {
      final response = await _apiClient.post(
        FeatureApiKeys.createFeature(),
        headers: {'Authorization': 'Bearer ${FeatureApiKeys.apiKey}'},
        data: feature.toJson(),
      );
      final dto = FeatureDto.fromJson(response.data);
      return Success(dto.toDomain());
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        return Failure(FeatureError.validation);
      }
      return Failure(FeatureError.unknown);
    }
  }
} 