import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct CloudKitCompilant {}

extension CloudKitCompilant: ExtensionMacro {
    public typealias Error = CloudKitCompilantError
    public typealias Syntax = SwiftSyntax.ExtensionDeclSyntax
    private typealias VarDeclInfo = (name: String, isOptional: Bool, hasDefaultValue: Bool, isRelationship: Bool)
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [Syntax] {
        let coreModelName: String = declaration.as(ClassDeclSyntax.self)!.name.text
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
                let isRelationship: Bool = decl.attributes.contains(where: {
                    // Attribute must be defined
                    guard let attribute = $0.as(AttributeSyntax.self) else { return false }
                    // Check if attribute name is Relationship
                    return attribute.attributeName.description == "Relationship"
                })
                
                return (name, isOptional, hasInitializer, isRelationship)
            })
            .filter({ tuple in tuple != nil })
            .compactMap({ tuple in tuple! })
        
        // This is a list of fields that contain error.
        var missingDefaultValues: [String] = []
        // All relations must be optional. Collect errors as well.
        var nonOptionalRelations: [String] = []
        
        // All properties must be optional, or have default values.
        // So, there is only two options:
        // - Optional variable (isOptional && !isRelationship)
        // - Optional relationship (isOptional && isRelationship)
        // - Non-optional variable with default value
        for (name, isOptional, hasDefaultValue, isRelationship) in variables {            
            // Catch non-optional relationship
            if isRelationship && !isOptional {
                nonOptionalRelations.append(name)
                continue
            }
            // Found optional relationship. Skipping the step.
            if isRelationship && isOptional { continue }
            
            // Catch non-optional value without default value
            if !isRelationship && !isOptional && !hasDefaultValue {
                missingDefaultValues.append(name)
                continue
            }
            // Found non-optinal value, that has default one. Skipping the step.
            if !isRelationship && !isOptional && hasDefaultValue { continue }
            
            // Value is optional. Skipping the step
            if !isRelationship && isOptional { continue }
        }
        
        // Report errors, if they exist
        guard missingDefaultValues.count == 0 else {
            throw Error.missingDefaultValue(modelName: coreModelName, properties: missingDefaultValues)
        }
        guard nonOptionalRelations.count == 0 else {
            throw Error.nonOptionalRelationship(modelName: coreModelName, properties: nonOptionalRelations)
        }
        
        return []
    }
}

public enum CloudKitCompilantError: Error {
    case missingDefaultValue(modelName: String, properties: [String])
    case nonOptionalRelationship(modelName: String, properties: [String])
}

extension CloudKitCompilantError: DiagnosticMessage {
    public var message: String {
        switch self {
        case .missingDefaultValue(let modelName, let properties):
            return "Model \(modelName) has required fields without default values: \(properties.joined(separator: ", "))."
            
        case .nonOptionalRelationship(let modelName, let properties):
            return "Model \(modelName) has non-optional relationships: \(properties.joined(separator: ", ")). All relationships must be optional."
        }
    }
    
    public var diagnosticID: MessageID {
        switch self {
        case .missingDefaultValue(let modelName, _):
            MessageID(domain: modelName, id: "missing_default_values_on_model")
        case .nonOptionalRelationship(let modelName, _):
            MessageID(domain: modelName, id: "have_non_optional_relationships_on_model")
        }
    }
    
    public var severity: DiagnosticSeverity {
        .error
    }
}

@main
struct CloudKitCompilantPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CloudKitCompilant.self,
    ]
}
