//
//  CaptureDeviceInput+AVCaptureDeviceInput.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import AVKit

extension AVCaptureDeviceInput: CaptureDeviceInput {
    static func get(mediaType: AVMediaType, position: AVCaptureDevice.Position?) -> Self? {
        let device = { switch mediaType {
        case .audio: return AVCaptureDevice.default(for: .audio)
        case .video where position == .front: return AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .front
            )
        case .video where position == .back:
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [
                    .builtInTripleCamera,
                    .builtInDualWideCamera,
                    .builtInDualCamera,
                    .builtInWideAngleCamera
                ],
                mediaType: .video,
                position: .back
            )
            return discoverySession.devices.first
        default: fatalError()
        }}()

        guard let device, let deviceInput = try? Self(device: device) else { return nil }
        return deviceInput
    }

    static func get(
        mediaType: AVMediaType,
        position: AVCaptureDevice.Position?,
        deviceType: AVCaptureDevice.DeviceType?
    ) -> Self? {
        let device: AVCaptureDevice? = {
            switch mediaType {
            case .audio:
                return AVCaptureDevice.default(for: .audio)
            case .video where position == .front:
                return AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: .front
                )
            case .video where position == .back:
                if let deviceType {
                    return AVCaptureDevice.default(
                        deviceType,
                        for: .video,
                        position: .back
                    )
                } else {
                    let discoverySession = AVCaptureDevice.DiscoverySession(
                        deviceTypes: [
                            .builtInTripleCamera,
                            .builtInDualWideCamera,
                            .builtInDualCamera,
                            .builtInWideAngleCamera
                        ],
                        mediaType: .video,
                        position: .back
                    )
                    return discoverySession.devices.first
                }
            default:
                fatalError()
            }
        }()

        guard let device, let deviceInput = try? Self(device: device) else { return nil }
        return deviceInput
    }
}
