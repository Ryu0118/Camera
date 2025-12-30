//
//  DefaultCameraScreen+TopBar.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import SwiftUI

extension DefaultCameraScreen { struct TopBar: View {
    let parent: DefaultCameraScreen

    var body: some View { if isTopBarActive {
        ZStack {
            createCloseButton()
            createCentralView()
            createRightSideView()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, topPadding)
        .padding(.bottom, 8)
        .padding(.horizontal, 20)
        .background(Color(.mijickBackgroundPrimary80))
        .transition(.move(edge: .top))
    }}
}}
extension DefaultCameraScreen.TopBar {
    @ViewBuilder
    fileprivate func createCloseButton() -> some View { if isCloseButtonActive {
        CloseButton(action: parent.closeMCameraAction)
            .frame(maxWidth: .infinity, alignment: .leading)
    }}
    @ViewBuilder
    fileprivate func createCentralView() -> some View { if isCentralViewActive {
        Text(parent.recordingTime.toString())
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(.init(.mijickTextPrimary))
    }}
    @ViewBuilder
    fileprivate func createRightSideView() -> some View { if isRightSideViewActive {
        HStack(spacing: 12) {
            createGridButton()
            createFlipOutputButton()
            createFlashButton()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }}
}

extension DefaultCameraScreen.TopBar {
    @ViewBuilder
    fileprivate func createGridButton() -> some View { if isGridButtonActive {
        DefaultCameraScreen.TopButton(
            icon: gridButtonIcon,
            iconRotationAngle: parent.iconAngle,
            action: changeGridVisibility
        )
    }}
    @ViewBuilder
    fileprivate func createFlipOutputButton() -> some View { if isFlipOutputButtonActive {
        DefaultCameraScreen.TopButton(
            icon: flipButtonIcon,
            iconRotationAngle: parent.iconAngle,
            action: changeMirrorOutput
        )
    }}
    @ViewBuilder
    fileprivate func createFlashButton() -> some View { if isFlashButtonActive {
        DefaultCameraScreen.TopButton(
            icon: flashButtonIcon,
            iconRotationAngle: parent.iconAngle,
            action: changeFlashMode
        )
    }}
}

extension DefaultCameraScreen.TopBar {
    fileprivate func changeGridVisibility() {
        parent.setGridVisibility(!parent.isGridVisible)
    }

    fileprivate func changeMirrorOutput() {
        parent.setMirrorOutput(!parent.isOutputMirrored)
    }

    fileprivate func changeFlashMode() {
        parent.setFlashMode(parent.flashMode.next())
    }
}

extension DefaultCameraScreen.TopBar {
    fileprivate var topPadding: CGFloat { switch parent.deviceOrientation {
    case .portrait, .portraitUpsideDown: 40
    default: 20
    }}
}

extension DefaultCameraScreen.TopBar {
    fileprivate var gridButtonIcon: ImageResource { switch parent.isGridVisible {
    case true: .mijickIconGridOn
    case false: .mijickIconGridOff
    }}
    fileprivate var flipButtonIcon: ImageResource { switch parent.isOutputMirrored {
    case true: .mijickIconFlipOn
    case false: .mijickIconFlipOff
    }}
    fileprivate var flashButtonIcon: ImageResource { switch parent.flashMode {
    case .off: .mijickIconFlashOff
    case .on: .mijickIconFlashOn
    case .auto: .mijickIconFlashAuto
    }}
}

extension DefaultCameraScreen.TopBar {
    fileprivate var isTopBarActive: Bool { parent.cameraManager.captureSession.isRunning }
    fileprivate var isCloseButtonActive: Bool { parent.config.closeButtonAllowed && !parent.isRecording }
    fileprivate var isCentralViewActive: Bool { parent.isRecording }
    fileprivate var isRightSideViewActive: Bool { !parent.isRecording }
    fileprivate var isGridButtonActive: Bool { parent.config.gridButtonAllowed }
    fileprivate var isFlipOutputButtonActive: Bool { parent.config.flipButtonAllowed && parent.cameraPosition == .front
    }

    fileprivate var isFlashButtonActive: Bool {
        parent.config.flashButtonAllowed && parent.hasFlash && parent.cameraOutputType == .photo
    }
}
