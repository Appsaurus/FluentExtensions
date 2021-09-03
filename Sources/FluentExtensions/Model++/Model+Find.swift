//
//  EntityExtensions.swift
//  
//
//  Created by Brian Strobach on 11/30/17.
//


//MARK: Query public extensions

public extension Model {

	static func find(_ ids: [IDValue], on database: Database) -> Future<[Self]>{
		return query(on: database).filter(\._$id  ~~ ids).all()

	}
	/// Attempts to find an instance of this model w/
	/// the supplied value at the given key path
    static func find<V: Encodable & QueryableProperty>(_ keyPath: KeyPath<Self, V>,
                                                              value: V.Value,
                                                              on database: Database) -> Future<Self?> {
        return query(on: database).filter(keyPath == value).first()
	}
}


public extension Model {

    /// Attempts to find all records of this entity w/
    /// the supplied value at the given key path
    static func findAll<V: QueryableProperty & Codable>(_ keyPath: KeyPath<Self, FieldProperty<Self, V>>, value: V, limit: Int? = nil, on database: Database) -> Future<[Self]> {
        return query(on: database).filter(keyPath == value).at(most: limit)
    }

    static func find(where filters: ModelValueFilter<Self>..., on database: Database) -> Future<Self?> {
        return find(where: filters, on: database)
    }

    static func find(where filters: [ModelValueFilter<Self>], on database: Database) -> Future<Self?> {
        return query(on: database).filter(filters).first()
    }

    static func findAll(where filters: ModelValueFilter<Self>..., limit: Int? = nil, on database: Database) -> Future<[Self]> {
        return findAll(where: filters, limit: limit, on: database)
    }

    static func findAll(where filters: [ModelValueFilter<Self>], limit: Int? = nil, on database: Database) -> Future<[Self]> {
        return query(on: database).filter(filters).at(most: limit)
    }
}
