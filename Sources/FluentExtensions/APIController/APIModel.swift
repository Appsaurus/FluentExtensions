//
//  APIModel.swift
//
//
//  Created by Brian Strobach on 5/21/24.
//

import Fluent
import Vapor

protocol APIModel: APIQueryable, APIWritable, APIDeletable {}

typealias APIQueryable = APIReadable & APISearchable

protocol APIReadable: Model {
    associatedtype ReadOutput: Content = Self
}

protocol APISearchable: Model {
    associatedtype SearchInput: Content = String?
    associatedtype SearchOutput: Content = Self
}


typealias APIWritable = APICreatable & APIUpdatable & APISavable & APIPatchable

protocol APICreatable: Model {
    associatedtype CreateInput: Content = Self
    associatedtype CreateOutput: Content = Self
}

protocol APIUpdatable: Model {
    associatedtype UpdateInput: Content = Self
    associatedtype UpdateOutput: Content = Self
}

protocol APISavable: Model {
    associatedtype SaveInput: Content = Self
    associatedtype SaveOutput: Content = Self
}

protocol APIPatchable: Model {
    associatedtype PatchInput: Content = Self
    associatedtype PatchOutput: Content = Self
}

protocol APIDeletable: Model {
    associatedtype DeleteInput: Content = Self
    associatedtype DeleteOutput: Content = Self
}
