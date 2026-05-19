//
//  CameraManager+Photo.swift of MijickCamera
//

import AVKit

// MARK: Set Photo Max Dimensions

extension CameraManager {
    func setPhotoMaxDimensions(_ dimensions: CMVideoDimensions) {
        let previous = attributes.photoMaxDimensions
        let isSame = previous?.width == dimensions.width && previous?.height == dimensions.height
        guard !isSame else { return }

        attributes.photoMaxDimensions = dimensions
        photoOutput.output.maxPhotoDimensions = dimensions
    }

    func getSupportedMaxPhotoDimensions() -> [CMVideoDimensions] {
        getCameraInput()?.device.supportedMaxPhotoDimensions ?? []
    }
}
