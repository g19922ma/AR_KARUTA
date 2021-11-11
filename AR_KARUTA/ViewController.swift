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
    
    @IBOutlet weak var label: UILabel!
    var message: String = ""
    
    var synthesizer: AVSpeechSynthesizer!
    var voice: AVSpeechSynthesisVoice!
    
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    var middleTip: CGPoint?
    
    var startDate = Date()
    var endDate = Date()
    let hyoji : [String] = ["はるす","はるの","はなさ","はなの"]
    
    let utas : [String] = ["春すぎて〜、夏きにけらし、白妙の","春のよの〜、夢ばかりなる、手枕に","花さそう〜、嵐の庭の、雪ならで","花の色わ〜、うつりにけりな、いたづらに"]
    
    var okCardNum : [Int] = [0,1,2,3]
    var okReadNum : [Int] = [0,1,2,3]
    var haichiCard: [Int] = []
    var take : [Int] = [0,0,0,0]//0空札1読まれていない2読まれた
    
    var soundPlayer = AVAudioPlayer()
    let soundPath = Bundle.main.bundleURL.appendingPathComponent("takeSound.mp3")

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
        
        message = "タップして札を置いてください"
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
            message = "平面をタップしてください"
            return
        }
        message = "タップして札を置いてください"
        if(okCardNum.count<3){message = "ボタンを押してスタートしてください"}
        // ヒットテストの結果からAR空間のワールド座標を取り出す
        let pos = result.worldTransform.columns.3
        //札一覧
        let cards : [String] = ["art.scnassets/02はるす.png","art.scnassets/67はるの.png","art.scnassets/96はなさ.png","art.scnassets/09はなの.png"]
        if(okCardNum.count > 0) {
            //どの札を配置するか
            let cardNum = okCardNum[Int.random(in: 0 ..< okCardNum.count)]
            //同じ札を配置しない
            okCardNum.removeAll(where: {$0 == cardNum})
            
            // 箱ノードを作る
            let cardNode = CardNode(card: cards[cardNum])
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
            haichiCard.append(cardNum)
            take[cardNum] = 1
        } else {
            message = "これ以上札を置くことができません"
        }
    }
    
    //シーンビューsceneViewを長押したら、配置した札を消す

    @IBAction func longTap(_ sender: UILongPressGestureRecognizer) {
    sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                node.removeFromParentNode() }
        cardWorldPositions.removeAll()
        okCardNum += [0,1,2,3]
        okReadNum += [0,1,2,3]
        touchCount=0
        pictureCount = 0
        for i in 0...take.count-1 {
            take[i] = 0
        }
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
            label.text = message
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

    @IBOutlet weak var viewTime: UILabel!
    var touchCount = 0
    var pictureCount = 0
    func hit(x :Double, y: Double){
        pictureCount += 1
        if(pictureCount < 15){return}
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
            if (distance < 100) {
                touchCount += 1
            }
            var time = 0.00
            if(readNum<100 && pictureCount>1 && distance < 100 && take[readNum] != 2) {
                
                do{
                    soundPlayer = try AVAudioPlayer(contentsOf: soundPath,fileTypeHint: nil)
                    soundPlayer.play()
                } catch {
                    print("エラー")
                }
                
                
                print("hit!",i)
                endDate = Date()
                //時間の表示
                time = ceil(Double(endDate.timeIntervalSince(startDate))*1000)/1000
                //取った札があっているかどうか
                print(haichiCard[i],readNum)
                let s1 = String(hyoji[haichiCard[i]])
                let s3 = String(hyoji[readNum])
                if(time>1){
                    if(haichiCard[i] == readNum){
                        let s2 = String(time)
                      message = s1+"を"+s2+"秒で取った！"
                        take[readNum] = 2
                        viewTime.text = "取り！"+s2+"秒"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.viewTime.text = ""
                        }
                    } else {
                        message = "それは「"+s3+"」じゃないよ！"
                        viewTime.text = "お手つき！"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.viewTime.text = ""
                        }
                    }
                }

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
        utterance.rate = 0.38 //話す速さ 0.0~1.0
        utterance.pitchMultiplier = 1.0 //声の高さ 0.5~2.0
                self.synthesizer.speak(utterance)
    }
    
    var speakedCount = 0
    var readNum = 100
    @IBOutlet weak var startButton: UIButton!
    @IBAction func tapStartButton(_ sender: UIButton) {
        message = "ゲーム開始"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [self] in
            if(okReadNum.count>0){
                readNum = self.okReadNum[Int.random(in: 0 ..< okReadNum.count)]
                //同じ歌を読まない
                self.okReadNum.removeAll(where: {$0 == readNum})
                pictureCount = 0
                //時間の計測開始
                self.startDate = Date()
                //読み上げ
                self.speak(self.utas[readNum])
                self.speakedCount += 1
                print(readNum)
            } else {
                message = "全ての歌を読み終わりました"
                self.performSegue(withIdentifier: "result", sender: nil)
            }
        }
    }
}
