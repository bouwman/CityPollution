//
//  Constants.swift
//  CityPollution
//
//  Created by Tassilo Bouwman on 12/02/2017.
//  Copyright © 2017 Tassilo Bouwman. All rights reserved.
//

import UIKit

struct Const {
    struct Physics {
        struct Category {
            static let citizens: UInt32 =   0x0000F000
            static let cars: UInt32 =       0x00000F00
            static let houses: UInt32 =     0x000000F0
            static let bounds: UInt32 =     0x0000000F
            static let none: UInt32 =       0x00000000
        }
        struct Collision {
            static let all: UInt32 = Category.citizens | Category.cars | Category.houses | Category.bounds
            static let cars: UInt32 = Category.citizens | Category.cars
            static let none: UInt32 = 0x00000000
        }
    }
    struct Nodes {
        static let healthBar = "health bar"
        static let destination = "destination"
        static let destinationSetZone = "destination set zone"
        static let regenerationZone = "regeneration zone"
        static let house = "house"
        
        struct Houses {
            static let capacity = "capacity"
        }
        struct Layers {
            static let top = "top"
            static let hud = "hud"
            static let aboveCharacters = "above characters"
            static let characters = "characters"
            static let buildings = "buildings"
            static let board = "board"
        }
    }
    struct Citizens {
        static let maxHealth = 400000.0
        static let startHealthPercent = 0.5
        static let increaseFactor = Citizens.maxHealth / 10
        static let increaseFactorFine = 1.0
        static let minEarning = 10.0
        static let yDistanceAfterSpawn = CGFloat(0.0)
        static let healthBarDistance = CGFloat(6.0)
        static let healthBarHeight = CGFloat(5.0)
        static let healthBarColor = UIColor.green
        static let greenRange = 0.8...1.0
        static let yellowRange = 0.3..<0.8
        static let redRange = 0..<0.3
        
        struct TypesFactors {
            static let normal = 2.0
            static let child =  2.3
            static let old =    2.6
            static let asthma = 2.9
        }
    }
}

enum WorldLayer: CGFloat {
    case board = -100, buildings = -25, characters = 0, aboveCharacters = 1000, hud = 1100, top = 1200
}
