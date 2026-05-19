//
//  CameraManager+Photo.swift of MijickCamera
//

import AVKit

// MARK: Set Photo Max Dimensions

extension CameraManager {
    func setPhotoMaxDimensions(_ dimensions: CMVideoDimensions) {
        guard !videoOutput.output.isRecording else { return }

        let previous = attributes.photoMaxDimensions
        let isSame = previous?.width == dimensions.width && previous?.height == dimensions.height
        guard !isSame else { return }

        // The setter throws NSInvalidArgumentException unless the photo output is connected
        // to a video source device with a non-nil activeFormat. Cache the desired dims so a
        // later applier (once session is running) can pick them up, but only attempt the
        // write when the connection is fully established.
        attributes.photoMaxDimensions = dimensions

        guard let connection = photoOutput.output.connection(with: .video),
              let port = connection.inputPorts.first,
              let deviceInput = port.input as? AVCaptureDeviceInput,
              deviceInput.device.activeFormat.formatDescription.dimensions.width > 0
        else { return }

        let supported = deviceInput.device.activeFormat.supportedMaxPhotoDimensions
        guard supported.contains(where: {
            $0.width == dimensions.width && $0.height == dimensions.height
        }) else { return }

        // Batch the write so concurrent sessionPreset changes are observed atomically.
        let avSession = captureSession as? AVCaptureSession
        avSession?.beginConfiguration()
        defer { avSession?.commitConfiguration() }

        photoOutput.output.maxPhotoDimensions = dimensions
    }

    func getSupportedMaxPhotoDimensions() -> [CMVideoDimensions] {
        guard let connection = photoOutput.output.connection(with: .video),
              let port = connection.inputPorts.first,
              let deviceInput = port.input as? AVCaptureDeviceInput
        else { return [] }
        return deviceInput.device.activeFormat.supportedMaxPhotoDimensions
    }
}
