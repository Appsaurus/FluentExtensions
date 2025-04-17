//
//  DatabaseSchemaDataTypeProviding.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/18/24.
//

/// A protocol that enables types to provide their corresponding database schema data type.
///
/// Types conforming to `DatabaseSchemaDataTypeProviding` can specify how they should be
/// represented in a database schema. This is particularly useful for automatic schema generation
/// and type mapping between Swift types and database column types.
///
/// ## Example
/// ```swift
/// extension Int: DatabaseSchemaDataTypeProviding {
///     public static var dataType: DatabaseSchema.DataType {
///         .int
///     }
/// }
/// ```
public protocol DatabaseSchemaDataTypeProviding {
    /// The database schema data type that corresponds to this Swift type.
    static var dataType: DatabaseSchema.DataType { get }
}

// MARK: - Integer Types

extension Int: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .int
    }
}

extension Int8: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .int8
    }
}

extension Int16: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .int16
    }
}

extension Int32: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .int32
    }
}

extension Int64: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .int64
    }
}

// MARK: - Unsigned Integer Types

extension UInt: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .uint
    }
}

extension UInt8: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .uint8
    }
}

extension UInt16: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .uint16
    }
}

extension UInt32: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .uint32
    }
}

extension UInt64: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .uint64
    }
}

// MARK: - Basic Types

extension Bool: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .bool
    }
}

extension String: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .string
    }
}

extension Date: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .datetime
    }
}

// MARK: - Floating Point Types

extension Float: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .float
    }
}

extension Double: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .double
    }
}

// MARK: - Binary Data Types

extension Data: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .data
    }
}

extension UUID: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .uuid
    }
}
