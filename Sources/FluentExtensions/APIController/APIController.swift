//
//  APIController.swift
//
//
//  Created by Brian Strobach on 5/21/24.
//

import Fluent
import Vapor

/// A protocol that defines a RESTful API controller for managing database models.
///
/// `APIController` provides a standardized interface for implementing CRUD operations
/// and extended functionality for model management through HTTP endpoints.
///
/// ## Overview
/// This controller protocol is designed to handle common API patterns including:
/// - Basic CRUD operations (Create, Read, Update, Delete)
/// - Batch operations for multiple models
/// - Search and find operations
/// - Flexible input/output type handling
///
/// ## Example Implementation
/// ```swift
/// final class UserController: APIController {
///     typealias Model = User
///
///     var idKey: String { "id" }
///
///     func getID(_ req: Request) throws -> UUID {
///         try req.parameters.require(idKey)
///     }
///
///     // Implement other required methods...
/// }
/// ```
protocol APIController {
    /// The model type that this controller manages.
    ///
    /// The model must conform to `APIModel` to ensure it supports all required
    /// API operations and type definitions.
    associatedtype Model: APIModel
    
    /// The key used to identify model instances in routes and queries.
    ///
    /// This value is typically used in route parameters and should match the
    /// model's ID field name (e.g., "id").
    var idKey: String { get }

    /// Extracts a model identifier from the request.
    ///
    /// - Parameter request: The incoming HTTP request containing the ID.
    /// - Returns: The parsed ID value matching the model's `IDValue` type.
    /// - Throws: If the ID cannot be extracted or is invalid.
    func getID(_ request: Request) throws -> Model.IDValue

    // MARK: - Create Operations

    /// Creates a new model instance from raw input data.
    ///
    /// - Parameter input: The data used to create the model instance.
    /// - Returns: The created model's output representation.
    /// - Throws: If creation fails or validation errors occur.
    func create(_ input: Model.CreateInput) async throws -> Model.CreateOutput
    
    /// Creates a new model instance from request data.
    ///
    /// - Parameter request: The incoming request containing creation data.
    /// - Returns: The created model's output representation.
    /// - Throws: If creation fails or validation errors occur.
    func create(_ request: Request) async throws -> Model.CreateOutput
    
    /// Creates multiple model instances from an array of inputs.
    ///
    /// - Parameter inputs: Array of creation data for multiple instances.
    /// - Returns: Array of created models' output representations.
    /// - Throws: If any creation fails or validation errors occur.
    func createAll(_ inputs: [Model.CreateInput]) async throws -> Model.CreateOutput
    func createAll(_ request: Request) async throws -> [Model.CreateOutput]
    
    // MARK: - Read Operations
    
    /// Retrieves a single model instance.
    ///
    /// - Parameter request: The incoming request containing model identifier.
    /// - Returns: The model's read output representation.
    /// - Throws: If the model cannot be found or access is denied.
    func read(_ request: Request) async throws -> Model.ReadOutput
    
    /// Retrieves a paginated list of model instances.
    ///
    /// - Parameter request: The incoming request containing pagination parameters.
    /// - Returns: A page of model read outputs.
    /// - Throws: If the query fails or parameters are invalid.
    func readAll(_ request: Request) async throws -> Page<Model.ReadOutput>
    
    // MARK: - Update Operations
    
    /// Updates an existing model instance.
    ///
    /// - Parameter request: The incoming request containing update data.
    /// - Returns: The updated model's output representation.
    /// - Throws: If the update fails or validation errors occur.
    func update(_ request: Request) async throws -> Model.UpdateOutput
    
    /// Updates multiple model instances.
    ///
    /// - Parameter request: The incoming request containing bulk update data.
    /// - Returns: Array of updated models' output representations.
    /// - Throws: If any updates fail or validation errors occur.
    func updateAll(_ request: Request) async throws -> [Model.UpdateOutput]
    
    // MARK: - Delete Operations
    
    /// Deletes a model instance.
    ///
    /// - Parameter request: The incoming request containing model identifier.
    /// - Returns: The deleted model's output representation.
    /// - Throws: If deletion fails or the model cannot be found.
    func delete(_ request: Request) async throws -> Model.DeleteOutput
    
    /// Deletes multiple model instances.
    ///
    /// - Parameter request: The incoming request containing deletion criteria.
    /// - Returns: Array of deleted models' output representations.
    /// - Throws: If any deletions fail or models cannot be found.
    func deleteAll(_ request: Request) async throws -> [Model.DeleteOutput]
    
    // MARK: - Search Operations
    
    /// Finds a specific model instance based on search criteria.
    ///
    /// - Parameter request: The incoming request containing search parameters.
    /// - Returns: The matching model's search output representation.
    /// - Throws: If no match is found or search parameters are invalid.
    func find(_ request: Request) throws -> Model.SearchOutput
    
    /// Searches for model instances matching given criteria.
    ///
    /// - Parameter request: The incoming request containing search parameters.
    /// - Returns: A page of matching models' search output representations.
    /// - Throws: If the search fails or parameters are invalid.
    func search(_ request: Request) async throws -> Page<Model.SearchOutput>
    
    // MARK: - Save Operations
    
    /// Saves a model instance, creating or updating as needed.
    ///
    /// - Parameter request: The incoming request containing model data.
    /// - Returns: The saved model's output representation.
    /// - Throws: If the save operation fails or validation errors occur.
    func save(_ request: Request) async throws -> Model.SaveOutput
    
    /// Saves multiple model instances.
    ///
    /// - Parameter request: The incoming request containing bulk save data.
    /// - Returns: Array of saved models' output representations.
    /// - Throws: If any saves fail or validation errors occur.
    func saveAll(_ request: Request) async throws -> [Model.SaveOutput]
    
    // MARK: - Route Setup
    
    /// Sets up all routes for this controller on the specified endpoint.
    ///
    /// This method configures all CRUD routes and additional functionality
    /// endpoints for the model. The typical REST pattern is followed:
    /// - GET /endpoint - List all
    /// - POST /endpoint - Create
    /// - GET /endpoint/:id - Read one
    /// - PUT /endpoint/:id - Update
    /// - DELETE /endpoint/:id - Delete
    ///
    /// - Parameters:
    ///   - routes: The routes builder to register routes on.
    ///   - endpoint: The base path for all routes (e.g., "users").
    /// - Returns: The routes builder for method chaining.
    @discardableResult
    func setup(routes: RoutesBuilder, on endpoint: String) -> RoutesBuilder
}
