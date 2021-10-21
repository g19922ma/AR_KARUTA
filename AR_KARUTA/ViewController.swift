//
//  ViewController.swift
//  AR_KARUTA
//
//  Created by Ayaka on 2021/10/21.
//

import UIKit
import Vision
import SceneKit
import ARKit


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    var middleTip: CGPoint?
    
    //private var gestureProcessor = HandGestureProcessor()
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self //デリゲートになる
        sceneView.scene = SCNScene() //シーンを作る
        sceneView.debugOptions = .showWireframe //ワイヤーフレーム表示
        sceneView.scene.physicsWorld.gravity = SCNVector3(0, -1.0, 0)//重力の設定
        handPoseRequest.maximumHandCount = 1 //手の数
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()//コンフィグを作る
        configuration.planeDetection = [.horizontal]//平面の検出を有効化
        sceneView.session.run(configuration)//セッションを開始
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //cameraFeedSession?.stopRunning()
        super.viewWillDisappear(animated)
        // セッションを止める
        sceneView.session.pause()
    }
    // シーンビューsceneViewをタップしたら

    @IBAction func tap(_ sender: UITapGestureRecognizer) {
    // タップした2D座標
        let tapLoc = sender.location(in: sceneView)
        // 検知平面とタップ座標のヒットテスト
        let results = sceneView.hitTest(tapLoc, types: .existingPlaneUsingExtent)
        // 検知平面をタップしていたら最前面のヒットデータをresultに入れる
        guard let result = results.first else {
            return
        }
        // ヒットテストの結果からAR空間のワールド座標を取り出す
        let pos = result.worldTransform.columns.3
        // 箱ノードを作る
        let cardNode = CardNode()
        // ノードの高さを求める
        let height = cardNode.boundingBox.max.y - cardNode.boundingBox.min.y
        let y = pos.y + Float(height/2.0) //水平面と箱の底を合わせる
        let unitVec = SCNVector3(1,1,0)
        let forceVec = SCNVector3(2*unitVec.x,2*unitVec.y,2*unitVec.z)
        cardNode.physicsBody?.applyForce(forceVec, asImpulse: true)
        // 位置決めする
        cardNode.position = SCNVector3(pos.x, y, pos.z)
        
        // シーンに箱ノードを追加する
        sceneView.scene.rootNode.addChildNode(cardNode)
    }
    
    //シーンビューsceneViewを長押したら、配置した札を消す

    @IBAction func longTap(_ sender: UILongPressGestureRecognizer) {
    sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                node.removeFromParentNode() }
    }
    
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
