//
//  SoundService.swift
//  Vika
//

import AudioToolbox
import Foundation

final class SoundService {
    static let shared = SoundService()

    private init() {}

    func playNewMessageSound() {
        AudioServicesPlaySystemSound(1003)
    }
}
