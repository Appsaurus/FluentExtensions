//
//  SQLQueryFetcher++.swift
//  
//
//  Created by Brian Strobach on 10/26/21.
//

import SQLKit

//extension SQLQueryFetcher {
//    public func all<A>(decodingValues type: A.Type) -> Future<[A]>
//        where A: Decodable
//    {
//        return all(decoding: [String : A].self).map({ (keyedValues: [[String: A]]) -> ([A]) in
//            return keyedValues.compactMap { $0.values }
//        })
//    }
//}
