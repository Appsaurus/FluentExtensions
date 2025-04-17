//
//  KeypathTypealiases.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

import Fluent

/// A key path that points to any queryable property on a model
public typealias QueryablePropertyKeyPath<M: Model> = KeyPath<M, any QueryableProperty>

/// A key path that points to the ID property of a model
public typealias IDPropertyKeyPath<M: Model> = KeyPath<M, IDProperty<M, M.IDValue>>

/// A key path that points to a foreign ID property, linking one model to another
public typealias ForeignIDPropertyKeyPath<From: Model, To: Model> = KeyPath<From, IDProperty<From, To.IDValue>>

/// A key path that points to a required field property on a model
public typealias FieldPropertyKeyPath<M: Model, V: Codable> = KeyPath<M, FieldProperty<M, V>>

/// A key path that points to an optional field property on a model
public typealias OptionalFieldPropertyKeyPath<M: Model, V: Codable> = KeyPath<M, OptionalFieldProperty<M, V>>

/// A key path that points to a timestamp property on a model
public typealias TimestampPropertyKeyPath<M: Model, F: TimestampFormat> = KeyPath<M, TimestampProperty<M, F>>

/// A key path that points to a children relationship property on a model
public typealias ChildrenPropertyKeyPath<Parent: Model, Child: Model> = KeyPath<Parent, ChildrenProperty<Parent, Child>>

/// A key path that points to an optional child relationship property on a model
public typealias OptionalChildPropertyKeyPath<Parent: Model, Child: Model> = KeyPath<Parent, OptionalChildProperty<Parent, Child>>

/// A key path that points to a parent relationship property on a model
public typealias ParentPropertyKeyPath<Parent: Model, Child: Model> = KeyPath<Child, ParentProperty<Child, Parent>>

/// A key path that points to an optional parent relationship property on a model
public typealias OptionalParentPropertyKeyPath<Parent: Model, Child: Model> = KeyPath<Child, OptionalParentProperty<Child, Parent>>

/// A key path that points to a siblings relationship property on a model
public typealias SiblingPropertyKeyPath<From: Model, To: Model, Through: Model> = KeyPath<From, SiblingsProperty<From, To, Through>>
