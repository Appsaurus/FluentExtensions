//
//  LogMiddleware.swift
//  App
//
//  Created by Brian Strobach on 5/31/19.
//

import Foundation
import VaporExtensions


public enum NetworkLoggerDetailLevel {
    case basic
    case detailed
}

public enum NetworkLoggerDetailElement: CaseIterable {
    case body
    case bodySize
    case cookies
    case headers
}

/// Logs all requests that pass through it.
public class LogMiddleware: AsyncMiddleware {
    static public var detailLevel: NetworkLoggerDetailLevel = .detailed
    public static var detailElements = Set(NetworkLoggerDetailElement.allCases)
    public static var omittedMethods: [HTTPMethod]?
    public static var decodeURLPaths: Bool = true
    
    // Add request filter type
    public typealias RequestFilter = (Request) -> Bool
    
    // Add request filters array
    private var requestFilters: [RequestFilter] = []
    
    public init(){}
    
    // Add method to add filters
    public func addFilter(_ filter: @escaping RequestFilter) {
        requestFilters.append(filter)
    }
    
    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        var shouldLog = true

        // Apply all filters
        for filter in requestFilters {
            if !filter(request) {
                shouldLog = false
                break
            }
        }


        if let omittedMethods = LogMiddleware.omittedMethods, omittedMethods.contains(any: request.method) {
            shouldLog = false
        }
        guard shouldLog else {
            return try await next.respond(to: request)
        }

        let logger = request.logger

        let startTime = Date()
        logger.log(request, whichStartedAt: startTime)

        let response = try await next.respond(to: request)
        logger.log(response, for: request, whichStartedAt: startTime)
        return response
    }
}

fileprivate extension Logger {
    func log(_ request: Request, whichStartedAt startTime: Date) {
        let frame = "📨"
        var logMessage = ""
        switch LogMiddleware.detailLevel {
        case .detailed:
            logMessage = """
            [Begin Request] \(frame)
            [\(Date())]
            \(request.method) \(request.url)
            """
            
            if LogMiddleware.detailElements.contains(.headers) {
                logMessage += """
                
                Headers:
                \(request.headers.debugDescription)
                """
            }
            
            if LogMiddleware.detailElements.contains(.cookies) {
                logMessage += """
                
                Cookies:
                \(request.cookies)
                """
            }
            
            logMessage += "\n[End Request] \(frame)"
        case .basic:
            logMessage = "\(request.method) \(request.url)"
        }

        request.logger.info(logMessage)
    }
    
    func log(_ response: Response, for request: Request, whichStartedAt startTime: Date) {
        let frame = "📦"
        
        var path = request.url.string //request.url.path + (request.url.query.map { "?\($0)" } ?? "")
        if LogMiddleware.decodeURLPaths {
            path = path.urlDecoded
        }
        let requestInfo = "\(request.method.string) \(path)"
        let responseInfo = "\(response.status.code) \(response.status.reasonPhrase)"
        let time = Date().timeIntervalSince(startTime)

        var logMessage = ""
        switch LogMiddleware.detailLevel {
        case .detailed:
            logMessage = """
            [Begin Response] \(frame)
            \(symbol(for: response.status)) \(responseInfo) -> \(requestInfo)
            Duration:
            \(time)
            """
            
            if LogMiddleware.detailElements.contains(.headers) {
                logMessage += """
                
                Headers:
                \(response.headers.debugDescription)
                """
            }
            
            if LogMiddleware.detailElements.contains(.cookies) {
                logMessage += """
                
                Cookies:
                \(response.cookies)
                """
            }
            
            if LogMiddleware.detailElements.contains(.bodySize), let bodyData = request.body.data, let byteCount = bodyData.readableBytes.countableRange.max() {
                logMessage += "\n\nBody Size: \(byteCount) bytes"
            }
            
            if LogMiddleware.detailElements.contains(.body) {
                logMessage += "\n\nBody: \(String(describing: request.body.string))"
            }
            
            logMessage += "\n\n[End Response] \(frame)\n\n"
        case .basic:
            logMessage = "\(symbol(for: response.status)) \(responseInfo) -> \(requestInfo)"
        }
        
        request.logger.info(logMessage)
    }

    func symbol(for status: HTTPResponseStatus) -> String {
        switch status.code {
        case 200..<300: return "✅"
        case 300..<400: return "🔀"
        case 400..<500: return "❌📲"
        case 500..<UInt.max: return "❌"
        default: return "🤔"
        }
    }
}
