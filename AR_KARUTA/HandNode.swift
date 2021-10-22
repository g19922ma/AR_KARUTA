//
//  HandNode.swift
//  AR_KARUTA
//
//  Created by Ayaka on 2021/10/21.
//

import Foundation
import SceneKit
import ARKit

class HandNode: SCNNode {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init() {
        super.init()
        // ジオメトリを作る
        let hand = SCNSphere(radius:0.01)
        // 塗り
        hand.firstMaterial?.diffuse.contents = UIColor.white
        // ノードのgeometryプロパティに設定する
        geometry = hand
        //物理ボディの設定
        let bodyShape = SCNPhysicsShape(geometry: geometry!,options:[:])
        physicsBody = SCNPhysicsBody(type: .kinematic, shape: bodyShape)
        //力や衝突の影響を受けないが、移動すると他のボディに影響を与える
        physicsBody?.isAffectedByGravity = false //重力の影響
        physicsBody?.friction = 2.0 //摩擦
        physicsBody?.restitution = 0.2 //反発力
    }
}
