//
//  TutorialManager.swift
//  CityPollution
//
//  Created by Tassilo Bouwman on 13/03/2017.
//  Copyright © 2017 Tassilo Bouwman. All rights reserved.
//

import Foundation

class TutorialManager: NSObject {
    var levelScene: LevelScene
    var currentStep: String?
    
    var isActive = true {
        didSet {
            if isActive == false {
                NotificationCenter.default.removeObserver(self)
            }
        }
    }
    
    init(levelScene: LevelScene) {
        self.levelScene = levelScene
        super.init()
        NotificationCenter.default.add(self, selector: #selector(TutorialManager.didReceiveSpawnCitizenNotification), notification: .spawnCitizen)
    }
    
    func didReceiveSpawnCitizenNotification() {
        NotificationCenter.default.remove(self, forNotification: .spawnCitizen)
        
        // Listen for next step
        NotificationCenter.default.add(self, selector: #selector(TutorialManager.didReceiveArriveAtParkNotification), notification: .arriveAtPark)
        
        currentStep = "The citizen wants some fresh air. Move him to the park. The air quality is really bad though. Make sure your citizens do not die on their way to the park."
        levelScene.stateMachine.enter(LevelSceneInstructionsState.self)
    }
    
    func didReceiveArriveAtParkNotification() {
        NotificationCenter.default.remove(self, forNotification: .arriveAtPark)
        
        // Listen for next step
        NotificationCenter.default.add(self, selector: #selector(TutorialManager.didReceiveTurnOnLightNotification), notification: .turnOnLight)
        NotificationCenter.default.add(self, selector: #selector(TutorialManager.didReceiveReachMaxHealthNotification), notification: .reachMaxHealth)
        
        currentStep = "Wait for the citizen to regenerate."
        levelScene.stateMachine.enter(LevelSceneInstructionsState.self)
    }
    
    func didReceiveTurnOnLightNotification() {
        NotificationCenter.default.remove(self, forNotification: .turnOnLight)
        
        currentStep = "Oh, someone left their light on. Turn it off to reduce the pollution."
        levelScene.stateMachine.enter(LevelSceneInstructionsState.self)
    }
    
    func didReceiveReachMaxHealthNotification() {
        NotificationCenter.default.remove(self, forNotification: .reachMaxHealth)
        
        // Listen for next step
        NotificationCenter.default.add(self, selector: #selector(TutorialManager.didReceiveArriveAtHouseNotification), notification: .arriveAtHouse)
        
        currentStep = "Move back to earn money"
        levelScene.stateMachine.enter(LevelSceneInstructionsState.self)
    }
    
    func didReceiveArriveAtHouseNotification() {
        isActive = false
        
        NotificationCenter.default.remove(self, forNotification: .arriveAtHouse)
        
        currentStep = "Great! You earned some support. When you have earned enough support you can upgrade the factory to reduce pollution."
        levelScene.stateMachine.enter(LevelSceneInstructionsState.self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
