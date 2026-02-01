#  CloudKitCompilant macro

_This macro ensures that SwiftData model is CloudKit-compilant._

## Example

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
