import CloudKitCompilant
import SwiftData

@available(macOS 14, *)
@Model @CloudKitCompilant
class SampleModel {
    var name: String = ""
    var anotherSus: Int?
    var optionalValue: Bool?
    
    init(
        name: String,
        anotherSus: Int,
        optionalValue: Bool? = nil
    ) {
        self.name = name
        self.anotherSus = anotherSus
        self.optionalValue = optionalValue
    }
}
