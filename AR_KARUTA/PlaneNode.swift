//
//  planeNode.swift
//  AR_KARUTA
//
//  Created by Ayaka on 2021/10/22.
//
import Foundation
import SceneKit
import ARKit

class PlaneNode: SCNNode {
    
    var detection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(anchor: ARPlaneAnchor) {
        super.init()
        

        // 平面のジオメトリを作る
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        // 緑で塗りは半透明（ワイヤーフレームはsceneViewで設定、白色）
        UIColor.gray.setStroke()
        plane.firstMaterial?.diffuse.contents = UIColor.green.withAlphaComponent(0.5)
        plane.widthSegmentCount = 10
        plane.heightSegmentCount = 10
        // ノードのgeometryプロパティに設定する
        geometry = plane
        // X軸回りで90度回転
        transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        // 位置決めする
        position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        
        let bodyShape = SCNPhysicsShape(geometry: geometry!,options:[:])
        physicsBody = SCNPhysicsBody(type: .static, shape: bodyShape)
        //表示してから1.5秒後の処理,ほぼ透明にする
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            plane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.01)
        }
    }
    
    // 位置とサイズを更新する
    func update(anchor: ARPlaneAnchor) {
        // ダウンキャストする
        let plane = geometry as! SCNPlane
        // アンカーから平面の幅、高さを更新する
        plane.width = CGFloat(anchor.extent.x)
        plane.height = CGFloat(anchor.extent.z)
        // 座標を更新する
        position = SCNVector3(anchor.center.x, 0, anchor.center.z)
    }
}
