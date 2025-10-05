import Foundation

// Server /register response
struct RegisteredUser: Codable {
    let name: String
    let email: String
    let uid: String
}

final class APIClient {
    let serverBase: URL
    let firebaseApiKey: String

    private(set) var idToken: String?
    private(set) var userId: String?
    var displayName: String = "iOS"

    init(serverBase: String, firebaseApiKey: String) {
        self.serverBase = URL(string: serverBase)!
        self.firebaseApiKey = firebaseApiKey
    }

    // MARK: - Firebase sign-in (REST)
    struct SignInBody: Codable { let email: String; let password: String; let returnSecureToken = true }
    struct SignInResp: Codable { let idToken: String; let localId: String; let displayName: String? }

    @discardableResult
    func signIn(email: String, password: String) async throws -> (token: String, uid: String) {
        let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=\(firebaseApiKey)")!
        var req = URLRequest(url: url); req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(SignInBody(email: email, password: password))

        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.throwIfBad(resp, data: data)

        let r = try JSONDecoder().decode(SignInResp.self, from: data)
        idToken = r.idToken; userId = r.localId; displayName = r.displayName ?? displayName
        return (r.idToken, r.localId)
    }

    /// Optional helper if you ever sign in via Firebase SDK and want to inject the token.
    func setAuth(idToken: String, uid: String) {
        self.idToken = idToken
        self.userId = uid
    }

    // MARK: - Create Account (server: POST /register)
    struct RegisterBody: Codable { let name: String; let email: String; let password: String }

    /// Registers a user on the server (Firestore) – unauthenticated route.
    func register(name: String, email: String, password: String) async throws -> RegisteredUser {
        var req = URLRequest(url: serverBase.appendingPathComponent("register"))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(RegisterBody(name: name, email: email, password: password))

        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.throwIfBad(resp, data: data)
        return try JSONDecoder().decode(RegisteredUser.self, from: data)
    }

    /// Convenience: register then sign in (so you have idToken ready for protected routes).
    func registerAndSignIn(name: String, email: String, password: String) async throws -> (RegisteredUser, String) {
        let user = try await register(name: name, email: email, password: password)
        let (_, uid) = try await signIn(email: email, password: password) // sets idToken + userId
        return (user, uid)
    }

    // MARK: - Surfaces
    /// POST /surface — server pushes a new record and (currently) may return without uid.
    /// We then call /surface/all and match via surface_local_id to get the uid.
    func createSurface(_ s: SurfacePayload) async throws -> String {
        guard let idToken else { throw SimpleError("Not signed in") }
        var req = URLRequest(url: serverBase.appendingPathComponent("surface"))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(s)

        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.throwIfBad(resp, data: data)

        // Try to parse uid if server includes it
        if let maybeWrapped = try? JSONDecoder().decode(SurfaceCreateResponse.self, from: data),
           let uid = maybeWrapped.surface.uid, !uid.isEmpty {
            return uid
        }

        // Fallback: fetch all and match by our surface_local_id
        guard let uid = try await findSurfaceUid(byLocalId: s.surface_local_id) else {
            throw SimpleError("Surface created but uid not found in /surface/all")
        }
        return uid
    }

    /// GET /surface/all, find the record with our local id
    func findSurfaceUid(byLocalId localId: String) async throws -> String? {
        guard let idToken else { throw SimpleError("Not signed in") }
        var req = URLRequest(url: serverBase.appendingPathComponent("surface/all"))
        req.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.throwIfBad(resp, data: data)

        let decoded = try JSONDecoder().decode(SurfacesAllResponse.self, from: data)
        return decoded.surfaces.first(where: { $0.surface_local_id == localId })?.uid
    }

    // MARK: - Strokes
    /// POST /surface/strokes/user — send either a single-point or polyline stroke
    func postStroke(surfaceUid: String, stroke: StrokeData, userName: String? = nil) async throws {
        guard let idToken, let userId else { throw SimpleError("Not signed in") }
        struct Body: Codable { let surface_id: String; let user_id: String; let name: String; let stroke: StrokeData }
        let body = Body(surface_id: surfaceUid, user_id: userId, name: userName ?? displayName, stroke: stroke)

        var req = URLRequest(url: serverBase.appendingPathComponent("surface/strokes/user"))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.throwIfBad(resp, data: data)
        _ = data
    }

    /// Convenience: single-point stroke (matches docs exactly)
    func postPointStroke(surfaceUid: String, color: String, x: Double, y: Double, z: Double) async throws {
        let s = StrokeData(uid: nil, color: color, x: x, y: y, z: z, points: nil, size: nil, ts: Self.nowMs())
        try await postStroke(surfaceUid: surfaceUid, stroke: s)
    }

    /// Convenience: polyline stroke (stored as array of points)
    func postPolylineStroke(surfaceUid: String, colorHex: String, points: [V3], size: Double? = nil) async throws {
        let s = StrokeData(uid: nil, color: colorHex, x: nil, y: nil, z: nil, points: points, size: size, ts: Self.nowMs())
        try await postStroke(surfaceUid: surfaceUid, stroke: s)
    }

    // MARK: - Read back (optional)
    func getUserStrokes(surfaceUid: String, userId: String? = nil) async throws -> [StrokeData] {
        guard let idToken else { throw SimpleError("Not signed in") }
        let uid = userId ?? self.userId ?? ""
        var req = URLRequest(url: serverBase.appendingPathComponent("surface/\(surfaceUid)/user/\(uid)/strokes"))
        req.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.throwIfBad(resp, data: data)
        let decoded = try JSONDecoder().decode(StrokesResponse.self, from: data)
        return decoded.strokes
    }

    // MARK: - Utils
    static func throwIfBad(_ resp: URLResponse, data: Data) throws {
        if let h = resp as? HTTPURLResponse, !(200...299).contains(h.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            throw SimpleError("HTTP \(h.statusCode): \(body)")
        }
    }
    static func nowMs() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000) }
    struct SimpleError: LocalizedError { let message: String; init(_ m: String){message=m}; var errorDescription: String?{message} }
}

