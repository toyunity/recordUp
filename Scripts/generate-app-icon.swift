#!/usr/bin/env swift
import SwiftUI
import AppKit

// 캔버스 1024×1024, squircle 배경(오렌지→레드 그라데이션) 위에
// 좌측 마이크 → 가운데 음파 리플 → 우측 문서 라인으로 변형되는 디자인.

@available(macOS 14.0, *)
struct AppIconView: View {
    var body: some View {
        ZStack {
            // 1) Squircle 배경 + 그라데이션
            RoundedRectangle(cornerRadius: 1024 * 0.2237, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.00, green: 0.416, blue: 0.239), // #FF6A3D
                            Color(red: 0.878, green: 0.141, blue: 0.369) // #E0245E
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // 상단 미세 하이라이트
                    RoundedRectangle(cornerRadius: 1024 * 0.2237, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.18), Color.white.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 6
                        )
                )

            // 2) 음파 → 문서 흐름 (배경 위, 마이크 아래)
            WaveToLines()

            // 3) 마이크 (좌측, 가장 앞)
            Microphone()
        }
        .frame(width: 1024, height: 1024)
    }
}

// 마이크: 캡슐 그릴 + 스탠드 + 받침 라인
@available(macOS 14.0, *)
struct Microphone: View {
    var body: some View {
        ZStack {
            // 그릴 (캡슐)
            Capsule()
                .fill(Color.white)
                .frame(width: 200, height: 360)
                .position(x: 300, y: 470)

            // 그릴 안쪽 가로 그루브 3개 (살짝 음영)
            ForEach(0..<3) { i in
                Capsule()
                    .fill(Color.white.opacity(0.0))
                    .overlay(
                        Capsule()
                            .stroke(Color(red: 0.878, green: 0.141, blue: 0.369).opacity(0.18),
                                    lineWidth: 6)
                    )
                    .frame(width: 140, height: 6)
                    .position(x: 300, y: CGFloat(380 + i * 60))
            }

            // 스탠드 라이저: 마이크 아래로 곡선 U자 (하단 받침 연결)
            // 두꺼운 라운드 라인으로 단순화
            Path { p in
                p.move(to: CGPoint(x: 180, y: 660))
                p.addLine(to: CGPoint(x: 180, y: 720))
                p.addQuadCurve(to: CGPoint(x: 420, y: 720),
                               control: CGPoint(x: 300, y: 820))
                p.addLine(to: CGPoint(x: 420, y: 660))
            }
            .stroke(Color.white,
                    style: StrokeStyle(lineWidth: 26, lineCap: .round, lineJoin: .round))

            // 수직 스탠드
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .frame(width: 28, height: 90)
                .position(x: 300, y: 820)

            // 받침 라인
            Capsule()
                .fill(Color.white)
                .frame(width: 220, height: 26)
                .position(x: 300, y: 880)
        }
    }
}

// 가운데 음파(원호) → 우측 문서 라인 변환
@available(macOS 14.0, *)
struct WaveToLines: View {
    var body: some View {
        ZStack {
            // 음파 리플 3겹 (마이크 우측에서 발산)
            // 우측 절반의 호로 표현: 동심 호
            ForEach(0..<3) { i in
                let radius = CGFloat(120 + i * 70)
                let alpha = 0.7 - Double(i) * 0.15
                Path { p in
                    p.addArc(
                        center: CGPoint(x: 300, y: 470),
                        radius: radius,
                        startAngle: .degrees(-55),
                        endAngle:   .degrees(55),
                        clockwise: false
                    )
                }
                .stroke(Color.white.opacity(alpha),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round))
            }

            // 문서 라인 6개 (우측 1/3)
            // 위에서 아래로 갈수록 약간 짧아짐, 두께도 살짝 줄어듦
            // 시작 X 좌표는 동일, 끝 X 좌표만 단축
            let lineStartX: CGFloat = 580
            let lineMaxEndX: CGFloat = 920
            let lineCenterY: CGFloat = 470
            let lineSpacing: CGFloat = 78
            let lineCount = 6

            ForEach(0..<lineCount, id: \.self) { i in
                let offsetIndex = CGFloat(i) - CGFloat(lineCount - 1) / 2.0
                let y = lineCenterY + offsetIndex * lineSpacing
                // 길이 변화: 위/아래 단으로 갈수록 살짝 짧아짐
                let shorten: CGFloat = abs(offsetIndex) * 30
                let endX = lineMaxEndX - shorten - (i == lineCount - 1 ? 80 : 0)
                let thickness: CGFloat = 28 - abs(offsetIndex) * 1.5
                let alpha = 1.0 - Double(abs(offsetIndex)) * 0.08

                Capsule()
                    .fill(Color.white.opacity(alpha))
                    .frame(width: endX - lineStartX, height: thickness)
                    .position(x: (lineStartX + endX) / 2, y: y)
            }
        }
    }
}

// MARK: - 렌더링 + 파일 출력

@available(macOS 14.0, *)
@MainActor
func renderIcon() throws {
    let view = AppIconView()
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0  // 1:1 픽셀

    guard let baseImage = renderer.nsImage else {
        throw NSError(domain: "icon", code: 1, userInfo: [NSLocalizedDescriptionKey: "render failed"])
    }

    // 1024 원본을 NSImage로부터 PNG 데이터로 (필요한 사이즈로 각각 리샘플)
    let sizes: [(name: String, px: Int)] = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024)
    ]

    let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0])
    // Scripts/ 의 부모 = 프로젝트 루트
    let projectRoot = scriptURL
        .resolvingSymlinksInPath()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    let outDir = projectRoot
        .appendingPathComponent("Resources")
        .appendingPathComponent("Assets.xcassets")
        .appendingPathComponent("AppIcon.appiconset")

    try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

    // 1024 원본 NSImage를 CGImage로 변환 (고품질 다운스케일을 위해)
    var rect = NSRect(x: 0, y: 0, width: 1024, height: 1024)
    guard let cg1024 = baseImage.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
        throw NSError(domain: "icon", code: 2, userInfo: [NSLocalizedDescriptionKey: "cgImage failed"])
    }

    for (name, px) in sizes {
        let size = CGSize(width: px, height: px)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: px,
            height: px,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw NSError(domain: "icon", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "ctx failed for \(name)"])
        }
        ctx.interpolationQuality = .high
        ctx.draw(cg1024, in: CGRect(origin: .zero, size: size))

        guard let scaled = ctx.makeImage() else {
            throw NSError(domain: "icon", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "scale failed for \(name)"])
        }

        let bitmap = NSBitmapImageRep(cgImage: scaled)
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "icon", code: 5,
                          userInfo: [NSLocalizedDescriptionKey: "png encode failed for \(name)"])
        }

        let url = outDir.appendingPathComponent(name)
        try png.write(to: url)
        FileHandle.standardOutput.write("wrote \(name) (\(px)px)\n".data(using: .utf8)!)
    }

    // Contents.json
    let contentsJson = """
    {
      "images" : [
        { "filename" : "icon_16x16.png",        "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
        { "filename" : "icon_16x16@2x.png",     "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
        { "filename" : "icon_32x32.png",        "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
        { "filename" : "icon_32x32@2x.png",     "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
        { "filename" : "icon_128x128.png",      "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
        { "filename" : "icon_128x128@2x.png",   "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
        { "filename" : "icon_256x256.png",      "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
        { "filename" : "icon_256x256@2x.png",   "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
        { "filename" : "icon_512x512.png",      "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
        { "filename" : "icon_512x512@2x.png",   "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
    let contentsURL = outDir.appendingPathComponent("Contents.json")
    try contentsJson.data(using: .utf8)!.write(to: contentsURL)
    FileHandle.standardOutput.write("wrote Contents.json\n".data(using: .utf8)!)
}

if #available(macOS 14.0, *) {
    do {
        try MainActor.assumeIsolated {
            try renderIcon()
        }
    } catch {
        FileHandle.standardError.write("error: \(error.localizedDescription)\n".data(using: .utf8)!)
        exit(1)
    }
} else {
    FileHandle.standardError.write("requires macOS 14.0+\n".data(using: .utf8)!)
    exit(1)
}
