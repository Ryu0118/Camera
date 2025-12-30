//
//  CameraManager+VideoOutput.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

@preconcurrency import AVKit
import MijickTimer
import SwiftUI

@MainActor
class CameraManagerVideoOutput: NSObject {
    private(set) var parent: CameraManager?
    private(set) var output: AVCaptureMovieFileOutput = .init()
    private(set) var timer: MTimer = .init(.camera)
    private(set) var recordingTime: MTime = .zero
    private(set) var firstRecordedFrame: UIImage?

    func setup(parent: CameraManager) throws(MCameraError) {
        self.parent = parent
        try parent.captureSession.add(output: output)
    }
}

// MARK: Reset

extension CameraManagerVideoOutput {
    func reset() {
        timer.reset()
    }
}

// MARK: - CAPTURE VIDEO

// MARK: Toggle

extension CameraManagerVideoOutput {
    func toggleRecording(parent: CameraManager) {
        self.parent = parent
        switch output.isRecording {
        case true: stopRecording(parent: parent)
        case false: startRecording(parent: parent)
        }
    }
}

// MARK: Start Recording

extension CameraManagerVideoOutput {
    private func startRecording(parent: CameraManager) {
        guard let url = prepareUrlForVideoRecording() else { return }

        configureOutput(parent: parent)
        storeLastFrame(parent: parent)
        output.startRecording(to: url, recordingDelegate: self)
        startRecordingTimer(parent: parent)
        parent.objectWillChange.send()
    }
}

extension CameraManagerVideoOutput {
    private func prepareUrlForVideoRecording() -> URL? {
        FileManager.prepareURLForVideoOutput()
    }

    private func configureOutput(parent: CameraManager) {
        guard let connection = output.connection(with: .video), connection.isVideoMirroringSupported else { return }

        connection.isVideoMirrored = parent.attributes.mirrorOutput ? parent.attributes
            .cameraPosition != .front : parent.attributes.cameraPosition == .front
        connection.videoOrientation = parent.attributes.deviceOrientation
    }

    private func storeLastFrame(parent: CameraManager) {
        guard let texture = parent.cameraMetalView.currentDrawable?.texture,
              let ciImage = CIImage(mtlTexture: texture, options: nil),
              let ciContext = parent.cameraMetalView.ciContext,
              let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)
        else { return }

        firstRecordedFrame = UIImage(
            cgImage: cgImage,
            scale: 1.0,
            orientation: parent.attributes.deviceOrientation.toImageOrientation()
        )
    }

    private func startRecordingTimer(parent: CameraManager) { try? timer
        .publish(every: 1) { [self] in
            recordingTime = $0
            self.parent?.objectWillChange.send()
        }
        .start()
    }
}

// MARK: Stop Recording

extension CameraManagerVideoOutput {
    private func stopRecording(parent: CameraManager) {
        presentLastFrame(parent: parent)
        output.stopRecording()
        timer.reset()
    }
}

extension CameraManagerVideoOutput {
    private func presentLastFrame(parent: CameraManager) {
        let firstRecordedFrame = MCameraMedia(data: firstRecordedFrame)
        parent.setCapturedMedia(firstRecordedFrame)
    }
}

// MARK: Receive Data

extension CameraManagerVideoOutput: @preconcurrency AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: (any Error)?
    ) { Task {
        guard let parent else { return }
        let videoURL = try await prepareVideo(
            outputFileURL: outputFileURL,
            cameraFilters: parent.attributes.cameraFilters
        )
        let capturedVideo = MCameraMedia(data: videoURL)

        await Task.sleep(seconds: Animation.duration)
        parent.setCapturedMedia(capturedVideo)
    }}
}

extension CameraManagerVideoOutput {
    private func prepareVideo(outputFileURL: URL, cameraFilters: [CIFilter]) async throws -> URL {
        if cameraFilters.isEmpty { return outputFileURL }

        let asset = AVAsset(url: outputFileURL)
        let videoComposition = try await AVVideoComposition.applyFilters(to: asset) { self.applyFiltersToVideo(
            $0,
            cameraFilters
        ) }
        let fileUrl = FileManager.prepareURLForVideoOutput()
        let exportSession = prepareAssetExportSession(asset, fileUrl, videoComposition)

        try await exportVideo(exportSession, fileUrl)
        return fileUrl ?? outputFileURL
    }
}

extension CameraManagerVideoOutput {
    private nonisolated func applyFiltersToVideo(
        _ request: AVAsynchronousCIImageFilteringRequest,
        _ filters: [CIFilter]
    ) {
        let videoFrame = prepareVideoFrame(request, filters)
        request.finish(with: videoFrame, context: nil)
    }

    private nonisolated func exportVideo(_ exportSession: AVAssetExportSession?, _ fileUrl: URL?) async throws {
        if let fileUrl {
            if #available(iOS 18, *) { try await exportSession?.export(to: fileUrl, as: .mov) }
            else { await exportSession?.export() }
        }
    }
}

extension CameraManagerVideoOutput {
    private nonisolated func prepareVideoFrame(
        _ request: AVAsynchronousCIImageFilteringRequest,
        _ filters: [CIFilter]
    ) -> CIImage { request
        .sourceImage
        .clampedToExtent()
        .applyingFilters(filters)
    }

    private nonisolated func prepareAssetExportSession(
        _ asset: AVAsset,
        _ fileUrl: URL?,
        _ composition: AVVideoComposition?
    ) -> AVAssetExportSession? {
        let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1920x1080)
        export?.outputFileType = .mov
        export?.outputURL = fileUrl
        export?.videoComposition = composition
        return export
    }
}

// MARK: - HELPERS

extension MTimerID {
    fileprivate static let camera: MTimerID = .init(rawValue: "mijick-camera")
}
