//
//  File.swift
//  
//
//  Created by Brian Strobach on 8/5/24.
//

import Foundation
//
//// MARK: Eager Loadable
//
//public extension SelfSiblingsProperty: EagerLoadable {
//    static func eagerLoad<Builder>(
//        _ relationKey: KeyPath<M, M.Siblings<M, Through>>,
//        to builder: Builder
//    )
//        where Builder: EagerLoadBuilder, Builder.Model == M
//    {
//        let loader = SiblingsEagerLoader(relationKey: relationKey)
//        builder.add(loader: loader)
//    }
//
//
//    static func eagerLoad<Loader, Builder>(
//        _ loader: Loader,
//        through: KeyPath<M, M.Siblings<M, Through>>,
//        to builder: Builder
//    ) where
//        Loader: EagerLoader,
//        Loader.Model == M,
//        Builder: EagerLoadBuilder,
//        Builder.Model == M
//    {
//        let loader = ThroughSiblingsEagerLoader(relationKey: through, loader: loader)
//        builder.add(loader: loader)
//    }
//}
//
//
//private struct SelfSiblingsEagerLoader<M, Through>: EagerLoader
//    where M: Model, Through: Model,
//{
//    let relationKey: KeyPath<M, M.SelfSiblings<M, Through>>
//
//    func run(models: [M], on database: Database) -> EventLoopFuture<Void> {
//        let ids = models.map { $0.id! }
//
//        let from = M()[keyPath: self.relationKey].from
//        let to = M()[keyPath: self.relationKey].to
//        return M.query(on: database)
//            .join(Through.self, on: \M._$id == to.appending(path: \.$id))
//            .filter(Through.self, from.appending(path: \.$id) ~~ Set(ids))
//            .all()
//            .flatMapThrowing
//        {
//            var map: [M.IDValue: [M]] = [:]
//            for to in $0 {
//                let fromID = try to.joined(Through.self)[keyPath: from].id
//                map[fromID, default: []].append(to)
//            }
//            for model in models {
//                model[keyPath: self.relationKey].value = map[model.id!] ?? []
//            }
//        }
//    }
//}
//
//private struct ThroughSelfSiblingsEagerLoader<M Through, Loader>: EagerLoader
//    where M: Model, Through: Model, Loader: EagerLoader, Loader.Model == M
//{
//    let relationKey: KeyPath<M, M.Siblings<M, Through>>
//    let loader: Loader
//
//    func run(models: [M], on database: Database) -> EventLoopFuture<Void> {
//        let throughs = models.flatMap {
//            $0[keyPath: self.relationKey].value!
//        }
//        return self.loader.run(models: throughs, on: database)
//    }
//}
