//
//  VideoRecording.swift
//  SmarterAIPlayer
//
//  Created by Rushikesh Deshpande on 26/07/24.
//

import UIKit
import AVFoundation

struct VideoRecording: Codable {
    let id: Int
    let startTimestamp: TimeInterval
    let endTimestamp: TimeInterval
    let url: String
}

struct VideoData: Codable {
    let recordings: [VideoRecording]
}
