//
//  DatabaseSchemaDataTypeProviding.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/18/24.
//


public protocol DatabaseSchemaDataTypeProviding {
    static var dataType: DatabaseSchema.DataType { get }
}

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

