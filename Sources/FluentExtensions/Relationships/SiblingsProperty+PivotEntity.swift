//
//  SiblingsProperty+PivotEntity.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/24/24.
//

/// Extension that provides convenience initialization for ``SiblingsProperty`` when using a generic ``PivotEntity``.
///
/// This extension simplifies the creation of many-to-many relationships by providing a default implementation
/// for relationships that use the standard ``PivotEntity`` type as their through model.
///
/// ## Example Usage
/// ```swift
/// final class User: Model {
///     @Siblings(through: PivotEntity<User, Group>.self)
///     var groups: [Group]
/// }
/// ```
extension SiblingsProperty where Through == PivotEntity<From, To> {
    
    /// Creates a new siblings property using ``PivotEntity`` as the through model.
    ///
    /// This initializer automatically configures the relationship using the standard property paths
    /// defined in ``PivotEntity``: `$from` and `$to`.
    ///
    /// - Parameter through: The concrete ``PivotEntity`` type to use for the relationship.
    ///                     Defaults to `PivotEntity<From, To>`.
    public convenience init(through _: Through.Type = PivotEntity<From, To>.self) {
        self.init(through: Through.self,
                  from: \Through.$from,
                  to: \Through.$to)
    }
}
