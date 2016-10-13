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
import CoreSpotlight
import MobileCoreServices

class MemoriesViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, AVAudioRecorderDelegate, UISearchBarDelegate {
    
    var memories = [URL]()
    var allMemories = [URL]()
    var activeMemory: URL!
    
    var recordingURL: URL!
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadMemories()
        recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
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
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memory = memories[indexPath.item]
        let fm = FileManager.default
        
        let audio = audioURL(for: memory)
        let transcription = transcriptionURL(for: memory)
        
        
        do {
            if fm.fileExists(atPath: audio.path) {
                try self.audioPlayer = AVAudioPlayer(contentsOf: audio)
                audioPlayer?.play()
            }
            
            if fm.fileExists(atPath: transcription.path) {
                let text = try String(contentsOf: transcription)
                print(text)
            }
            
        } catch let error {
            print("There was an error loading audio: \(error.localizedDescription)")
        }
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterMemories(text: searchText)
    }
    
    var searchQuery: CSSearchQuery?
    
    func filterMemories(text: String) {
        
        guard text.characters.count > 0 else {
            memories = allMemories
            UIView.performWithoutAnimation {
                collectionView?.reloadSections(IndexSet(integer: 1))
            }
            return
        }
        
        var allItems = [CSSearchableItem]()
        
        
        
        self.searchQuery?.cancel()
        
        let queryString = "contentDescription == \"*\(text)*\"c"
        
        searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)
        searchQuery?.foundItemsHandler = { items in
            allItems.append(contentsOf: items)
        }
        
        searchQuery?.completionHandler = { error in
            DispatchQueue.main.async {
                self.activateFilter(matches: allItems)
            }
        }
        
        searchQuery?.start()
        
    }

    func activateFilter(matches: [CSSearchableItem]) {
        
        memories = matches.map { URL(fileURLWithPath: $0.uniqueIdentifier) }
        UIView.performWithoutAnimation {
            self.collectionView?.reloadSections(IndexSet(integer: 1))
        }
    }
    
    
    
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
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
            
            if let cell = sender.view as? MemoryCell {
                if let indexPath = collectionView?.indexPath(for: cell) {
                    activeMemory = memories[indexPath.item]
                    
                    recordMemory()
                }
            }
            
        }
        
        if sender.state == .ended {
            
        }
        
    }
    
    func recordMemory() {
        
        collectionView?.backgroundColor = UIColor(red: 0.8, green: 0, blue: 0, alpha: 0.9)
        
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            // configure for the session for recording and playback through the speaker
            
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            
            try recordingSession.setActive(true)
            // set up high quality recording session
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 4400, AVNumberOfChannelsKey: 2, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            // create audio recording, and assign ourself as delegate
            
            self.audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            
        } catch let error {
            print("Failed to record \(error.localizedDescription)")
            finishRecording(success: false)
        }

        
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func finishRecording(success: Bool) {
        
        collectionView?.backgroundColor = UIColor.darkGray
        audioRecorder?.stop()
        
        if success {
            do {
                let memoryAudio = audioURL(for: activeMemory)
                let fm = FileManager.default
                
                if fm.fileExists(atPath: memoryAudio.path) {
                    try fm.removeItem(at: memoryAudio)
                }
                
                try fm.copyItem(at: recordingURL, to: memoryAudio)
                
                startTranscription(memory: activeMemory)
                

            } catch let error {
                print("Failed to write disk \(error.localizedDescription)")
            }
        }
        
    }
    
    func startTranscription(memory: URL) {
        
        let audio = audioURL(for: memory)
        let transcription = transcriptionURL(for: memory)

        //create new recognizer and point it at our audio
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audio)
        
        
        //start recognition
        recognizer?.recognitionTask(with: request, resultHandler: { (result: SFSpeechRecognitionResult?, error: Error?) in
            guard let result = result else {
                print("There was an error: \(error?.localizedDescription)")
                return
            }
            
            
            
            //if we got final transcription back, we write it to disk
            
            if result.isFinal {
                //pull out the best transcription
                let text = result.bestTranscription.formattedString
                do {
                    try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                    self.indexMemory(memory: memory, text: text)
                } catch let error {
                    print("failed to save transcription! \(error.localizedDescription)")
                }
            
            }
        })
    }
    
    func indexMemory(memory: URL, text: String) {
        //create a basic attribute set
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = "Happy Days New Memory"
        attributeSet.contentDescription = text
        attributeSet.thumbnailURL = thumbnailURL(for: memory)
        
        //wrap it in a searchable item, using the memory full path as its unique identifier
        let item = CSSearchableItem(uniqueIdentifier: memory.path, domainIdentifier: "com.thangcompany", attributeSet: attributeSet)
        
        // make it never expire
        item.expirationDate = Date.distantFuture
        
        
        CSSearchableIndex.default().indexSearchableItems([item]) { (error: Error?) in
            if let error = error {
                print("Indexing error: \(error.localizedDescription)")
                
            } else {
                print("Search Item successfully indexed \(text)")
            }
        }
        
        
    }
    
    //UICollectionViewDelegateFlowLayout -> protocol
    //viewForSupplementaryElementOfKind -> identifier "Header"
    //collectionViewLayout -> size/height for header
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
        allMemories.removeAll()
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else { return }
        
        for file in files {
            let filename = file.lastPathComponent
            if filename.hasSuffix(".thumb") {
                
                let noExtension = filename.replacingOccurrences(of: ".thumb", with: "")
                
                let memoryPath = getDocumentsDirectory().appendingPathComponent(noExtension)
                allMemories.append(memoryPath)
                
            }
        }
        print("files count = \(files.count)")
        
        memories = allMemories
        
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
