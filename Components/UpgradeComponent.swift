//
//  UpgradeComponent.swift
//  CityPollution
//
//  Created by Tassilo Bouwman on 09/03/2017.
//  Copyright © 2017 Tassilo Bouwman. All rights reserved.
//

import GameplayKit

struct Upgrade: Equatable {
    let money: Double
    let factor: Double
    let spriteName: String
    
    static func ==(lhs: Upgrade, rhs: Upgrade) -> Bool {
        return lhs.money == rhs.money && lhs.factor == rhs.factor && lhs.spriteName == rhs.spriteName
    }
}

class UpgradeComponent: GKComponent {
    let upgrades: [Upgrade]
    let levelManager: LevelManager
    
    var currentUpgrade: Upgrade
    
    private lazy var labelNode: SKLabelNode = {
        guard let node = self.entity?.component(ofType: GKSKNodeComponent.self)?.node as? SKSpriteNode else { fatalError("upgrade") }
        let label = SKLabelNode(fontNamed: Const.Fonts.bold)
        let background = SKSpriteNode(imageNamed: "upgrade background")
        let position = CGPoint(x: -node.size.width / 2 + 21, y: node.size.height / 2 - 1)
        
        background.position = position
        background.name = Const.Nodes.upgrade
        background.zPosition = WorldLayer.characters.rawValue + 1

        label.zPosition = WorldLayer.characters.rawValue + 2
        label.position.x = 18
        label.position.y = -1
        label.fontSize = Const.Fonts.Size.small
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        
        if node is CarNode {
            background.position.y = position.y + 8
        }
        
        node.addChild(background)
        background.addChild(label)
        
        self.backgroundNode = background
        
        return label
    }()
    
    var backgroundNode: SKSpriteNode!
    
    init(levelManager: LevelManager, upgrades: [Upgrade]) {
        self.upgrades = upgrades
        self.currentUpgrade = upgrades.first!
        self.levelManager = levelManager
        
        super.init()
        
        applyCurrentUpgrade()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        if currentUpgrade != upgrades.last {
            labelNode.text = upgrades[upgrades.index(of: currentUpgrade)! + 1].money.format(".0")
        } else {
            if labelNode.parent?.parent != nil {
                labelNode.parent?.removeFromParent()
            }
        }
    }
    
    func tryToUpgrade() {
        for (i, upgrade) in upgrades.enumerated() {
            if upgrade == currentUpgrade, i != upgrades.count - 1 {
                let possibleUpgrade = upgrades[i + 1]
                if levelManager.money >= possibleUpgrade.money {
                    currentUpgrade = possibleUpgrade
                    applyCurrentUpgrade()
                    SoundManager.sharedInstance.playSound(.click)
                }
                return
            }
        }
    }
    
    private func applyCurrentUpgrade() {
        levelManager.money -= currentUpgrade.money
        if let contaminator = entity?.component(ofType: ContaminatorComponent.self) {
            contaminator.factor = currentUpgrade.factor
        }
        if let sprite = entity?.component(ofType: GKSKNodeComponent.self)?.node as? SKSpriteNode {
            if currentUpgrade.spriteName.isEmpty {
                sprite.color = UIColor(white: CGFloat(currentUpgrade.factor), alpha: 1.0)
            } else {
                sprite.texture = SKTexture(imageNamed: currentUpgrade.spriteName)
            }
        }
        if let event = entity?.component(ofType: EventComponent.self) {
            event.nextEventToTrigger = .upgrade(currentUpgrade.money)
        }
    }
}
