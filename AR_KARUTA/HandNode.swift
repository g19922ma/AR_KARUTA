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
    }
}
