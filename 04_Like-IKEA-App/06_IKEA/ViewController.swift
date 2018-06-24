//
//  ViewController.swift
//  06_IKEA
//
//  Created by Seo JaeHyeong on 08/05/2018.
//  Copyright © 2018 Seo Jaehyeong. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate{
   
   @IBOutlet weak var sceneView: ARSCNView!
   @IBOutlet weak var itemCollectionView: UICollectionView!
   @IBOutlet weak var planeDetectedLabel: UILabel!
   
   let configuration = ARWorldTrackingConfiguration()
   let itemsArray: [String] = ["cup", "vase", "boxing", "table"]
   var selectedItem: String?
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      self.itemCollectionView.delegate = self
      self.itemCollectionView.dataSource = self
      self.sceneView.delegate = self
      
      self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
      self.sceneView.autoenablesDefaultLighting = true
      
      self.configuration.planeDetection = .horizontal
      
      self.sceneView.session.run(configuration)
      self.registerGestureReconizer()
   }

   
   func registerGestureReconizer() {
      let tapGestureReconizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
      self.sceneView.addGestureRecognizer(tapGestureReconizer)
      
      let pinchGestureReconizer = UIPinchGestureRecognizer(target: self, action: #selector(pinched(_:)))
      self.sceneView.addGestureRecognizer(pinchGestureReconizer)
      
      let longPressGestureReconizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
      longPressGestureReconizer.minimumPressDuration = 0.1
      self.sceneView.addGestureRecognizer(longPressGestureReconizer)
   }
   
   
   @objc func longPressed(_ sender: UILongPressGestureRecognizer) {
      let scnView = sender.view as! ARSCNView
      let holdLocation = sender.location(in: scnView)
      let hitTest = scnView.hitTest(holdLocation)
      
      if !hitTest.isEmpty {
         let result = hitTest.first!
         
         if sender.state == .began {
            let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 3)
            let forever = SCNAction.repeatForever(rotation)
            result.node.runAction(forever)
         } else if sender.state == .ended {
            result.node.removeAllActions()
         }
      }
   }
   
   
   @objc func pinched(_ sender: UIPinchGestureRecognizer) {
      let scnView = sender.view as! ARSCNView
      let pinchLocation = sender.location(in: scnView)
      let hitTest = scnView.hitTest(pinchLocation)
      
      if let result = hitTest.first {
         let node = result.node
         let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
         node.runAction(pinchAction)
      }
      sender.scale = 1.0
   }
   
   
   @objc func tapped(_ sender: UITapGestureRecognizer) {
      let scnView = sender.view as! ARSCNView
      let tapLocation = sender.location(in: scnView)
      let hitTest = scnView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
      if let result = hitTest.first {
         self.addItem(with: result )
      }
   }
   
   
   func addItem(with result: ARHitTestResult) {
      if let selectedItem = self.selectedItem {
         let scene = SCNScene(named: "Model.scnassets/\(selectedItem).scn")
         let node = scene?.rootNode.childNode(withName: selectedItem, recursively: false)
         let thirdColumn = result.worldTransform.columns.3
         
         node?.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
         if selectedItem == "table" {
            self.centerPivot(for: node! )
         }
         self.sceneView.scene.rootNode.addChildNode(node!)
      }
   }
   
   
   func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
      guard anchor is ARPlaneAnchor else {return}
      
      DispatchQueue.main.async {
         self.planeDetectedLabel.isHidden = false
         DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.planeDetectedLabel.isHidden = true
         }
      }
   }
   
   
   func centerPivot(for node: SCNNode) {
      let min = node.boundingBox.min
      let max = node.boundingBox.max
      
      node.pivot = SCNMatrix4MakeTranslation(
         min.x + (max.x - min.x) / 2,
         min.y + (max.y - min.y) / 2,
         min.z + (max.z - min.z) / 2)
   }

}



extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return itemsArray.count
   }

   
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let cell = itemCollectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! ItemCell
      cell.itemLabel.text = itemsArray[indexPath.row]
      
      return cell
   }
   
   
   func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      let cell = collectionView.cellForItem(at: indexPath)
      
      cell?.backgroundColor = UIColor.green
      self.selectedItem = itemsArray[indexPath.row]
   }
   
   
   func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
      let cell = collectionView.cellForItem(at: indexPath)
      cell?.backgroundColor = UIColor.orange
   }
}



extension Int {
   var degreesToRadians: Double { return Double(self) * .pi/180 }
}
