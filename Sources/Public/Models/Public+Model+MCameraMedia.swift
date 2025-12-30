//
//  Public+Model+MCameraMedia.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import SwiftUI

// MARK: Getters

extension MCameraMedia {
    /**
     Gets the image from the media object.
     */
    public func getImage() -> UIImage? { image }

    /**
     Gets the video URL from the media object.
     */
    public func getVideo() -> URL? { video }
}
