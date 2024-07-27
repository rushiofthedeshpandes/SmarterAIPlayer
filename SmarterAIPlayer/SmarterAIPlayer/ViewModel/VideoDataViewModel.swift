//
//  VideoDataViewModel.swift
//  SmarterAIPlayer
//
//  Created by Rushikesh Deshpande on 26/07/24.
//

import Foundation

class VideoDataViewModel{
    static func loadJSONData() -> VideoData?{
        guard let url = Bundle.main.url(forResource: "myRecordings", withExtension: "json") else {return nil}
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let funcVideoData = try? decoder.decode(VideoData.self, from: data)
            return funcVideoData
        } catch {
            print("error:\(error)")
            return nil
        }
    }
}
