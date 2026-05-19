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

        let supported = getSupportedMaxPhotoDimensions()
        guard supported.contains(where: {
            $0.width == dimensions.width && $0.height == dimensions.height
        }) else { return }

        attributes.photoMaxDimensions = dimensions
        photoOutput.output.maxPhotoDimensions = dimensions
    }

    func getSupportedMaxPhotoDimensions() -> [CMVideoDimensions] {
        getCameraInput()?.device.supportedMaxPhotoDimensions ?? []
    }
}
