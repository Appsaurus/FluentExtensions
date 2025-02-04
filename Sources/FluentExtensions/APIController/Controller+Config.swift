//
//  Controller+Config.swift
//
//
//  Created by Brian Strobach on 2/3/25.
//

import Fluent

extension Controller {
    public class AccessControl {
        public var resource: [Action: (Request, Resource) async throws -> Bool]
        public var resources: [Action: (Request, [Resource]) async throws -> Bool]
        
        public init(resource: [Action: (Request, Resource) async throws -> Bool] = [:],
                    resources: [Action: (Request, [Resource]) async throws -> Bool] = [:]) {
            self.resource = resource
            self.resources = resources
        }
    }
    
    public class Config {
        public var baseRoute: [PathComponentRepresentable]
        public var middlewares: [Middleware]
        public var createMethod: CreateMethod
        public var updateMethod: UpdateMethod
        public var forceDelete: Bool
        public var supportedActions: SupportedActions
        public var accessControl: AccessControl
        
        public init(baseRoute: [PathComponentRepresentable] = [],
                   middlewares: [Middleware] = [],
                   supportedActions: SupportedActions = .all,
                   createMethod: CreateMethod = .default,
                   updateMethod: UpdateMethod = .default,
                   forceDelete: Bool = false,
                   accessControl: AccessControl = AccessControl()) {
            self.baseRoute = baseRoute
            self.middlewares = middlewares
            self.supportedActions = supportedActions
            self.createMethod = createMethod
            self.updateMethod = updateMethod
            self.forceDelete = forceDelete
            self.accessControl = accessControl
        }
    }
    
    public enum Action {
        case search
        case read
        case readAll
        case create
        case createBatch
        case update
        case updateBatch
        case delete
    }

    
    public enum SupportedActions {
        case everythingBut(_ actions: [Controller.Action])
        case only(_ actions: [Controller.Action])
        case none
        case all
        
        var supportedActions: [Controller.Action] {
            switch self {
            case .all:
                return [.search, .read, .readAll, .create, .createBatch, .update, .updateBatch, .delete]
            case .none:
                return []
            case .only(let actions):
                return actions
            case .everythingBut(let excludedActions):
                let allActions: Set<Controller.Action> = [.search, .read, .readAll, .create, .createBatch, .update, .updateBatch, .delete]
                return Array(allActions.subtracting(Set(excludedActions)))
            }
        }
    }
}

public enum CreateMethod: Decodable {
    case create
    case save
    case upsert
    public static var `default` = CreateMethod.create
}

public enum UpdateMethod: Decodable {
    case update
    case save
    case upsert
    public static var `default` = UpdateMethod.update
}


public typealias ResourceModel = Content & Parameter
public typealias CreateModel = Content
public typealias ReadModel = Content
public typealias UpdateModel = Content
public typealias SearchResultModel = Content
