//
//  Paginatable.swift
//
//
//  Created by Brian Strobach on 9/25/21.
//

/// A namespace for pagination-related configurations and defaults.
public struct Pagination {
    /// Default configuration values for pagination behavior.
    public class Defaults {
        /// The default number of items to display per page.
        public static var pageSize: Int = 10
        
        /// The maximum number of items allowed per page.
        /// - Note: Set to `nil` for no upper limit
        public static var maxPageSize: Int? = nil
        
        /// The query parameter key used to specify the current page number.
        public static var pageKey = "page"
        
        /// The query parameter key used to specify items per page.
        public static var perPageKey = "per"
    }
}

/// A protocol that defines pagination behavior for conforming types.
///
/// Types conforming to `Paginatable` can be used with pagination functionality,
/// allowing for controlled data fetching in manageable chunks.
///
/// Example usage:
/// ```swift
/// struct MyModel: Model, Paginatable {
///     // Implementation details...
/// }
/// ```
public protocol Paginatable {
    /// The default number of items to display per page.
    static var defaultPageSize: Int { get }
    
    /// The maximum number of items allowed per page.
    /// - Note: If `nil`, no upper limit will be enforced
    static var maxPageSize: Int? { get }
}

// MARK: - Default Implementation

public extension Paginatable {
    /// Default implementation providing the standard page size.
    static var defaultPageSize: Int {
        return Pagination.Defaults.pageSize
    }
    
    /// Default implementation providing the maximum page size.
    static var maxPageSize: Int? {
        return Pagination.Defaults.maxPageSize
    }
}
