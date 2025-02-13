//
//  Controller+Config.swift
//
//
//  Created by Brian Strobach on 2/3/25.
//

import Fluent

extension Controller {
    public class AccessControl {
        public typealias ResourceCheck = (Request, Resource) async throws -> Bool
        public typealias ResourcesCheck = (Request, [Resource]) async throws -> Bool
        public typealias ResourceChecks = [AuthorizedAction: ResourceCheck]
        public typealias ResourcesChecks = [AuthorizedAction: ResourcesCheck]
        
        public var resource: ResourceChecks
        public var resources: ResourcesChecks
        
        public init(resource: ResourceChecks = [:],
                    resources: ResourcesChecks = [:]) {
            self.resource = resource
            self.resources = resources
        }
    }
    
    public class Config {
        public var baseRoute: [PathComponentRepresentable]
        public var middlewares: [Middleware]
        public var supportedActions: SupportedActions
        public var saveMethod: SaveMethod
        public var putAction: PUTRouteAction
        public var forceDelete: Bool
        public var accessControl: AccessControl
        
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
        //        case deleteBatch
    }
    
    public enum AuthorizedAction {
        case read
        case create
        case update
        case save
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

public enum PUTRouteAction: Decodable {
    case update
    case save
    public static var `default` = PUTRouteAction.save
}

public enum SaveMethod: Decodable {
    case save
    case upsert
    public static var `default` = SaveMethod.upsert
}

public enum UpdateMethod: Decodable {
    case save
    case upsert
    case update
    public static var `default` = UpdateMethod.upsert
}


public typealias ResourceModel = Content & Parameter
public typealias CreateModel = Content
public typealias ReadModel = Content
public typealias UpdateModel = Content
public typealias SearchResultModel = Content
