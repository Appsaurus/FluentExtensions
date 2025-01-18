//
//  XCTApplicationTester+Response.swift
//
//
//  Created by Brian Strobach on 9/5/24.
//

import XCTVapor

extension XCTApplicationTester {
    public func testPut<C: Content>(
        _ path: String,
        headers: HTTPHeaders = [:],
        body: C? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> XCTHTTPResponse {
        return try self.test(.PUT, path, headers:headers, body: nil, file: file, line: line) { req in
            if let body {
                try req.content.encode(body)
            }
        }
    }
    public func test(
        _ method: HTTPMethod,
        _ path: String,
        headers: HTTPHeaders = [:],
        body: ByteBuffer? = nil,
        file: StaticString = #file,
        line: UInt = #line,
        beforeRequest: (inout XCTHTTPRequest) throws -> () = { _ in }
    ) throws -> XCTHTTPResponse {
        var response: XCTHTTPResponse?
        try self.test(method, path, headers:headers, body: body, file: file, line: line, beforeRequest: beforeRequest) { response = $0 }
        if let response {
            return response
        }
        throw Abort(.expectationFailed)
    }
}
