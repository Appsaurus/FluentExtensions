//
//  TestModel.swift
//  FluentTestModels
//
//  Created by Brian Strobach on 11/28/17.
//

import FluentExtensions

private extension FieldKey {
    static var stringField: Self { "stringField" }
    static var optionalStringField: Self { "optionalStringField" }
    static var intField: Self { "intField" }
    static var doubleField: Self { "doubleField" }
    static var booleanField: Self { "booleanField" }
    static var dateField: Self { "dateField" }
    static var optionalDateField: Self { "optionalDateField" }
    static var stringArrayField: Self { "stringArrayField" }
    static var intArrayField: Self { "intArrayField" }
    static var doubleArrayField: Self { "doubleArrayField" }
    static var booleanArrayField: Self { "booleanArrayField" }
    static var dateArrayField: Self { "dateArrayField" }
    static var createdAt: Self { "createdAt" }
    static var updatedAt: Self { "updatedAt" }
    static var deletedAt: Self { "deletedAt" }
    static var groupedFields: Self { "groupedFields" }
    static var stringEnum: Self { "stringEnum" }
    static var optionalStringEnum: Self { "optionalStringEnum" }
    static var rawStringEnum: Self { "rawStringEnum" }
    static var optionalRawStringEnum: Self { "optionalRawStringEnum" }
    static var rawIntEnum: Self { "rawIntEnum" }
    static var optionalRawIntEnum: Self { "optionalRawIntEnum" }
    static var stringEnumArray: Self { "stringEnumArray" }
    static var rawStringEnumArray: Self { "rawStringEnumArray" }
    static var rawIntEnumArray: Self { "rawIntEnumArray" }
    static var stringDictionary: Self { "stringDictionary" }
    static var intDictionary: Self { "intDictionary" }
    static var enumDictionary: Self { "enumDictionary" }
}

public final class KitchenSink: TestModel, @unchecked Sendable {

    @ID(custom: .id)
	public var id: Int?

    //MARK: Basic Data Type Fields

    @Field(key: .stringField)
    public var stringField: String

    @OptionalField(key: .optionalStringField)
    public var optionalStringField: String?

    @Field(key: .intField)
    public var intField: Int

    @Field(key: .doubleField)
	public var doubleField: Double

    @Field(key: .booleanField)
	public var booleanField: Bool

    @Field(key: .dateField)
	public var dateField: Date
    
    @OptionalField(key: .optionalDateField)
    public var optionalDateField: Date?

    //MARK: Collection Fields

    @Field(key: .stringArrayField)
    public var stringArrayField: [String]

    @Field(key: .intArrayField)
    public var intArrayField: [Int]

    @Field(key: .doubleArrayField)
    public var doubleArrayField: [Double]

    @Field(key: .booleanArrayField)
    public var booleanArrayField: [Bool]

    @Field(key: .dateArrayField)
    public var dateArrayField: [Date]

    //MARK: Timestamp Updated Fields

    @Timestamp(key: .createdAt, on: .create)
    public var createdAt: Date?

    @Timestamp(key: .updatedAt, on: .update)
    public var updatedAt: Date?

    @Timestamp(key: .deletedAt, on: .delete)
    public var deletedAt: Date?

    //MARK: Grouped Fields

    @Group(key: .groupedFields)
    public var groupedFields: TestGroupedFieldsModel

    //MARK: Enum Fields

    @Enum(key: .stringEnum)
    public var stringEnum: TestStringEnum

    @OptionalEnum(key: .optionalStringEnum)
    public var optionalStringEnum: TestStringEnum?

    @Field(key: .rawStringEnum)
    public var rawStringEnum: TestRawStringEnum

    @OptionalField(key: .optionalRawStringEnum)
    public var optionalRawStringEnum: TestRawStringEnum?

    @Field(key: .rawIntEnum)
    public var rawIntEnum: TestRawIntEnum

    @OptionalField(key: .optionalRawIntEnum)
    public var optionalRawIntEnum: TestRawIntEnum?

    //MARK: Enum Collection Fields

    @Field(key: .stringEnumArray)
    public var stringEnumArray: [TestStringEnum]

    @Field(key: .rawStringEnumArray)
    public var rawStringEnumArray: [TestRawStringEnum]

    @Field(key: .rawIntEnumArray)
    public var rawIntEnumArray: [TestRawIntEnum]

    //MARK: Dictionary Fields

    @Field(key: .stringDictionary)
    public var stringDictionary: [String: String]

    @Field(key: .intDictionary)
    public var intDictionary: [String: Int]

    @Field(key: .enumDictionary)
    public var enumDictionary: [String: TestStringEnum]

    public convenience init() {
        self.init(optionalStringField: nil)
    }

    public init(id: Int? = nil,
                stringField: String = "StringValue",
                optionalStringField: String? = nil,
                intField: Int = 1,
                doubleField: Double = 2.0,
                booleanField: Bool = true,
                dateField: Date = Date(),
                optionalDateField: Date? = nil,
                stringArrayField: [String] = ["StringValue"],
                intArrayField: [Int] = [1],
                doubleArrayField: [Double] = [2.0],
                booleanArrayField: [Bool] = [true],
                dateArrayField: [Date] = [Date()],
                groupedFields: TestGroupedFieldsModel = TestGroupedFieldsModel(),
                stringEnum: TestStringEnum = .case1,
                optionalStringEnum: TestStringEnum = .case1,
                rawStringEnum: TestRawStringEnum = .case1,
                optionalRawStringEnum: TestRawStringEnum = .case1,
                rawIntEnum: TestRawIntEnum = .case1,
                optionalRawIntEnum: TestRawIntEnum = .case1,
                stringEnumArray: [TestStringEnum] = TestStringEnum.allCases,
                rawStringEnumArray: [TestRawStringEnum] = TestRawStringEnum.allCases,
                rawIntEnumArray: [TestRawIntEnum] = TestRawIntEnum.allCases,
                stringDictionary: [String: String] = ["key1" : "value1", "key2" : "value2"],
                intDictionary: [String: Int] = ["key1" : 1, "key2" : 2],
                enumDictionary: [String: TestStringEnum] = ["key1" : .case1, "key2" : .case2]) {
        self.id = id
        self.stringField = stringField
        self.optionalStringField = optionalStringField
        self.intField = intField
        self.doubleField = doubleField
        self.booleanField = booleanField
        self.dateField = dateField
        self.optionalDateField = optionalDateField
        self.stringArrayField = stringArrayField
        self.intArrayField = intArrayField
        self.doubleArrayField = doubleArrayField
        self.booleanArrayField = booleanArrayField
        self.dateArrayField = dateArrayField
        self.groupedFields = groupedFields
        self.stringEnum = stringEnum
        self.optionalStringEnum = optionalStringEnum
        self.rawStringEnum = rawStringEnum
        self.optionalRawStringEnum = optionalRawStringEnum
        self.rawIntEnum = rawIntEnum
        self.optionalRawIntEnum = optionalRawIntEnum
        self.stringEnumArray = stringEnumArray
        self.rawStringEnumArray = rawStringEnumArray
        self.rawIntEnumArray = rawIntEnumArray
        self.stringDictionary = stringDictionary
        self.intDictionary = intDictionary
        self.enumDictionary = enumDictionary
    }

}

public final class TestGroupedFieldsModel: Fields, @unchecked Sendable  {

    @Field(key: .stringField)
    public var stringField: String

    @OptionalField(key: .optionalStringField)
    public var optionalStringField: String?

    @Field(key: .intField)
    public var intField: Int

    public convenience init() {
        self.init(optionalStringField: nil)
    }

    public init(stringField: String = "StringValue",
                optionalStringField: String? = nil,
                intField: Int = 1) {
        self.stringField = stringField
        self.optionalStringField = optionalStringField
        self.intField = intField
    }
}


public enum TestIntEnum: Int, Codable, CaseIterable {
    case case1
    case case2
    case case3
}

public enum TestStringEnum: String, Codable, RawRepresentable, CaseIterable {
    case case1
    case case2
    case case3
}

public enum TestRawStringEnum: String, Codable, CaseIterable {
    case case1
    case case2
    case case3
}

public enum TestRawIntEnum: Int, Codable, CaseIterable {
    case case1
    case case2
    case case3
}


//MARK: Reflection-based migration
public final class KitchenSinkReflectionMigration: AutoMigration<KitchenSink>, @unchecked Sendable {}

//MARK: Manual migration
public final class KitchenSinkMigration: AsyncMigration {
    
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
