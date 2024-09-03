//
//  TestModel.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/1/24.
//

import Fluent
import Vapor
import FluentExtensions

public typealias TestModel = Model & Parameter & Content & Paginatable
