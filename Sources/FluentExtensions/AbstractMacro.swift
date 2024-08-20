////
////  AbstractMacro.swift
////  
////
////  Created by Brian Strobach on 8/13/24.
////
//
//import Foundation
//import SwiftSyntax
//import SwiftSyntaxMacros
//import SwiftSyntaxBuilder
//
//public struct AbstractMacro: PeerMacro {
//    public static func expansion(
//        of node: AttributeSyntax,
//        providingPeersOf declaration: some DeclSyntaxProtocol,
//        in context: some MacroExpansionContext
//    ) throws -> [DeclSyntax] {
//        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
//            throw MacroError.invalidDeclaration("@Abstract can only be applied to functions")
//        }
//        
//        let functionName = funcDecl.name.text
//        let abstractImplementation = try FunctionDeclSyntax("""
//            \(funcDecl.attributes)
//            \(funcDecl.modifiers)
//            \(funcDecl.funcKeyword)
//            \(funcDecl.name)
//            \(funcDecl.genericParameterClause ?? "")
//            \(funcDecl.signature) {
//                assertionFailure("\\(String(describing: self)) is abstract. You must implement \\(functionName)")
//                throw Abort(.notFound)
//            }
//            """)
//        
//        return [DeclSyntax(abstractImplementation)]
//    }
//}
//
//@main
//struct AbstractPlugin: CompilerPlugin {
//    let providingMacros: [Macro.Type] = [
//        AbstractMacro.self
//    ]
//}
