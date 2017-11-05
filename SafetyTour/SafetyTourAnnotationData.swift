import UIKit

import MapboxARKit

class SafetyTourAnnotationData: Hashable, Equatable {
    
    var annotation: Annotation
    var identifier: String
    var isAddedToScene = false
        
    init(annotation: Annotation, identifier: String) {
        self.annotation = annotation
        self.identifier = identifier
    }
    
    var hashValue: Int {
        return self.identifier.hashValue
    }
    
    static func == (lhs: SafetyTourAnnotationData, rhs: SafetyTourAnnotationData) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
}
