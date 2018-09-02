//
//  ViewController.swift
//  Brooklyn
//
//  Created by William Savary on 2018-08-30.
//  Copyright © 2018 William Savary. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var sceneView = ARSCNView()
    
    let phoneWidth = 375 * 3
    let phoneHeight = 812 * 3
    
    var positions: Array<simd_float2> = Array()
    let numPositions = 10
    
    var eyeLasers: EyeLasers?
    var eyeRaycastData: RaycastData?
    var virtualPhoneNode = SCNNode()
    
    var target: UIView = UIView()
    
    var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.green
        return SCNNode(geometry: screenGeometry)
    }()
    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(sceneView)
        sceneView.anchor(top: view.topAnchor, right: view.rightAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, paddingTop: 0, paddingRight: 0, paddingBottom: 0, paddingLeft: 0, width: view.frame.width, height: view.frame.height)

        target.backgroundColor = UIColor.red
        target.frame = CGRect(x: view.frame.midX, y: view.frame.midY, width: 25, height: 25)
        target.layer.cornerRadius = 12.5
        sceneView.addSubview(target)
        
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.showsStatistics = true
        
        guard let device = sceneView.device else { return }
        guard let eyeGeometry = ARSCNFaceGeometry(device: device) else { return }
        eyeLasers = EyeLasers(geometry: eyeGeometry)
        eyeRaycastData = RaycastData(geometry: eyeGeometry)
        sceneView.scene.rootNode.addChildNode(eyeLasers!)
        sceneView.scene.rootNode.addChildNode(eyeRaycastData!)
        
        virtualPhoneNode.geometry?.firstMaterial?.isDoubleSided = true
        virtualPhoneNode.addChildNode(virtualScreenNode)
        self.sceneView.scene.rootNode.addChildNode(virtualPhoneNode)
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        return node
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform user of interruption
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        eyeLasers?.transform = node.transform
        eyeRaycastData?.transform = node.transform
        eyeLasers?.update(withFaceAnchor: faceAnchor)
        eyeRaycastData?.update(withFaceAnchor: faceAnchor)
        
        
        let blinkRight = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
        let blinkLeft = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0
        if blinkRight > 0.6 {
            DispatchQueue.main.async {
                self.target.backgroundColor = .green
            }
            
        }
        if blinkLeft > 0.6 {
            DispatchQueue.main.async {
                self.target.backgroundColor = .red
            }
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView else { return }
        virtualPhoneNode.transform = pointOfView.transform
        
        let options: [String: Any] = [SCNHitTestOption.backFaceCulling.rawValue: false,
                                      SCNHitTestOption.searchMode.rawValue: 1,
                                      SCNHitTestOption.ignoreChildNodes.rawValue: false,
                                      SCNHitTestOption.ignoreHiddenNodes.rawValue: false]
        
        guard let data = self.eyeRaycastData else { return }
        let hitTestLeftEye = virtualPhoneNode.hitTestWithSegment(from: virtualPhoneNode.convertPosition(data.leftEye.worldPosition, from: nil), to: virtualPhoneNode.convertPosition(data.leftEyeEnd.worldPosition, from: nil), options: options)
        
        let hitTestRightEye = virtualPhoneNode.hitTestWithSegment(from: virtualPhoneNode.convertPosition(data.rightEye.worldPosition, from: nil), to: virtualPhoneNode.convertPosition(data.rightEyeEnd.worldPosition, from: nil), options: options)
        
        if (hitTestLeftEye.count > 0 && hitTestRightEye.count > 0) {
            var coords = screenPositionFromHittest(hitTestLeftEye[0], hitTestRightEye[0])
            
            DispatchQueue.main.async {
                self.target.center = CGPoint.init(x: CGFloat(coords.x), y: CGFloat(coords.y))
            }
        }
        
    }
    
    func screenPositionFromHittest(_ result1: SCNHitTestResult, _ result2: SCNHitTestResult) -> simd_float2 {
        // Will have to change when face recognition comes out for iPad
        let iPhoneXPointSize = simd_float2(375, 812)
        let iPhoneXMeterSize = simd_float2(0.0623908297, 0.135096943231532)
        
        let xLC = ((result1.localCoordinates.x + result2.localCoordinates.x) / 2.0)
        var x = xLC / (iPhoneXMeterSize.x / 2.0) * iPhoneXPointSize.x
        
        let yLC = -((result1.localCoordinates.y + result2.localCoordinates.y) / 2.0)
        var y = yLC / (iPhoneXMeterSize.y / 2.0) * iPhoneXPointSize.y + 312
        
        x = Float.maximum(Float.minimum(x, iPhoneXPointSize.x - 1), 0)
        y = Float.maximum(Float.minimum(y, iPhoneXPointSize.y - 1), 0)
        
        positions.append(simd_float2(x,y))
        if positions.count > numPositions {
            positions.removeFirst()
        }
        
        var total = simd_float2(0,0)
        for pos in positions {
            total.x += pos.x
            total.y += pos.y
        }
        
        total.x /= Float(positions.count)
        total.y /= Float(positions.count)
        
        return total
    }
    
    

}
