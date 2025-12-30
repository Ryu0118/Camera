//
//  DefaultCameraScreen+CaptureButton.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import SwiftUI

extension DefaultCameraScreen { struct CaptureButton: View {
    let outputType: CameraOutputType
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action, label: createButtonLabel).buttonStyle(ButtonScaleStyle())
    }
}}
extension DefaultCameraScreen.CaptureButton {
    fileprivate func createButtonLabel() -> some View {
        ZStack {
            createBackground()
            createBorders()
        }.frame(width: 72, height: 72)
    }
}

extension DefaultCameraScreen.CaptureButton {
    fileprivate func createBackground() -> some View {
        RoundedRectangle(cornerRadius: backgroundCornerRadius, style: .continuous)
            .fill(backgroundColor)
            .padding(backgroundPadding)
    }

    fileprivate func createBorders() -> some View {
        Circle().stroke(Color(.mijickBackgroundInverted), lineWidth: 2.5)
    }
}

extension DefaultCameraScreen.CaptureButton {
    fileprivate var backgroundColor: Color { switch outputType {
    case .photo: .init(.mijickBackgroundInverted)
    case .video: .init(.mijickBackgroundRed)
    }}
    fileprivate var backgroundCornerRadius: CGFloat { switch isRecording {
    case true: 6
    case false: 36
    }}
    fileprivate var backgroundPadding: CGFloat { switch isRecording {
    case true: 20
    case false: 4
    }}
}
