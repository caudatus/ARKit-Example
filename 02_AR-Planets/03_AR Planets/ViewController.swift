//
//  ViewController.swift
//  03_AR Planets
//
//  Created by Seo JaeHyeong on 05/05/2018.
//  Copyright © 2018 Seo Jaehyeong. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

   @IBOutlet weak var sceneView: ARSCNView!
   let configuration = ARWorldTrackingConfiguration()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
      self.sceneView.autoenablesDefaultLighting = true
      self.sceneView.delegate = self
      
      self.sceneView.session.run(configuration)
   }
   
   
   override func viewDidAppear(_ animated: Bool) {
      let sun = SCNNode(geometry: SCNSphere(radius: 0.35))
      sun.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Sun")
      sun.position = SCNVector3(0, 0, -1)
      self.sceneView.scene.rootNode.addChildNode(sun)
      
      let earthParent = SCNNode()
      earthParent.position = SCNVector3(0, 0, -1)
      self.sceneView.scene.rootNode.addChildNode(earthParent)
      
      let venusParent = SCNNode()
      venusParent.position = SCNVector3(0, 0, -1)
      self.sceneView.scene.rootNode.addChildNode(venusParent)
      
      let moonParent = SCNNode()
      moonParent.position = SCNVector3(1.2, 0, 0)
      earthParent.addChildNode(moonParent)
      
      let earth = planet(geometry: SCNSphere(radius: 0.2),
                         diffuse: UIImage(named: "Earth")!,
                         specular: UIImage(named: "Earth Specular")!,
                         emission: UIImage(named: "Earth Emission")!,
                         normal: UIImage(named: "Earth Normal")!,
                         position: SCNVector3(1.2, 0, 0))
      earthParent.addChildNode(earth)
      
      let venus = planet(geometry: SCNSphere(radius: 0.1),
                         diffuse: UIImage(named: "Venus")!,
                         specular: nil,
                         emission: UIImage(named: "Venus Atmosphere")!,
                         normal: nil,
                         position: SCNVector3(0.7, 0, 0))
      venusParent.addChildNode(venus)
      
      let moon = planet(geometry: SCNSphere(radius: 0.05),
                        diffuse: UIImage(named: "Moon")!,
                        specular: nil,
                        emission: nil,
                        normal: nil,
                        position: SCNVector3(0.3, 0.2, 0))
      moonParent.addChildNode(moon)
      
      let sunRotation = rotation(time: 20)
      sun.runAction(sunRotation)
      
      let earthRotation = rotation(time: 15)
      earth.runAction(earthRotation)
      
      let earthParentRotation = rotation(time: 40)
      earthParent.runAction(earthParentRotation)
      
      let venusParentRotation = rotation(time: 30)
      venusParent.runAction(venusParentRotation)
      
      let moonParentRotation = rotation(time: 3)
      moonParent.runAction(moonParentRotation)
   }

   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
   }
   
   
   func planet(geometry: SCNGeometry, diffuse: UIImage, specular: UIImage?, emission: UIImage?, normal: UIImage?, position: SCNVector3) -> SCNNode {
      
      let planet = SCNNode(geometry: geometry)
      planet.geometry?.firstMaterial?.diffuse.contents = diffuse
      planet.geometry?.firstMaterial?.specular.contents = specular
      planet.geometry?.firstMaterial?.emission.contents = emission
      planet.geometry?.firstMaterial?.normal.contents = normal
      planet.position = position
      
      return planet
   }
   
   
   func rotation(time: TimeInterval) -> SCNAction {
      let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: time)
      let forever = SCNAction.repeatForever(rotation)
      
      return forever
   }


}




extension Int {
   var degreesToRadians: Double { return Double(self) * .pi/180}
}
