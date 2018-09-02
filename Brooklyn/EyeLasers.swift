//
//  EyeLasers.swift
//  Brooklyn
//
//  Created by William Savary on 2018-08-30.
//  Copyright © 2018 William Savary. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class EyeLasers: SCNNode {
    var startLeftEye: simd_float3?
    var endLeftEye: simd_float3?
    
    var startRightEye: simd_float3?
    var endRightEye: simd_float3?
    
    let leftEyeCylinder: SCNNode
    let rightEyeCylinder: SCNNode
    
    init(geometry: ARSCNFaceGeometry) {
        leftEyeCylinder = SCNNode(geometry: SCNCylinder(radius: 0.005, height: 0.1))
        rightEyeCylinder = SCNNode(geometry: SCNCylinder(radius: 0.005, height: 0.1))
        
        leftEyeCylinder.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        rightEyeCylinder.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        leftEyeCylinder.opacity = 0.5
        rightEyeCylinder.opacity = 0.5
        
        rightEyeCylinder.renderingOrder = 100;
        leftEyeCylinder.renderingOrder = 100;
        rightEyeCylinder.geometry?.firstMaterial?.readsFromDepthBuffer = false;
        leftEyeCylinder.geometry?.firstMaterial?.readsFromDepthBuffer = false;
        
        super.init()
        
        addChildNode(leftEyeCylinder)
        addChildNode(rightEyeCylinder)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        if #available(iOS 12.0, *) {
            let rotate: matrix_float4x4 =
                simd_float4x4(SCNMatrix4Mult(SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0), SCNMatrix4MakeTranslation(0, 0, 0.1/2)))
            
            leftEyeCylinder.simdTransform = anchor.leftEyeTransform * rotate
            rightEyeCylinder.simdTransform = anchor.rightEyeTransform * rotate
        } else {
            
        };
    }
}
