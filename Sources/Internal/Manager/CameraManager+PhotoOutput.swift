//
//  CameraManager+PhotoOutput.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import AVKit

@MainActor
class CameraManagerPhotoOutput: NSObject {
    private(set) var parent: CameraManager?
    private(set) var output: AVCapturePhotoOutput = .init()

    func setup(parent: CameraManager) throws(MCameraError) {
        self.parent = parent
        try parent.captureSession.add(output: output)
        output.maxPhotoQualityPrioritization = .quality
        // Do NOT assign `output.maxPhotoDimensions` here. At this point the output is added to
        // the session but its video connection to the source device may not yet be established,
        // so the setter throws:
        //   "May not be set until connected to a video source device with a non-nil activeFormat"
        // The dimensions are (re)applied later via `setPhotoMaxDimensions(_:)`, which the host
        // app calls once the camera screen appears, after the session is running.
    }
}

// MARK: - CAPTURE PHOTO

// MARK: Capture

extension CameraManagerPhotoOutput {
    func capture(parent: CameraManager) {
        self.parent = parent

        // Ensure output has an active video connection (setup was called)
        guard output.connection(with: .video) != nil else { return }

        let settings = getPhotoOutputSettings(parent: parent)

        configureOutput(parent: parent)
        output.capturePhoto(with: settings, delegate: self)
        parent.cameraMetalView.performImageCaptureAnimation()
    }
}

extension CameraManagerPhotoOutput {
    private func getPhotoOutputSettings(parent: CameraManager) -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = parent.attributes.flashMode.toDeviceFlashMode()
        settings.photoQualityPrioritization = .quality
        // Re-clamp against the device's *current* activeFormat. The cached attribute can become
        // stale after a camera-position switch (e.g. WideAngle -> TripleCamera) because the new
        // virtual device's activeFormat reports a different supportedMaxPhotoDimensions set.
        // Setting an unsupported value here raises NSInvalidArgumentException.
        if let dims = parent.attributes.photoMaxDimensions {
            let supported = parent.getSupportedMaxPhotoDimensions()
            if supported.contains(where: { $0.width == dims.width && $0.height == dims.height }) {
                settings.maxPhotoDimensions = dims
            }
        }
        return settings
    }

    private func configureOutput(parent: CameraManager) {
        guard let connection = output.connection(with: .video) else { return }

        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = parent.attributes.mirrorOutput ? parent.attributes
                .cameraPosition != .front : parent.attributes.cameraPosition == .front
        }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = parent.attributes.deviceOrientation
        }
    }
}

// MARK: Receive Data

extension CameraManagerPhotoOutput: @preconcurrency AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        guard let parent else { return }

        if let error {
            parent.attributes.error = .photoCaptureFailed(error)
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let ciImage = CIImage(data: imageData)
        else {
            parent.attributes.error = .photoCaptureProducedNoData
            return
        }

        let capturedCIImage = prepareCIImage(ciImage, parent.attributes.cameraFilters)
        let capturedCGImage = prepareCGImage(capturedCIImage)
        let capturedUIImage = prepareUIImage(cgImage: capturedCGImage, parent: parent)
        let capturedMedia = MCameraMedia(data: capturedUIImage)

        parent.setCapturedMedia(capturedMedia)
    }
}

extension CameraManagerPhotoOutput {
    private func prepareCIImage(_ ciImage: CIImage, _ filters: [CIFilter]) -> CIImage {
        ciImage.applyingFilters(filters)
    }

    private func prepareCGImage(_ ciImage: CIImage) -> CGImage? {
        CIContext().createCGImage(ciImage, from: ciImage.extent)
    }

    private func prepareUIImage(cgImage: CGImage?, parent: CameraManager) -> UIImage? {
        guard let cgImage else { return nil }

        let frameOrientation = getFixedFrameOrientation(parent: parent)
        let orientation = UIImage.Orientation(frameOrientation)
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
        return uiImage
    }
}

extension CameraManagerPhotoOutput {
    private func getFixedFrameOrientation(parent: CameraManager) -> CGImagePropertyOrientation {
        guard UIDevice.current.orientation != parent.attributes.deviceOrientation.toDeviceOrientation()
        else { return parent.attributes.frameOrientation }

        return switch (parent.attributes.deviceOrientation, parent.attributes.cameraPosition) {
        case (.portrait, .front): .left
        case (.portrait, .back): .right
        case (.landscapeLeft, .back): .down
        case (.landscapeRight, .back): .up
        case (.landscapeLeft, .front) where parent.attributes.mirrorOutput: .up
        case (.landscapeLeft, .front): .upMirrored
        case (.landscapeRight, .front) where parent.attributes.mirrorOutput: .down
        case (.landscapeRight, .front): .downMirrored
        default: .right
        }
    }
}
