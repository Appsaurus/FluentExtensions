//
//  SQLSelectBuilder+Join.swift
//  
//
//  Created by Brian Strobach on 10/26/21.
//

import SQLKit

public extension SQLSelectBuilder {
    func join<Foreign, ForeignField, Local, LocalField>(
        _ lhs: KeyPath<Local, LocalField>, to rhs: KeyPath<Foreign, ForeignField>
    ) -> Self
        where
            ForeignField: QueryableProperty,
            ForeignField.Model == Foreign,
            LocalField: QueryableProperty,
            LocalField.Model == Local,
            ForeignField.Value == LocalField.Value,
            Local: Model,
            Foreign: Model {
        return self.join(Foreign.sqlTable, on: lhs, .equal, rhs)
    }
}
