//
//  ViewController.swift
//  WhatFlower
//
//  Created by Aaryan Aggarwal on 16/02/2019.
//  Copyright © 2019 Aaryan Aggarwal. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    let imagePicked = UIImagePickerController()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicked.delegate = self
        imagePicked.sourceType = .camera
        imagePicked.allowsEditing = true
        
        label.numberOfLines = 0
        
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            imageView.image = userPickedImage
            
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert UIImage into CIImage")
            }
        
            detect(image: ciImage)
            
        }
        
        imagePicked.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(image: CIImage){
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            
            fatalError("Loading CoreML Model Failed.")
            
        }
         let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation
                
                else {
                
                fatalError("Model failed to process image.")
            }
            
            //print(classification)
            
            self.navigationItem.title = classification.identifier.capitalized

            self.requestInfo(flowerName: classification.identifier)
            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]

        
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess{
                
                print("Got the wikipedia info")
//                print(JSON(response.result.value))
                
                let flowerJSON : JSON = JSON(response.result.value!)
                
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
//                print(flowerDescription)
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                
                self.label.text = flowerDescription
            }
        }
    }
    
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicked, animated: true, completion: nil)
        
    }
    
}

