import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct CloudKitCompilant {}

extension CloudKitCompilant: ExtensionMacro {
    public typealias Error = CloudKitCompilantError
    public typealias Syntax = SwiftSyntax.ExtensionDeclSyntax
    private typealias VarDeclInfo = (name: String, isOptional: Bool, hasDefaultValue: Bool)
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [Syntax] {
        let memberBlock = declaration.memberBlock
        let variables: [VarDeclInfo] = memberBlock.members
            .map({ $0.decl })
            .filter({ $0.is(VariableDeclSyntax.self) })
            .compactMap({ $0.as(VariableDeclSyntax.self)! })
            .map({ (_ decl: VariableDeclSyntax) -> VarDeclInfo? in
                guard let binding = decl.bindings.first else {
                    return nil
                }
                
                // Extract variables from AST
                let name: String = binding.pattern.description
                let hasInitializer: Bool = binding.initializer != nil
                let isOptional: Bool = binding.typeAnnotation?.type.is(OptionalTypeSyntax.self) ?? false
                
                return (name, isOptional, hasInitializer)
            })
            .filter({ tuple in tuple != nil })
            .compactMap({ tuple in tuple! })
        
        // This is a list of fields that contain error.
        var missingDefaultValues: [String] = []
        
        // All properties must be optional, or have default values.
        // So, there is only two options:
        // - Optional variable
        // - Non-optional variable with default value
        for (name, isOptional, hasDefaultValue) in variables {
            // Optional values are valid anyways
            if isOptional { continue }
            // Value is non-optional. In that way it must have default value
            if !hasDefaultValue {
                missingDefaultValues.append(name)
                continue
            }
        }
        
        // Report errors, if they exist
        guard missingDefaultValues.count == 0 else {
            throw Error.missingDefaultValue(modelName: "Sus", properties: missingDefaultValues)
        }
        
        return []
    }
}

public enum CloudKitCompilantError: Error {
    case missingDefaultValue(modelName: String, properties: [String])
}

extension CloudKitCompilantError: DiagnosticMessage {
    public var message: String {
        switch self {
        case .missingDefaultValue(let modelName, let properties):
            return "Model \(modelName) has required fields without default values: \(properties.joined(separator: ", "))"
        }
    }
    
    public var diagnosticID: MessageID {
        switch self {
        case .missingDefaultValue(let modelName, _):
            MessageID(domain: modelName, id: "missing_default_values_on_model")
        }
    }
    
    public var severity: DiagnosticSeverity {
        switch self {
            case .missingDefaultValue: return .error
        }
    }
}

@main
struct CloudKitCompilantPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CloudKitCompilant.self,
    ]
}
