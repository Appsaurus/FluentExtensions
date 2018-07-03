//
//  FluentPropertyExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/27/18.
//

import Foundation
import Fluent

extension FluentProperty{
	public var name: String{
		return path.last!
	}
	public var fullPath: String{
		return path.joined(separator: ".")
	}
}
