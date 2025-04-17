# FluentExtensions

[![Documentation](https://github.com/Appsaurus/FluentExtensions/actions/workflows/generate-docc-site.yml/badge.svg)](https://appsaurus.github.io/FluentExtensions/)
[![Swift](https://img.shields.io/badge/Swift-5.7-orange.svg)](https://swift.org)
[![Vapor](https://img.shields.io/badge/Vapor-4.0-blue.svg)](https://vapor.codes)

## Key Features

FluentExtensions enhances Vapor's Fluent ORM with:

- **Powerful Controller System**: Pre-built controllers with full CRUD operations, relationship management, and advanced filtering
- **Smart Query Filtering**: JSON-based and simplified query syntax for complex data filtering
- **Relationship Management**: Easy-to-use endpoints for handling parent-child and sibling relationships
- **Reflection-Based Migrations**: Dramatically reduce boilerplate with automatic schema generation
- **Advanced Query Building**: Enhanced query capabilities with sorting, pagination, and nested relationship queries

[**View Full Documentation**](https://appsaurus.github.io/FluentExtensions/)

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/Appsaurus/FluentExtensions.git", from: "1.0.0")
]
```

## Controller System

### FluentAdminController

The most feature-rich controller, providing full CRUD, relationship management, and search capabilities. Typically meant for admin panel type apps that may deal directly with the lower-level Model types:

```swift
final class UserController: FluentAdminController<User> {
    public override init(config: Config = Config()) {
        super.init(config: config)
        // Configure nested filters for relationships
        parameterFilterConfig.nestedBuilders = [
            "posts": QueryParameterFilter.Child(\Post.$author),
            "comments": QueryParameterFilter.Child(\Comment.$author)
        ]
    }
}

// Usage in configure.swift
app.group("api") { api in
    let controller = UserController()
    try api.register(controller)
}
```

This provides:
- CRUD endpoints (/users)
- Relationship management (/users/:id/children/posts)
- Search & filtering
- Pagination
- Nested filtering

### Controller Hierarchy

1. `Controller`: Base abstract controller with authorization and routing
2. `FluentController`: Adds Fluent-specific operations
3. `FluentAdminController`: Adds relationship management and advanced filtering

## Query Parameter Filtering

### JSON-Based Filter API

Complex filtering using JSON structure:

```swift
// GET /users?filter={"field":"age","method":"gt","value":21}

// Nested relationship filtering
// GET /users?filter={"field":"posts","method":"filter","value":"{\"field\":\"title\",\"method\":\"contains\",\"value\":\"vapor\"}"}

// Multiple conditions
// GET /users?filter={"and":[
//   {"field":"age","method":"gt","value":21},
//   {"field":"name","method":"contains","value":"john"}
// ]}
```

Available methods:
```swift
// Comparison
"eq", "neq", "gt", "gte", "lt", "lte"

// String operations
"contains", "startsWith", "endsWith"

// Array operations
"in", "notIn"

// Range operations
"between", "betweenInclusive"

// Null checks
"isNull", "isNotNull"
```

### Simple Filter API

Alternative simplified filtering syntax:

```swift
// Simple equality
GET /users?name=eq:John

// Numeric comparisons
GET /users?age=gt:21

// String operations
GET /users?email=contains:@gmail.com

// Array operations
GET /users?id=in:1,2,3

// Range queries
GET /users?age=bti:[18,65]  // Between inclusive
GET /users?createdAt=bt:[2023-01-01,2024-01-01]
```

### Sorting

```swift
// Single field sorting
GET /users?sort=name:asc

// Multiple field sorting
GET /users?sort=name:asc,age:desc

// Nested field sorting
GET /users?sort=profile_email:asc
```

## Relationship Management

FluentAdminController provides endpoints for managing relationships:

```swift
// Get related entities
GET /users/:id/children/posts

// Replace relationships
PUT /users/:id/children/posts

// Attach relationships
PUT /users/:id/children/posts/attach

// Detach relationships
PUT /users/:id/children/posts/detach

// Similar endpoints for siblings
GET /users/:id/siblings/roles
PUT /users/:id/siblings/roles
PUT /users/:id/siblings/roles/attach
PUT /users/:id/siblings/roles/detach
```

## Examples

### Controller Setup with Nested Filtering

```swift
final class ParentController: FluentAdminController<Parent> {
    init() {
        super.init()
        parameterFilterConfig.nestedBuilders = [
            "children": QueryParameterFilter.Child(\Child.$parent),
            "optionalChildren": QueryParameterFilter.Child(\Child.$optionalParent)
        ]
    }
}

final class ChildController: FluentAdminController<Child> {
    init() {
        super.init()
        parameterFilterConfig.nestedBuilders = [
            "parent": QueryParameterFilter.Parent(\Child.$parent),
            "optionalParent": QueryParameterFilter.Parent(\Child.$optionalParent)
        ]
    }
}
```

### Complex Query Example

```swift
// Find users over 21 with active posts
GET /users?filter={
    "and": [
        {"field": "age", "method": "gt", "value": 21},
        {
            "field": "posts",
            "method": "filter",
            "value": "{\"field\":\"status\",\"method\":\"eq\",\"value\":\"active\"}"
        }
    ]
}
```

## Reflection-Based Migrations

FluentExtensions provides powerful reflection-based migrations that dramatically reduce boilerplate code. Here's a comparison using a complex model:

### Traditional Migration Approach

```swift
final class KitchenSinkMigration: AsyncMigration {
    
    public func prepare(on database: any FluentKit.Database) async throws {
        try await database.schema(KitchenSink.schema)
            .field(.id, .int, .identifier(auto: true))

            //MARK: Basic Data Type Fields Schema
            .field(.stringField, .string, .required)
            .field(.optionalStringField, .string)
            .field(.intField, .int, .required)
            .field(.doubleField, .double, .required)
            .field(.booleanField, .bool, .required)
            .field(.dateField, .datetime, .required)
            .field(.optionalDateField, .datetime)

            //MARK: Collection Fields Schema
            .field(.stringArrayField, .array(of: .string), .required)
            .field(.intArrayField, .array(of: .int), .required)
            .field(.doubleArrayField, .array(of: .double), .required)
            .field(.booleanArrayField, .array(of: .bool), .required)
            .field(.dateArrayField, .array(of: .datetime), .required)

            //MARK: Timestamp Updated Fields Schema
            .field(.createdAt, .datetime, .required)
            .field(.updatedAt, .datetime)
            .field(.deletedAt, .datetime)

            //MARK: Grouped Fields Schema
            .field(.group(.groupedFields, .stringField), .string, .required)
            .field(.group(.groupedFields, .optionalStringField), .string)
            .field(.group(.groupedFields, .intField), .int, .required)

            //MARK: Enum Fields Schema
            .field(.stringEnum, .enum(TestStringEnum.self), .required)
            .field(.optionalStringEnum, .enum(TestStringEnum.self))
            .field(.rawStringEnum, .string, .required)
            .field(.optionalRawStringEnum, .string)
            .field(.rawIntEnum, .int, .required)
            .field(.optionalRawIntEnum, .int)

            //MARK: Enum Array Fields Schema
            .field(.stringEnumArray, .array(of: .string), .required)
            .field(.rawStringEnumArray, .array(of: .string), .required)
            .field(.rawIntEnumArray, .array(of: .int), .required)

            //MARK: Dictionary Fields
            .field(.stringDictionary, .dictionary(of: .string), .required)
            .field(.intDictionary, .dictionary(of: .int), .required)
            .field(.enumDictionary, .dictionary(of: .enum(TestStringEnum.self)), .required)
            .create()

    }

    public func revert(on database: any FluentKit.Database) async throws {
        try await database.schema(KitchenSink.schema).delete()
    }
}
```

### Reflection-Based Migration

```swift
// Simple AutoMigration
final class KitchenSinkMigration: AutoMigration<KitchenSink> {}

// That's it! The migration is automatically generated based on your model structure

// Usage in configure.swift
app.migrations.add(KitchenSinkMigration())
```

### Customizing Reflection-Based Migrations

You can customize the reflection-based migration when needed:

```swift
final class CustomKitchenSinkMigration: AutoMigration<KitchenSink> {
    // Custom field key mapping
    override var fieldKeyMap: [String: FieldKey] {
        [
            "stringField": "custom_string_field",
            "intField": "custom_int_field"
        ]
    }
    
    // Override specific field definitions
    override func override(schema: SchemaBuilder, property: ReflectedSchemaProperty) -> Bool {
        if property.fieldName == "stringField" {
            schema.field("custom_string_field", .string, .required)
                 .unique(on: "custom_string_field")
            return true
        }
        return false
    }
    
    // Add additional schema customization
    @discardableResult
    override func customize(schema: SchemaBuilder) -> SchemaBuilder {
        schema
            .unique(on: "email")
            .index(on: "created_at")
    }
}
```

### ReflectionConfiguration

For more complex scenarios, you can provide a custom ReflectionConfiguration:

```swift
let config = ReflectionConfiguration(
    // Custom field key mapping
    fieldKeyMap: [
        "stringField": "custom_string",
        "intField": "custom_int"
    ],
    // Custom schema overrides
    overrides: { schema, property in
        if property.fieldName == "email" {
            schema.field("email", .string, .required)
                 .unique(on: "email")
            return true
        }
        return false
    }
)

// Use with auto-migration
try await database.autoMigrate(KitchenSink.self, configuration: config)
```

### Direct Model Migration

For simple cases, you can migrate models directly:

```swift
// Automatically create schema based on model structure
try await KitchenSink.autoMigrate(on: database)

```

## Advanced Usage

For more detailed examples and advanced features, please refer to our [comprehensive documentation](https://appsaurus.github.io/FluentExtensions/).

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
