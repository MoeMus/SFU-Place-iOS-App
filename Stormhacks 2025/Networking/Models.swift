import Foundation

// Vectors that match the server JSON
struct V2: Codable { var x: Double; var y: Double }
struct V3: Codable { var x: Double; var y: Double; var z: Double }

struct StrokeData: Codable {
    var uid: String? // filled by server on return
    var color: String? // "Blue" or "#FF3355"
    // For single-point strokes (matches docs):
    var x: Double?; var y: Double?; var z: Double?
    // For polylines:
    var points: [V3]? // optional array of points
    // Optional:
    var size: Double?
    var ts: Int64?
}

// Surface POST.
struct SurfacePayload: Codable {
    var surface_local_id: String
    var center: V3
    var extent: V2
    var normal: V3
    var users: [UserOnSurface]? // optional;
}

struct UserOnSurface: Codable {
    var uid: String
    var name: String
    var strokes: [StrokeData]?
}

// Server responses
struct SurfaceStored: Codable {
    var uid: String? // server uid
    var surface_local_id: String?
    var center: V3?
    var extent: V2?
    var normal: V3?
    var users: [UserOnSurface]?
}
struct SurfaceCreateResponse: Codable { let surface: SurfaceStored }
struct SurfacesAllResponse: Codable { let surfaces: [SurfaceStored] }
struct StrokesResponse: Codable { let strokes: [StrokeData] }

