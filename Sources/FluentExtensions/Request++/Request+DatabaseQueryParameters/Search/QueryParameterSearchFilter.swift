//
//  QueryParameterSearchFilter.swift
//  
//
//  Created by Brian Strobach on 9/29/21.
//

//public extension Request {
//    func filterRange<M, C>(for keyPath: KeyPath<M, C>,
//                           at queryKeyPath: Core.BasicKeyRepresentable...) -> ClosedRange<C>? where C: Strideable & Codable {
//        return self.query[ClosedRange<C>.self, at: queryKeyPath]
//    }
//}
public struct QueryParameterSearchFilter {
    var name: String
    var value: String
}

//extension Request {
//    func queryParameterSearchFilter(name: String) throws -> QueryParameterSearchFilter? {
//        let decoder = try make(ContentCoders.self).requireDataDecoder(for: .urlEncodedForm)
//
//        guard let config = query[String.self, at: name] else {
//            return nil
//        }
//    }
//}
