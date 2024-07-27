//
//  Helper.swift
//  SmarterAIPlayer
//
//  Created by Rushikesh Deshpande on 26/07/24.
//

import Foundation

class Helper{
    static func getStringConversion(for time: Double) -> String?{
        let mins =  (time / 60).truncatingRemainder(dividingBy: 60)
        let secs = time.truncatingRemainder(dividingBy: 60)
        let timeformatter = NumberFormatter()
        timeformatter.minimumIntegerDigits = 2
        timeformatter.minimumFractionDigits = 0
        timeformatter.roundingMode = .down
        guard let minsStr = timeformatter.string(from: NSNumber(value: mins)),
                let secsStr = timeformatter.string(from: NSNumber(value: secs)) else {
            return nil
        }
        return "\(minsStr):\(secsStr)"
  }
    
}
