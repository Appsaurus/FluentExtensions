//
//  KeyPath+SQLColumn.swift
//  
//
//  Created by Brian Strobach on 9/9/21.
//

import FluentSQL


public extension KeyPath where Root: Model, Value: QueryableProperty {

    var sqlColumn: SQLColumn {
        SQLColumn(self)
    }

    var sqlTable: SQLExpression {
        return Root.sqlTable
    }
}


public extension SQLColumn {
    init<M: Model, V: QueryableProperty, KP: KeyPath<M,V>>(_ keyPath: KP)  {
        self.init(keyPath.propertyName, table: M.schemaOrAlias)
    }
}
extension KeyPath: SQLExpression where Root: Model, Value: QueryableProperty {

    public func serialize(to serializer: inout SQLSerializer) {
        SQLColumn(propertyName, table: Root.schemaOrAlias).serialize(to: &serializer)
    }
}
