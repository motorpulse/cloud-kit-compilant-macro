import SwiftData

#warning("TODO: Update comment below")
/**
 */
@attached(extension, conformances: Observable, PersistentModel, Sendable)
public macro CloudKitCompilant() = #externalMacro(module: "CloudKitCompilantMacros", type: "CloudKitCompilant")
