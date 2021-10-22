//
//  CardNode.swift
//  AR_KARUTA
//
//  Created by Ayaka on 2021/10/21.
//

import Foundation
import SceneKit
import ARKit

class CardNode: SCNNode {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init() {
        super.init()
        // ジオメトリを作る
        let card = SCNBox(width: 0.052, height: 0.002, length: 0.073, chamferRadius: 0.005)
        // 塗り
        card.firstMaterial?.diffuse.contents = UIColor.green
        // ノードのgeometryプロパティに設定する
        geometry = card
        //物理ボディの設定
        let bodyShape = SCNPhysicsShape(geometry: geometry!,options:[:])
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: bodyShape)
        physicsBody?.isAffectedByGravity = false //重力の影響
        physicsBody?.friction = 2.0 //摩擦
        physicsBody?.restitution = 0.2 //反発力
    }
}
