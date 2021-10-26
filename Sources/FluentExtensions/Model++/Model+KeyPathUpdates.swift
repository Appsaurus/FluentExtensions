//
//  Model+KeyPathUpdates.swift
//  
//
//  Created by Brian Strobach on 10/26/21.
//


public extension Model{
        static func updateValue<Property: QueryableProperty>(at keyPath: KeyPath<Self, Property>,
                                                             to value: Property.Value,
                                      where filters: ModelValueFilter<Self>...,
                                      on database: Database) throws -> Future<[Self]> {

            return try findAll(where: filters, on: database).updateValue(at: keyPath, to: value, on: database)
    }
}

public extension Collection where Element: Model {
    mutating func updateValue<Property: QueryableProperty>(at keyPath: KeyPath<Element, Property>,
                                                           to value: Property.Value,
                                                           on database: Database) throws -> Future<[Element]> {
        let mutatedValues: [Element] = self.map { model in
            model[keyPath: keyPath].value = value
            return model
        }

        return mutatedValues.updateAndReturn(on: database, transaction: true)
    }

}
public extension Future where Value: Collection, Value.Element: Model {

    func updateValue<Property: QueryableProperty>(at keyPath: KeyPath<Value.Element, Property>,
                                                  to value: Property.Value,
                                        on database: Database) throws -> Future<[Value.Element]> {
        tryFlatMap { (results) -> Future<[Value.Element]> in
            var mResults = results
            return try mResults.updateValue(at: keyPath, to: value, on: database)
        }
    }
}


