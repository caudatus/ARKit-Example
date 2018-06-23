//
//  ViewController.swift
//  05_Floor Detection
//
//  Created by Seo JaeHyeong on 08/05/2018.
//  Copyright © 2018 Seo Jaehyeong. All rights reserved.
//

import UIKit
import ARKit
import CoreMotion

class ViewController: UIViewController, ARSCNViewDelegate {

   @IBOutlet weak var sceneView: ARSCNView!
   
   let configuration = ARWorldTrackingConfiguration()
   let motionManager = CMMotionManager()
   
   var vehicle = SCNPhysicsVehicle()
   var orientation: CGFloat = 0
   var touched: Int = 0
   var accelerationValues = [UIAccelerationValue(0), UIAccelerationValue(0)]
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
      self.sceneView.showsStatistics = true
      self.sceneView.delegate = self
      
      self.configuration.planeDetection = .horizontal
      self.sceneView.session.run(configuration)
      
      setUpAccelerometer()
   }
   
   
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      guard let _ = touches.first else {return}
      self.touched = touches.count
   }
   
   
   override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
      
   }
   
   
   func createPlane(with planeAnchor: ARPlaneAnchor) -> SCNNode {
      let node = SCNNode(geometry:
         SCNPlane(
            width: CGFloat(planeAnchor.extent.x),
            height: CGFloat(planeAnchor.extent.z)))
      
      node.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "concrete")
      node.geometry?.firstMaterial?.isDoubleSided = true
      node.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
      node.position = SCNVector3(
         planeAnchor.center.x,
         planeAnchor.center.y,
         planeAnchor.center.z)
      
      let staticBody = SCNPhysicsBody.static()
      node.physicsBody = staticBody
      return node
   }
   
   
   func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
      guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
      let lavaNode = createPlane(with: planeAnchor)
      
      node.addChildNode(lavaNode)
      print("new flat surface detected, new ARPlaneAnchor Added")
   }
   
   
   func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
      guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
      print("update planeAnchor ")
      
      node.enumerateChildNodes { (childNode, _) in
         childNode.removeFromParentNode()
      }
      let lavaNode = createPlane(with: planeAnchor)
      
      node.addChildNode(lavaNode)
   }
   
   
   func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
      print("node removed..")
      guard let _ = anchor as? ARPlaneAnchor else {return}
      
      node.enumerateChildNodes { (childNode, _) in
         childNode.removeFromParentNode()
      }
   }
   
   
   func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
      self.vehicle.setSteeringAngle(-orientation, forWheelAt: 0)
      self.vehicle.setSteeringAngle(-orientation, forWheelAt: 1)
      
      var engineForce: CGFloat = 0
      var breakingForce: CGFloat = 0
      if touched == 1 {
         engineForce = 5
      } else if touched == 2 {
         engineForce = -5
      } else if touched == 3 {
         breakingForce = 100
      } else {
         engineForce = 0
      }
      
      self.vehicle.applyEngineForce(engineForce, forWheelAt: 2)
      self.vehicle.applyEngineForce(engineForce, forWheelAt: 3)
      self.vehicle.applyBrakingForce(breakingForce, forWheelAt: 2)
      self.vehicle.applyBrakingForce(breakingForce, forWheelAt: 3)
   }
   
   
   @IBAction func addButtonPressed(_ sender: UIButton) {
      guard let pointOfView = sceneView.pointOfView else {return}
      
      let transform = pointOfView.transform
      let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
      let location = SCNVector3(transform.m41, transform.m42, transform.m43)
      let currentPositionOfCamera = orientation + location
      
      let scene = SCNScene(named: "Car-Scene.scn")
      let chassis = (scene?.rootNode.childNode(withName: "chassis", recursively: false))!
      
      let frontLeftWheel = (chassis.childNode(withName: "frontLeftParent", recursively: false))!
      let frontRightWheel = (chassis.childNode(withName: "frontRightParent", recursively: false))!
      let rearLeftWheel = (chassis.childNode(withName: "rearLeftParent", recursively: false))!
      let rearRightWheel = (chassis.childNode(withName: "rearRightParent", recursively: false))!
      
      let vehicleFrontLeftWheel = SCNPhysicsVehicleWheel(node: frontLeftWheel)
      let vehicleFrontRightWheel = SCNPhysicsVehicleWheel(node: frontRightWheel)
      let vehicleRearLeftWheel = SCNPhysicsVehicleWheel(node: rearLeftWheel)
      let vehicleRearRightWheel = SCNPhysicsVehicleWheel(node: rearRightWheel)
      
      chassis.position = currentPositionOfCamera
      
      let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: chassis, options: [SCNPhysicsShape.Option.keepAsCompound: true]))
      chassis.physicsBody = body
      
      self.vehicle = SCNPhysicsVehicle(
         chassisBody: chassis.physicsBody!,
         wheels:
         [vehicleFrontLeftWheel, vehicleFrontRightWheel, vehicleRearLeftWheel, vehicleRearRightWheel])
      self.sceneView.scene.physicsWorld.addBehavior(self.vehicle)
      
      self.sceneView.scene.rootNode.addChildNode(chassis)
   }
   
   
   func setUpAccelerometer() {
      if motionManager.isAccelerometerAvailable {
         motionManager.accelerometerUpdateInterval = 1/60
         motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
            if let error = error {
               print(error.localizedDescription)
               return
            }
            if let acceleration = data?.acceleration {
               self.accelerometerDidChange(acceleration: acceleration)
            }
         }
      } else {
         print("accelerometer not available")
      }
   }
   
   
   func accelerometerDidChange(acceleration: CMAcceleration) {
      accelerationValues[0] = filtered(first: accelerationValues[0], second: acceleration.x)
      accelerationValues[1] = filtered(first: accelerationValues[1], second: acceleration.y)
      if accelerationValues[0] > 0 {
         self.orientation = -CGFloat(accelerationValues[1])
      } else {
         self.orientation = CGFloat(accelerationValues[1])
      }
   }
   
   
   func filtered(first currentAcceleration: Double, second updatedAcceleration: Double) -> Double {
      let kfilteringFactor = 0.5
      return updatedAcceleration * kfilteringFactor + currentAcceleration * (1 - kfilteringFactor)
   }
}


extension Int {
   var degreesToRadians: Double { return Double(self) * .pi/180}
}


func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
   return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}















