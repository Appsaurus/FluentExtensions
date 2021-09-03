//
//  EntityExtensions.swift
//  
//
//  Created by Brian Strobach on 11/30/17.
//


//MARK: Query extensions

extension Model {

	public static func find(_ ids: [IDValue], on database: Database) -> Future<[Self]>{
		return query(on: database).filter(\._$id  ~~ ids).all()

	}
	/// Attempts to find an instance of this model w/
	/// the supplied value at the given key path
    public static func find<V: Encodable & QueryableProperty>(_ keyPath: KeyPath<Self, V>,
                                                              value: V.Value,
                                                              on database: Database) -> Future<Self?> {
        return query(on: database).filter(keyPath == value).first()
	}
}


extension Model {

    /// Attempts to find all records of this entity w/
    /// the supplied value at the given key path
    public static func findAll<V: QueryableProperty & Codable>(_ keyPath: KeyPath<Self, FieldProperty<Self, V>>, value: V, limit: Int? = nil, on database: Database) -> Future<[Self]> {
        return query(on: database).filter(keyPath == value).at(most: limit)
    }

    public static func find(where filters: ModelValueFilter<Self>..., on database: Database) -> Future<Self?> {
        return find(where: filters, on: database)
    }

    public static func find(where filters: [ModelValueFilter<Self>], on database: Database) -> Future<Self?> {
        return query(on: database).filter(filters).first()
    }

    public static func findAll(where filters: ModelValueFilter<Self>..., limit: Int? = nil, on database: Database) -> Future<[Self]> {
        return findAll(where: filters, limit: limit, on: database)
    }

    public static func findAll(where filters: [ModelValueFilter<Self>], limit: Int? = nil, on database: Database) -> Future<[Self]> {
        return query(on: database).filter(filters).at(most: limit)
    }
}
