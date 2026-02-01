import CloudKitCompilant
import SwiftData

@available(macOS 14, *)
@Model
class Job {
    var name: String
    init(name: String) {
        self.name = name
    }
}

@available(macOS 14, *)
@Model @CloudKitCompilant
class SampleModel {
    var name: String = ""
    var anotherSus: Int?
    var optionalValue: Bool = false
    @Relationship(deleteRule: .cascade) var jobs: [Job]?
    
    init(
        name: String,
        anotherSus: Int,
        optionalValue: Bool? = nil
    ) {
        self.name = name
        self.anotherSus = anotherSus
        self.optionalValue = optionalValue ?? false
    }
}
