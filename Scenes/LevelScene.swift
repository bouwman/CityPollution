//
//  GameScene.swift
//  DrawToMoveExamplee
//
//  Created by Tassilo Bouwman on 06/02/2017.
//  Copyright © 2017 Tassilo Bouwman. All rights reserved.
//

import SpriteKit
import GameplayKit

protocol LevelSceneDelegate {
//    func levelScene(levelScene: LevelScene, did)
}

class LevelScene: BaseScene {
    var lastUpdateTimeInterval: TimeInterval = 0
    var totalTimeInterval: TimeInterval = 0
    
    var entityManager: EntityManager!
    var citizenSpawner: HousesManager!
    var levelManager: LevelManager!
    var tutorialManager: TutorialManager!
    
    var obstacles = [GKEntity]()
    var buildings = [GKEntity]()
    var houses = [HouseEntity]()
    
    lazy var stateMachine: GKStateMachine = GKStateMachine(states: [
        LevelSceneTutorialState(levelScene: self),
        LevelSceneActiveState(levelScene: self),
        LevelScenePauseState(levelScene: self),
        LevelSceneInstructionsState(levelScene: self),
        LevelSceneSuccessState(levelScene: self),
        LevelSceneFailState(levelScene: self)
        ])
    
    var pollutionLabel: SKLabelNode {
        let hud = self.childNode(withName: "hud")
        return hud!.childNode(withName: "pollution") as! SKLabelNode
    }
    var moneyLabel: SKLabelNode {
        let hud = self.childNode(withName: "hud")
        return hud!.childNode(withName: "money") as! SKLabelNode
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        registerForPauseNotifications()
        
        SoundManager.sharedInstance.playMusic(music: .level, inScene: self)
        
        tutorialManager = TutorialManager(levelScene: self)
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        physicsBody?.categoryBitMask = Const.Physics.Category.bounds
        physicsBody?.collisionBitMask = Const.Physics.Collision.none
        
        physicsWorld.contactDelegate = self
        
        let houseCount = children.filter({$0.name == Const.Nodes.house}).count
        let citizensPerHouse = levelManager.configuration.citizenCount / houseCount
        let pollutionPerHouse = levelManager.configuration.pollutionLight / Double(houseCount)
        
        for layerNode in children {
            if let house = layerNode as? HouseNode {
                let entity = HouseEntity(levelManager: levelManager, node: house, maxCapacity: citizensPerHouse, pollutionInput: pollutionPerHouse)
                houses.append(entity)
                buildings.append(entity)
                obstacles.append(entity)
                entityManager.add(entity)
            }
            
            for child in layerNode.children {
                if child.name == "factory" {
                    let entity = FactoryEntity(levelManager: levelManager, node: child as! SKSpriteNode, pollutionInput: levelManager.configuration.pollutionIndustry / 2, upgrades: Upgrade(money: 0, factor: 1.0, spriteName: ""), Upgrade(money: 500, factor: 0.7, spriteName: ""), Upgrade(money: 1000, factor: 0.5, spriteName: ""))
                    entityManager.add(entity)
                } else if let park = child as? ParkNode {
                    let entity = ParkEntity(levelManager: levelManager, node: park)
                    entityManager.add(entity)
                }
            }
        }
        
        citizenSpawner = HousesManager(houses: houses, spawnInterval: levelManager.configuration.citizenSpawnInterval)
        citizenSpawner.dataSource = self
        citizenSpawner.delegate = self
        
        addCar()
        
        stateMachine.enter(LevelSceneTutorialState.self)
    }
        
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // Don't perform any updates if the scene isn't in a view.
        guard view != nil else { return }
        
        // Do not count seconds when was paused
        if wasPaused {
            lastUpdateTimeInterval = currentTime
            wasPaused = false
        }
        
        let deltaTime = currentTime - lastUpdateTimeInterval
        
        lastUpdateTimeInterval = currentTime
        
        // Initial call
        guard deltaTime < 16000.0 else { return }
        
        totalTimeInterval += deltaTime
        
        stateMachine.update(deltaTime: deltaTime)
        
        // spawn citizens
        citizenSpawner.update(totalTime: totalTimeInterval)
        
        // reset city pollution so it can be recalculated each time
        levelManager.cityPollutionAbs = 0
        entityManager.update(deltaTime)
        
        // update hud
        pollutionLabel.text = "Pollution: " + levelManager.cityPollutionAbs.format(".0")
        moneyLabel.text = "Support: " + levelManager.money.format(".0") + " $"
    }
    
    func updateEnvironmentWithPollution(_ pollution: Double) {
        
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        
        SoundManager.sharedInstance.stopMusic()
    }
    
    deinit {
        unregisterForPauseNotifications()
    }
    
    private func addCar() {
        let sprite = SKSpriteNode(color: UIColor.black, size: CGSize(width: 60, height: 30))
        let points = [CGPoint(x: -self.size.width / 2 - sprite.size.width, y: 0), CGPoint(x: 0, y: 0), CGPoint(x: self.size.width / 2 + sprite.size.width, y: 0)]
        let car = CarEntity(levelManager: levelManager, node: sprite, movePoints: points, upgrades: Upgrade(money: 0, factor: 1.0, spriteName: ""), Upgrade(money: 500, factor: 0.7, spriteName: ""), Upgrade(money: 1000, factor: 0.5, spriteName: ""))
        sprite.position = points.first!
        
        entityManager.add(car)
    }
    
    // MARK: Touches
    
    var movingNode: SKNode?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        
        if let node = scene?.atPoint(location) {
            guard node.name != Const.Nodes.contaminatorEmitter else { return }
            let entity = node.entity ?? node.parent?.entity ?? node.parent?.parent?.entity
            if let input = entity?.component(ofType: InputComponent.self) {
                movingNode = node
                input.beginTouchAt(point: location)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        
        if let node = movingNode {
            if let input = node.entity?.component(ofType: InputComponent.self) {
                // TODO: Find old point
                input.moveTouchFrom(fromPoint: location, toPoint: location)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        movingNode = nil
    }
    
    func nodeAt(touches: Set<UITouch>) -> SKNode? {
        guard let touch = touches.first else {
            return nil
        }
        
        let viewTouchLocation = touch.location(in: self)
        let sceneTouchPoint = scene!.convertPoint(fromView: viewTouchLocation)
        
        return scene?.atPoint(sceneTouchPoint)
    }
    
    // MARK: ButtonNodeResponderType
    
    override func buttonTriggered(button: ButtonNode) {
        switch button.buttonIdentifier! {
        case .pause:
            stateMachine.enter(LevelScenePauseState.self)
            SoundManager.sharedInstance.playSound(.click, inScene: self)
        case .resume:
            if tutorialManager.isActive {
                stateMachine.enter(LevelSceneTutorialState.self)
            } else {
                stateMachine.enter(LevelSceneActiveState.self)
            }
            SoundManager.sharedInstance.playSound(.click, inScene: self)
        default:
            super.buttonTriggered(button: button)
        }
    }
    
    // MARK: Pause
    
    private var wasPaused = false
    
    func pause(_ pause: Bool) {
        // Do not count seconds when paused
        wasPaused = !pause

        entityManager.pause(pause)
        isPaused = pause
        // isUserInteractionEnabled = !pause
    }    
}

// MARK: - Notifications

extension LevelScene {
    func registerForPauseNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(LevelScene.gameWillPause), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    func gameWillPause() {
        stateMachine.enter(LevelScenePauseState.self)
    }
    
    func unregisterForPauseNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
}

// MARK: - SKPhysicsContactDelegate

extension LevelScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        let isFirstCitizen = firstBody.categoryBitMask == Const.Physics.Category.citizens
        let isSecondCitizen = secondBody.categoryBitMask == Const.Physics.Category.citizens
        let isFirstCar = firstBody.categoryBitMask == Const.Physics.Category.cars
        let isSecondCar = secondBody.categoryBitMask == Const.Physics.Category.cars
        
        if isFirstCitizen && isSecondCar {
            let citizen = firstBody.node!.entity! as! CitizenEntity
            citizen.delegate?.citizenEnitityDidDie(citizen: citizen)
        } else if isFirstCar && isSecondCitizen {
            let citizen = secondBody.node!.entity! as! CitizenEntity
            citizen.delegate?.citizenEnitityDidDie(citizen: citizen)
        }
    }
}

// MARK: - HousesManagerDataSource

extension LevelScene: HousesManagerDataSource {
    func housesManager(_ housesManager: HousesManager, citizenForHouse house: HouseEntity) -> CitizenEntity {
        let houseSprite = house.renderComponent.node as! HouseNode
        let citizen = CitizenEntity(type: .normal, levelManager: levelManager, possibleDestinations: houses, obstacles: obstacles)
        
        citizen.renderComponent.node.position = houseSprite.entryAreaPosition
        citizen.delegate = levelManager
        
        return citizen
    }
}

// MARK: - HousesManagerDelegate

extension LevelScene: HousesManagerDelegate {
    func housesManager(_ housesManager: HousesManager, didSpawnCitizen citizen: CitizenEntity) {
        // Make citizen move away from door
        guard let pathComponent = citizen.component(ofType: PathComponent.self) else { return }
        
        pathComponent.clearMovingPoints()
        
        let sprite = citizen.renderComponent.node as! SKSpriteNode
        let firstPoint = sprite.position
        let secondPoint = CGPoint(x: firstPoint.x, y: firstPoint.y - sprite.size.height - Const.Citizens.yDistanceAfterSpawn)
        
        pathComponent.addMovingPoint(point: firstPoint)
        pathComponent.addMovingPoint(point: secondPoint)
        
        entityManager.add(citizen)
    }
}

