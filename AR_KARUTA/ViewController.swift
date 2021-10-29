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
import AVFoundation


class ViewController: UIViewController, ARSCNViewDelegate,ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!

    var synthesizer: AVSpeechSynthesizer!
    var voice: AVSpeechSynthesisVoice!
    
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    var middleTip: CGPoint?
    
    var startDate = Date()
    var endDate = Date()
    
    let utas : [String] = ["春すぎて夏きにけらし白妙の","春のよの夢ばかりなる手枕に","花さそう嵐の庭の雪ならで","花の色はうつりにけりないたづらに"]

    //private var gestureProcessor = HandGestureProcessor()
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self //デリゲートになる
        sceneView.session.delegate = self // ARSessionDelegateデリゲート
        sceneView.scene = SCNScene() //シーンを作る
        sceneView.debugOptions = .showWireframe //ワイヤーフレーム表示
        handPoseRequest.maximumHandCount = 1 //手の数
        
        self.synthesizer = AVSpeechSynthesizer()
        self.voice = AVSpeechSynthesisVoice.init(language: "ja-JP")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()//コンフィグを作る
        configuration.planeDetection = [.horizontal]//平面の検出を有効化
        
        configuration.environmentTexturing = .automatic
        
        //手とARの位置関係を正しくする
        // People Occlusion が使える端末か判定
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            // People Occlusion を使用する
            configuration.frameSemantics = .personSegmentationWithDepth
        }
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
    
    var cardWorldPos = SCNVector3(0,0,0)
    var cardWorldPositions : [SCNVector3] = []
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
        
        cardWorldPos = SCNVector3(pos.x, y, pos.z)
        cardWorldPositions.append(cardWorldPos)
        // 位置決めする
        cardNode.position = cardWorldPos
        // シーンに箱ノードを追加する
        sceneView.scene.rootNode.addChildNode(cardNode)
        
        let randomInt = Int.random(in: 0 ..< utas.count)
        //時間の計測開始
        startDate = Date()
        //読み上げ
        speak(utas[randomInt])
    }
    
    //シーンビューsceneViewを長押したら、配置した札を消す

    @IBAction func longTap(_ sender: UILongPressGestureRecognizer) {
    sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                node.removeFromParentNode() }
        cardWorldPositions.removeAll()
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
    
    // フレーム毎に繰り返し実行する（ARSessionDelegateデリゲートメソッド、ある条件のときに処理をする）
    func session(_ session: ARSession, didUpdate frame: ARFrame){
        
        let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage,
                                            options: [:])
        
        do {
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([handPoseRequest])
            // Continue only when a hand was detected in the frame.
            // Since we set the maximumHandCount property of the request to 1, there will be at most one observation.
            guard let observation = handPoseRequest.results?.first else {
                return
            }
            //中指のPointの取得
            let midPoint = try observation.recognizedPoints(.middleFinger)
            //tip pointの取得
            guard let midTipPoint = midPoint[.middleTip] else {
                return
            }
            //一定の精度を下回るポイントは無視
            guard midTipPoint.confidence > 0.3 else {
                return
            }
            //print(midTipPoint)
            let y_ = 1-midTipPoint.y
            
            let pixel_x = UIScreen.main.bounds.size.width
            let pixel_y = UIScreen.main.bounds.size.height
            
            if (cardWorldPositions.count > 0) {
            hit(x: midTipPoint.x*Double(pixel_x),y: y_*Double(pixel_y))
            }
            
        } catch {
            /*cameraFeedSession?.stopRunning()
            let error = AppError.visionError(error: error)
            DispatchQueue.main.async {
                error.displayInViewController(self)*/
            }
    }
    
    func hit(x :Double, y: Double){
        //print("x,y: ")
        //print(x,y)
        print(cardWorldPositions.count-1)
        for i in 0...cardWorldPositions.count-1 {
            //カードのスクリーン座標
            let cardPos = sceneView.projectPoint(cardWorldPositions[i])
            //print("cardPos: ")
            //print(cardPos)
            
            let X = cardPos.x - Float(x)
            let Y = cardPos.y - Float(y)
            //カードと指の距離
            let distance = sqrt(X*X+Y*Y)
            //print("distance: ")
            //print(distance)
            if(distance < 100) {
                print("hit!",i)
                endDate = Date()
                //時間の表示
                print(endDate.timeIntervalSince(startDate))
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        node.addChildNode(PlaneNode(anchor: planeAnchor))
    }
    func rendrer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        guard let planeNode = node.childNodes.first as? PlaneNode else {
            return
        }
        planeNode.update(anchor:planeAnchor)
    }
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance.init(string: text)
                utterance.voice = self.voice
                self.synthesizer.speak(utterance)
    }
}
