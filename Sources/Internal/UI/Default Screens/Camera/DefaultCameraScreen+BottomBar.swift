//
//  DefaultCameraScreen+BottomBar.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import SwiftUI

extension DefaultCameraScreen { struct BottomBar: View {
    let parent: DefaultCameraScreen

    var body: some View {
        ZStack(alignment: .top) {
            createOutputTypeSwitch()
            createButtons()
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 44)
        .padding(.horizontal, 32)
    }
}}
extension DefaultCameraScreen.BottomBar {
    @ViewBuilder
    fileprivate func createOutputTypeSwitch() -> some View { if isOutputTypeSwitchActive {
        DefaultCameraScreen.CameraOutputSwitch(parent: parent)
            .offset(y: -80)
    }}
    fileprivate func createButtons() -> some View {
        ZStack {
            createLightButton()
            createCaptureButton()
            createChangeCameraPositionButton()
        }.frame(height: 72)
    }
}

extension DefaultCameraScreen.BottomBar {
    @ViewBuilder
    fileprivate func createLightButton() -> some View { if isLightButtonActive {
        BottomButton(
            icon: .mijickIconLight,
            iconColor: lightButtonIconColor,
            backgroundColor: .init(.mijickBackgroundSecondary),
            rotationAngle: parent.iconAngle,
            action: changeLightMode
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.scale)
    }}
    @ViewBuilder
    fileprivate func createCaptureButton() -> some View { if isCaptureButtonActive {
        DefaultCameraScreen.CaptureButton(
            outputType: parent.cameraOutputType,
            isRecording: parent.isRecording,
            action: parent.captureOutput
        )
        .transition(.scale)
    }}
    @ViewBuilder
    fileprivate func createChangeCameraPositionButton()
        -> some View
    { if isChangeCameraPositionButtonActive {
        BottomButton(
            icon: .mijickIconChangeCamera,
            iconColor: changeCameraPositionButtonIconColor,
            backgroundColor: .init(.mijickBackgroundSecondary),
            rotationAngle: parent.iconAngle,
            action: changeCameraPosition
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
        .transition(.scale)
    }}
}

extension DefaultCameraScreen.BottomBar {
    fileprivate func changeLightMode() {
        do { try parent.setLightMode(parent.lightMode.next()) }
        catch {}
    }

    fileprivate func changeCameraPosition() { Task {
        do { try await parent.setCameraPosition(parent.cameraPosition.next()) }
        catch {}
    }}
}

extension DefaultCameraScreen.BottomBar {
    fileprivate var lightButtonIconColor: Color { switch parent.lightMode {
    case .on: .init(.mijickBackgroundYellow)
    case .off: .init(.mijickBackgroundInverted)
    }}
    fileprivate var changeCameraPositionButtonIconColor: Color { .init(.mijickBackgroundInverted) }
}

extension DefaultCameraScreen.BottomBar {
    fileprivate var isOutputTypeSwitchActive: Bool {
        parent.config.cameraOutputSwitchAllowed && parent.cameraManager.captureSession.isRunning && !parent.isRecording
    }

    fileprivate var isLightButtonActive: Bool {
        parent.config.lightButtonAllowed && parent.hasLight && parent.cameraManager.captureSession.isRunning && !parent
            .isRecording
    }

    fileprivate var isCaptureButtonActive: Bool {
        parent.config.captureButtonAllowed && parent.cameraManager.captureSession.isRunning
    }

    fileprivate var isChangeCameraPositionButtonActive: Bool {
        parent.config.cameraPositionButtonAllowed && parent.cameraManager.captureSession.isRunning && !parent
            .isRecording
    }
}
