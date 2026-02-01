import SwiftData

/**
 This macro parses model declaration at checks if it is ready for CloudKit deploy.
 
 ```swift
 @Model @CloudKitCompilant
 class SampleModel {
     var requiredField: String = ""
     var requiredField2: String // Will error. All required fields must have default values.
     var optional: Int?
     @Relationship(deleteRule: .cascade) var jobs: [Job]?
     @Relationship(deleteRule: .cascade) var jobs2: [Job] // Will error. Relationships must be optional.
     
     ...
 }
 ```
 */
@attached(extension, conformances: Observable, PersistentModel, Sendable)
public macro CloudKitCompilant() = #externalMacro(module: "CloudKitCompilantMacros", type: "CloudKitCompilant")
