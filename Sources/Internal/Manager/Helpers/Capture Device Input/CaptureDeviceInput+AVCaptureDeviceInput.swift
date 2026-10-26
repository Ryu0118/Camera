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
        case .video where position == .front: return frontCamera()
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
                return frontCamera()
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

    // On iPhone Duo both front cameras are ultra-wide; the Virtual Front Camera, which switches
    // automatically when the device opens or closes, is found by searching front Wide and Ultra Wide types.
    // Wide comes first, so devices whose only front camera is Wide keep selecting the same device.
    // A virtual device is preferred so the physical inner/outer cameras are not picked on iPhone Duo.
    private static func frontCamera() -> AVCaptureDevice? {
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: .front
        ).devices
        return devices.first(where: \.isVirtualDevice) ?? devices.first
    }
}
