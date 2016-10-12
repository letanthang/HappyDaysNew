//
//  MemoriesViewController.swift
//  HappyDayNew
//
//  Created by Thang Le Tan on 10/12/16.
//  Copyright © 2016 Thang Le Tan. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class MemoriesViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout {
    var memories = [URL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadMemories()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkPermissions()
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 1 {
            return memories.count
        } else {
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as! MemoryCell
        let memory = memories[indexPath.item]
        
        cell.imageView.image = UIImage(contentsOfFile: thumbnailURL(for: memory).path)
        
        if cell.gestureRecognizers == nil {
            let gesture = UILongPressGestureRecognizer(target: self, action: #selector(cellLongPressed))
            gesture.minimumPressDuration = 0.25
            cell.addGestureRecognizer(gesture)
            
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 3
            cell.layer.cornerRadius = 10
            
        }
        
        return cell
        
    }
    
    func cellLongPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            
        }
        
        if sender.state == .ended {
            
        }
        
    }
    
    func recordMemory() {
        
    }
    
    func finishRecording(success: Bool) {
        
    }
    
    func startTranscription(memory: URL) {
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1 {
            return CGSize.zero
        } else {
            return CGSize(width: 0, height: 50)
        }
    }
    
    func imageURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }
    
    func thumbnailURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }
    
    func audioURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }
    
    func transcriptionURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("txt")
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        
        if let possibleImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            saveNewMemory(image: possibleImage)
            loadMemories()
        }
    }
    
    func saveNewMemory(image: UIImage) {
        //create a unique name for this memory
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        
        let imageName = memoryName + ".jpg"
        let thumbnailName = memoryName + ".thumb"
        
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        if let jpegData = UIImageJPEGRepresentation(image, 80) {
            do {
                
                try jpegData.write(to: imagePath, options: [.atomicWrite])
                
                if let thumbnail = resize(image: image, to: 200) {
                    
                    let imagePath = getDocumentsDirectory().appendingPathComponent(thumbnailName)
                    
                    if let jpegData = UIImageJPEGRepresentation(thumbnail, 80) {
                        try jpegData.write(to: imagePath, options: [.atomicWrite])
                    }
                }
                
            } catch let error {
                print("Failed to save to disk: \(error.localizedDescription)")
            }
            
        }
    }
    
    func resize(image: UIImage, to width: CGFloat) -> UIImage? {
        let scale = width / image.size.width
        let height = image.size.height * scale
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    func checkPermissions() {
        let photoAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordAuthorized = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcribeAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        let authorized = photoAuthorized && recordAuthorized && transcribeAuthorized
        
        if authorized == false {
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "FirstRun") {
               present(vc, animated: true, completion: nil)
 
            }
        }
    }
    
    
    
    func addTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.modalPresentationStyle = .formSheet
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        let documentsDirectory = paths[0]
        
        return documentsDirectory
    }
    
    func loadMemories() {
        memories.removeAll()
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else { return }
        
        for file in files {
            let filename = file.lastPathComponent
            if filename.hasSuffix(".thumb") {
                
                let noExtension = filename.replacingOccurrences(of: ".thumb", with: "")
                
                let memoryPath = getDocumentsDirectory().appendingPathComponent(noExtension)
                memories.append(memoryPath)
                
            }
        }
        print("files count = \(files.count)")
        print(memories)
        
        self.collectionView?.reloadSections(IndexSet(integer: 1))
        
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
