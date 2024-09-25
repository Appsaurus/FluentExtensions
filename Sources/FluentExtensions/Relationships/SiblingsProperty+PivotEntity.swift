//
//  SiblingsProperty+PivotEntity.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/24/24.
//


extension SiblingsProperty where Through == PivotEntity<From, To> {
    
    public convenience init(through _: Through.Type = PivotEntity<From, To>.self) {
        self.init(through: Through.self,
                  from: \Through.$from,
                  to: \Through.$to)
    }
}