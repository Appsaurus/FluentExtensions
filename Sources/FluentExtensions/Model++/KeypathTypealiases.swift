//
//  KeypathTypealiases.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

import Fluent


public typealias QueryablePropertyKeyPath<M: Model> = KeyPath<M, QueryableProperty>

public typealias IDPropertyKeyPath<M: Model> = KeyPath<M, IDProperty<M, M.IDValue>>
public typealias ForeignIDPropertyKeyPath<From: Model, To: Model> = KeyPath<From, IDProperty<From, To.IDValue>>

public typealias FieldPropertyKeyPath<M: Model, V: Codable> = KeyPath<M, FieldProperty<M, V>>
public typealias OptionalFieldPropertyKeyPath<M: Model, V: Codable> = KeyPath<M, OptionalFieldProperty<M, V>>

public typealias TimestampPropertyKeyPath<M: Model, F: TimestampFormat> = KeyPath<M, TimestampProperty<M, F>>

public typealias ChildrenPropertyKeyPath<Parent: Model, Child: Model> = KeyPath<Parent, ChildrenProperty<Parent, Child>>
public typealias OptionalChildPropertyKeyPath<Parent: Model, Child: Model> = KeyPath<Parent, OptionalChildProperty<Parent, Child>>

public typealias ParentPropertyKeyPath<Parent: Model, Child: Model> = KeyPath<Child, ParentProperty<Child, Parent>>
public typealias OptionalParentPropertyKeyPath<Parent: Model, Child: Model> = KeyPath<Child, OptionalParentProperty<Child, Parent>>

public typealias SiblingPropertyKeyPath<From: Model, To: Model, Through: Model> = KeyPath<From, SiblingsProperty<From, To, Through>>
