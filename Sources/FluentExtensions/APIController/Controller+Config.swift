//
//  Controller+Config.swift
//
//
//  Created by Brian Strobach on 2/3/25.
//

import Fluent

extension Controller {
    /// Access control configuration for resource-level authorization.
    public class AccessControl {
        /// Typealias for a single-resource authorization check.
        public typealias ResourceCheck = (Request, Resource) async throws -> Bool
        /// Typealias for a multi-resource authorization check.
        public typealias ResourcesCheck = (Request, [Resource]) async throws -> Bool
        /// Dictionary mapping authorized actions to their respective resource-level checks.
        public typealias ResourceChecks = [AuthorizedAction: ResourceCheck]
        /// Dictionary mapping authorized actions to their respective collection-level checks.
        public typealias ResourcesChecks = [AuthorizedAction: ResourcesCheck]
        
        /// Resource-level authorization checks.
        public var resource: ResourceChecks
        /// Collection-level authorization checks.
        public var resources: ResourcesChecks
        
        /// Creates a new access control configuration.
        /// - Parameters:
        ///   - resource: Resource-level authorization checks.
        ///   - resources: Collection-level authorization checks.
        public init(resource: ResourceChecks = [:],
                    resources: ResourcesChecks = [:]) {
            self.resource = resource
            self.resources = resources
        }
    }
    
    /// Configuration for controller behavior and routing.
    public class Config {
        /// Base route components for all endpoints managed by this controller.
        public var baseRoute: [PathComponentRepresentable]
        /// Middleware to be applied to all routes managed by this controller.
        public var middlewares: [Middleware]
        /// Configuration for which CRUD actions are supported by this controller.
        public var supportedActions: SupportedActions
        /// Strategy for handling save operations.
        public var saveMethod: SaveMethod
        /// Strategy for handling PUT requests.
        public var putAction: PUTRouteAction
        /// Whether delete operations should force delete by default.
        public var forceDelete: Bool
        /// Access control configuration for authorization checks.
        public var accessControl: AccessControl
        
        /// Creates a new controller configuration.
        /// - Parameters:
        ///   - baseRoute: Base route components for all endpoints.
        ///   - middlewares: Middleware to be applied to all routes.
        ///   - supportedActions: Configuration for supported CRUD actions.
        ///   - saveMethod: Strategy for handling save operations.
        ///   - putAction: Strategy for handling PUT requests.
        ///   - forceDelete: Whether delete operations should force delete.
        ///   - accessControl: Access control configuration.
        public init(baseRoute: [PathComponentRepresentable] = [],
                    middlewares: [Middleware] = [],
                    supportedActions: SupportedActions = .all,
                    saveMethod: SaveMethod = .default,
                    putAction: PUTRouteAction = .default,
                    forceDelete: Bool = false,
                    accessControl: AccessControl = AccessControl()) {
            self.baseRoute = baseRoute
            self.middlewares = middlewares
            self.supportedActions = supportedActions
            self.saveMethod = saveMethod
            self.putAction = putAction
            self.forceDelete = forceDelete
            self.accessControl = accessControl
        }
    }
    
    /// Available CRUD actions that can be supported by a controller.
    public enum Action: Codable, CaseIterable {
        case search
        case read
        case readAll
        case create
        case createBatch
        case update
        case updateBatch
        case save
        case saveBatch
        case delete
    }
    
    /// Actions that can require authorization.
    public enum AuthorizedAction {
        case read
        case create
        case update
        case save
        case delete
    }
    
    /// Configuration for which actions are supported by a controller.
    public enum SupportedActions {
        /// Supports all actions except those specified.
        case everythingBut(_ actions: [Controller.Action])
        /// Supports only the specified actions.
        case only(_ actions: [Controller.Action])
        /// Supports no actions.
        case none
        /// Supports all available actions.
        case all
        
        /// The resolved list of supported actions based on the configuration.
        var supportedActions: [Controller.Action] {
            switch self {
            case .all:
                return Action.allCases
            case .none:
                return []
            case .only(let actions):
                return actions
            case .everythingBut(let excludedActions):
                let allActions: Set<Controller.Action> = Set(SupportedActions.all.supportedActions)
                return Array(allActions.subtracting(Set(excludedActions)))
            }
        }
    }
}

/// Strategy for handling PUT requests.
public enum PUTRouteAction: Decodable {
    /// Treat PUT requests as updates.
    case update
    /// Treat PUT requests as saves.
    case save
    /// Default strategy for PUT requests.
    public static var `default` = PUTRouteAction.save
}

/// Strategy for handling save operations.
public enum SaveMethod: Decodable {
    /// Standard save operation.
    case save
    /// Upsert operation (create if doesn't exist, update if exists).
    case upsert
    /// Default save strategy.
    public static var `default` = SaveMethod.upsert
}

/// Strategy for handling update operations.
public enum UpdateMethod: Decodable {
    /// Standard save operation.
    case save
    /// Upsert operation.
    case upsert
    /// Update operation.
    case update
    /// Default update strategy.
    public static var `default` = UpdateMethod.upsert
}

/// Protocol requirements for models that can be used as resources.
public typealias ResourceModel = Content & Parameter
/// Protocol requirements for models that can be created.
public typealias CreateModel = Content
/// Protocol requirements for models that can be read.
public typealias ReadModel = Content
/// Protocol requirements for models that can be updated.
public typealias UpdateModel = Content
/// Protocol requirements for search result models.
public typealias SearchResultModel = Content
