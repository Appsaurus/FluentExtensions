//
//  LogMiddleware.swift
//  App
//
//  Created by Brian Strobach on 5/31/19.
//

import Foundation
import VaporExtensions

/// Specifies the level of detail for network request/response logging
public enum NetworkLoggerDetailLevel {
    /// Basic logging includes only the HTTP method and URL
    case basic
    /// Detailed logging includes headers, cookies, body size, and request/response bodies
    case detailed
}

/// Elements that can be included in detailed network logging output
public enum NetworkLoggerDetailElement: CaseIterable {
    /// Request/response body content
    case body
    /// Size of the request/response body in bytes
    case bodySize
    /// Cookie information
    case cookies
    /// HTTP headers
    case headers
}

/// A middleware that provides configurable logging of HTTP requests and responses.
///
/// `LogMiddleware` allows filtering and customization of network logging output,
/// supporting different detail levels and selective logging of request/response elements.
///
/// Example usage:
/// ```swift
/// let middleware = LogMiddleware()
/// middleware.addFilter { request in
///     request.url.path.hasPrefix("/api")
/// }
/// ```
public class LogMiddleware: AsyncMiddleware {
    /// The level of detail to include in logs
    static public var detailLevel: NetworkLoggerDetailLevel = .detailed
    
    /// Specific elements to include when using detailed logging
    public static var detailElements = Set(NetworkLoggerDetailElement.allCases)
    
    /// HTTP methods to exclude from logging
    public static var omittedMethods: [HTTPMethod]?
    
    /// Whether to URL decode paths before logging
    public static var decodeURLPaths: Bool = true
    
    /// A closure type that determines whether a request should be logged
    public typealias RequestFilter = (Request) -> Bool
    
    /// Collection of filters that determine which requests get logged
    private var requestFilters: [RequestFilter] = []
    
    /// Creates a new LogMiddleware instance
    public init(){}
    
    /// Adds a filter that determines whether a request should be logged
    /// - Parameter filter: A closure that returns true if the request should be logged
    public func addFilter(_ filter: @escaping RequestFilter) {
        requestFilters.append(filter)
    }
    
    /// Processes the incoming request and logs relevant information based on configuration
    /// - Parameters:
    ///   - request: The incoming HTTP request
    ///   - next: The next responder in the chain
    /// - Returns: The HTTP response
    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        var shouldLog = true

        // Apply all request filters
        for filter in requestFilters {
            if !filter(request) {
                shouldLog = false
                break
            }
        }

        // Check if the request method is in the omitted list
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

// MARK: - Logger Extensions

fileprivate extension Logger {
    /// Logs information about an HTTP request
    /// - Parameters:
    ///   - request: The request to log
    ///   - startTime: When the request processing began
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
    
    /// Logs information about an HTTP response
    /// - Parameters:
    ///   - response: The response to log
    ///   - request: The original request
    ///   - startTime: When the request processing began
    func log(_ response: Response, for request: Request, whichStartedAt startTime: Date) {
        let frame = "📦"
        
        var path = request.url.string
        if LogMiddleware.decodeURLPaths {
            path = path.urlDecoded
        }
        let requestInfo = "\(request.method.rawValue) \(path)"
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

    /// Returns an emoji symbol representing the HTTP response status
    /// - Parameter status: The HTTP response status
    /// - Returns: An emoji representing the status category
    func symbol(for status: HTTPResponseStatus) -> String {
        switch status.code {
        case 200..<300: return "✅" // Success
        case 300..<400: return "🔀" // Redirection
        case 400..<500: return "❌📲" // Client Error
        case 500..<UInt.max: return "❌" // Server Error
        default: return "🤔" // Unknown
        }
    }
}
