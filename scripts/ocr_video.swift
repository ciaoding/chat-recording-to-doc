import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import Vision

struct OCRLine: Encodable {
    let text: String
    let confidence: Float
    let x: Double
    let y: Double
    let w: Double
    let h: Double
}

struct FrameResult: Encodable {
    let frame: Int
    let time: Double
    let image: String
    let width: Int
    let height: Int
    let lines: [OCRLine]
}

func arg(_ name: String, default fallback: String? = nil) -> String {
    if let idx = CommandLine.arguments.firstIndex(of: name), idx + 1 < CommandLine.arguments.count {
        return CommandLine.arguments[idx + 1]
    }
    if let fallback { return fallback }
    fputs("Missing argument \(name)\n", stderr)
    exit(2)
}

let videoPath = arg("--video")
let outDir = arg("--out")
let step = Double(arg("--step", default: "0.5")) ?? 0.5
let languages = arg("--languages", default: "zh-Hans,zh-Hant,en-US")
    .split(separator: ",")
    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { !$0.isEmpty }

try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
let frameDir = URL(fileURLWithPath: outDir).appendingPathComponent("frames")
try FileManager.default.createDirectory(at: frameDir, withIntermediateDirectories: true)
let jsonlURL = URL(fileURLWithPath: outDir).appendingPathComponent("ocr.jsonl")
FileManager.default.createFile(atPath: jsonlURL.path, contents: nil)
let outHandle = try FileHandle(forWritingTo: jsonlURL)
defer { try? outHandle.close() }

let asset = AVURLAsset(url: URL(fileURLWithPath: videoPath))
let durationSeconds = CMTimeGetSeconds(asset.duration)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero

let encoder = JSONEncoder()
encoder.outputFormatting = [.withoutEscapingSlashes]

var frameIndex = 0
var t = 0.0
while t <= durationSeconds + 0.001 {
    autoreleasepool {
        do {
            let requestedTime = CMTime(seconds: t, preferredTimescale: 600)
            var actualTime = CMTime.zero
            let cgImage = try generator.copyCGImage(at: requestedTime, actualTime: &actualTime)
            let width = cgImage.width
            let height = cgImage.height
            let imageName = String(format: "frame_%04d.png", frameIndex)
            let imageURL = frameDir.appendingPathComponent(imageName)
            let dest = CGImageDestinationCreateWithURL(imageURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
            CGImageDestinationAddImage(dest, cgImage, nil)
            CGImageDestinationFinalize(dest)

            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = languages
            request.minimumTextHeight = 0.008
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            let observations = (request.results ?? []).compactMap { obs -> OCRLine? in
                guard let candidate = obs.topCandidates(1).first else { return nil }
                let bb = obs.boundingBox
                return OCRLine(
                    text: candidate.string,
                    confidence: candidate.confidence,
                    x: Double(bb.minX) * Double(width),
                    y: (1.0 - Double(bb.maxY)) * Double(height),
                    w: Double(bb.width) * Double(width),
                    h: Double(bb.height) * Double(height)
                )
            }.sorted {
                if abs($0.y - $1.y) > 8 { return $0.y < $1.y }
                return $0.x < $1.x
            }

            let result = FrameResult(
                frame: frameIndex,
                time: CMTimeGetSeconds(actualTime),
                image: imageURL.path,
                width: width,
                height: height,
                lines: observations
            )
            let data = try encoder.encode(result)
            outHandle.write(data)
            outHandle.write("\n".data(using: .utf8)!)
            print("frame \(frameIndex) @ \(String(format: "%.2f", t))s: \(observations.count) lines")
        } catch {
            fputs("Frame \(frameIndex) at \(t)s failed: \(error)\n", stderr)
        }
    }
    frameIndex += 1
    t += step
}
