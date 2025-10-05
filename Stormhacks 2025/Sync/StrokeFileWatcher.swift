// StrokeFileWatcher.swift
import Foundation
import Combine
import Darwin

/// Watches Documents/strokes.json and pushes new strokes to the server.
final class StrokeFileWatcher: ObservableObject {
  private let api: APIClient
  private let fileURL: URL
  private var dirFD: CInt = -1
  private var source: DispatchSourceFileSystemObject?
  private var lastMod: Date? = nil

  /// Call setSurface(uid:) after you create a surface on the server.
  private(set) var surfaceUid: String?

  init(api: APIClient, fileName: String = "strokes.json") {
    self.api = api
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    self.fileURL = docs.appendingPathComponent(fileName)
  }

  func setSurface(uid: String) { self.surfaceUid = uid }

  func start() {
    stop()

    let dirURL = fileURL.deletingLastPathComponent()
    dirFD = open(dirURL.path, O_EVTONLY)
    guard dirFD >= 0 else {
      print("❌ Failed to open directory for watching:", dirURL.path)
      return
    }

    source = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: dirFD,
      eventMask: [.write, .rename, .delete],
      queue: DispatchQueue.global(qos: .utility)
    )

    source?.setEventHandler { [weak self] in
      self?.checkAndSend()
    }

    source?.setCancelHandler { [weak self] in
      if let fd = self?.dirFD, fd >= 0 { close(fd) }
    }

    source?.resume()
    // Initial read (in case the file already exists)
    checkAndSend()
  }

  func stop() {
    source?.cancel()
    source = nil
    if dirFD >= 0 { close(dirFD) }
    dirFD = -1
  }

  // MARK: - Reading / posting

  private func fileModDate() -> Date? {
    guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
          let d = attrs[.modificationDate] as? Date else { return nil }
    return d
  }

  private func checkAndSend() {
    guard let mod = fileModDate() else { return }               // file not there yet
    if let last = lastMod, mod <= last { return }               // no new change
    lastMod = mod

    do {
      let data = try Data(contentsOf: fileURL)

      // Try array of strokes first, then single stroke
      if let strokes = try? JSONDecoder().decode([RawStroke].self, from: data) {
        handle(strokes: strokes)
      } else if let stroke = try? JSONDecoder().decode(RawStroke.self, from: data) {
        handle(strokes: [stroke])
      } else {
        print("⚠️ Unknown strokes.json format")
      }
    } catch {
      print("❌ Failed reading strokes.json:", error.localizedDescription)
    }
  }

  // Shape your Unity JSON to one of these forms:
  // 1) { "color":"Blue", "x":30, "y":50, "z":50, "size":0.015, "ts": 1712345678901 }
  // 2) { "color":"#FF3355", "points":[{"x":..,"y":..,"z":..}, ...], "size":0.015 }
  private struct RawV3: Codable { let x: Double?; let y: Double?; let z: Double? }
  private struct RawStroke: Codable {
    let color: String?
    let x: Double?
    let y: Double?
    let z: Double?
    let size: Double?
    let ts: Int64?
    let points: [RawV3]?
  }

  private func handle(strokes: [RawStroke]) {
    guard let surfaceUid else {
      print("ℹ️ Surface UID not set yet; ignoring strokes until surface is created.")
      return
    }

    for s in strokes {
      if let pts = s.points, !pts.isEmpty {
        // Polyline stroke
        let seq: [V3] = pts.compactMap { p in
          guard let x = p.x, let y = p.y, let z = p.z else { return nil }
          return V3(x: x, y: y, z: z)
        }
        Task {
          do {
            try await api.postPolylineStroke(surfaceUid: surfaceUid,
                                             colorHex: s.color ?? "#FFFFFF",
                                             points: seq,
                                             size: s.size)
            print("✅ Posted polyline stroke (\(seq.count) pts)")
          } catch { print("❌ Post polyline failed:", error.localizedDescription) }
        }
      } else if let x = s.x, let y = s.y, let z = s.z {
        // Single-point stroke
        Task {
          do {
            try await api.postPointStroke(surfaceUid: surfaceUid,
                                          color: s.color ?? "Blue",
                                          x: x, y: y, z: z)
            print("✅ Posted 1-point stroke (\(x),\(y),\(z))")
          } catch { print("❌ Post point failed:", error.localizedDescription) }
        }
      } else {
        print("⚠️ Stroke missing coordinates; skipping.")
      }
    }
  }
}

