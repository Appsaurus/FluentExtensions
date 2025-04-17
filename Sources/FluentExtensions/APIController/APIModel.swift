//
//  APIModel.swift
//
//
//  Created by Brian Strobach on 5/21/24.
//

import Fluent
import Vapor

/// A model that supports full CRUD operations through API endpoints.
///
/// `APIModel` combines the capabilities of querying, writing, and deleting data through API endpoints.
/// By conforming to this protocol, your model will automatically support:
/// - Reading and searching operations via `APIQueryable`
/// - Create, update, save, and patch operations via `APIWritable`
/// - Delete operations via `APIDeletable`
protocol APIModel: APIQueryable, APIWritable, APIDeletable {}

/// A model that supports read and search operations through API endpoints.
typealias APIQueryable = APIReadable & APISearchable

/// A model that can be read through API endpoints.
///
/// Use this protocol to define how your model's data should be formatted when read through an API endpoint.
/// The associated `ReadOutput` type allows you to transform your model data into a different format
/// specifically designed for API responses.
protocol APIReadable: Model {
    /// The type returned by read operations.
    ///
    /// By default, this is set to `Self`, meaning the model itself will be returned.
    /// You can specify a different type to customize the API response format.
    associatedtype ReadOutput: Content = Self
}

/// A model that can be searched through API endpoints.
///
/// This protocol enables search functionality for your model through API endpoints.
/// You can customize both the input parameters accepted for search queries and
/// the format of the search results.
protocol APISearchable: Model {
    /// The type used for search input parameters.
    ///
    /// By default, this is set to `String?`, allowing for simple string-based searches.
    /// You can specify a custom type to support more complex search criteria.
    associatedtype SearchInput: Content = String?
    
    /// The type returned in search results.
    ///
    /// By default, this is set to `Self`, meaning the model itself will be returned.
    /// You can specify a different type to customize how search results are formatted.
    associatedtype SearchOutput: Content = Self
}

/// A model that supports write operations through API endpoints.
typealias APIWritable = APICreatable & APIUpdatable & APISavable & APIPatchable

/// A model that can be created through API endpoints.
///
/// This protocol defines how new instances of your model can be created via API endpoints.
/// You can specify different types for the input data and the response format.
protocol APICreatable: Model {
    /// The type accepted for creating new instances.
    ///
    /// This type defines the structure of data required to create a new instance.
    /// By default, it's set to `Self`, meaning the model's own structure is used.
    associatedtype CreateInput: Content = Self
    
    /// The type returned after successful creation.
    ///
    /// This type defines how the newly created instance is formatted in the response.
    /// By default, it's set to `Self`, returning the model instance as-is.
    associatedtype CreateOutput: Content = Self
}

/// A model that can be updated through API endpoints.
///
/// This protocol defines how existing instances of your model can be updated via API endpoints.
/// You can specify different types for the update data and the response format.
protocol APIUpdatable: Model {
    /// The type accepted for updates.
    ///
    /// This type defines the structure of data required to update an existing instance.
    /// By default, it's set to `Self`, meaning the model's own structure is used.
    associatedtype UpdateInput: Content = Self
    
    /// The type returned after successful update.
    ///
    /// This type defines how the updated instance is formatted in the response.
    /// By default, it's set to `Self`, returning the model instance as-is.
    associatedtype UpdateOutput: Content = Self
}

/// A model that can be saved through API endpoints.
///
/// This protocol defines how model instances can be saved via API endpoints.
/// The save operation typically handles both creation and updates.
protocol APISavable: Model {
    /// The type accepted for saving.
    ///
    /// This type defines the structure of data required to save an instance.
    /// By default, it's set to `Self`, meaning the model's own structure is used.
    associatedtype SaveInput: Content = Self
    
    /// The type returned after successful save.
    ///
    /// This type defines how the saved instance is formatted in the response.
    /// By default, it's set to `Self`, returning the model instance as-is.
    associatedtype SaveOutput: Content = Self
}

/// A model that supports partial updates through API endpoints.
///
/// This protocol defines how your model handles PATCH operations, allowing for
/// partial updates to existing instances.
protocol APIPatchable: Model {
    /// The type accepted for patch updates.
    ///
    /// This type defines the structure of data required for partial updates.
    /// By default, it's set to `Self`, meaning the model's own structure is used.
    associatedtype PatchInput: Content = Self
    
    /// The type returned after successful patch.
    ///
    /// This type defines how the patched instance is formatted in the response.
    /// By default, it's set to `Self`, returning the model instance as-is.
    associatedtype PatchOutput: Content = Self
}

/// A model that can be deleted through API endpoints.
///
/// This protocol defines how instances of your model can be deleted via API endpoints.
/// You can specify different types for the deletion criteria and response format.
protocol APIDeletable: Model {
    /// The type accepted for deletion.
    ///
    /// This type defines any additional data required for deletion.
    /// By default, it's set to `Self`, though typically only an ID is needed.
    associatedtype DeleteInput: Content = Self
    
    /// The type returned after successful deletion.
    ///
    /// This type defines what information is returned after deletion.
    /// By default, it's set to `Self`, though you might want to return just a success message.
    associatedtype DeleteOutput: Content = Self
}
