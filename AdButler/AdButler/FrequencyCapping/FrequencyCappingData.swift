import Foundation

public class FrequencyCappingData : Codable {
    public var placement_id: String
    public var views: String
    public var start: String
    public var expiry: String
    
    public init(placementId: String, views: String, start: String, expiry: String) {
        self.placement_id = placementId
        self.views = views
        self.start = start
        self.expiry = expiry
    }
}
