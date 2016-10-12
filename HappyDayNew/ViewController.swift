//
//  ViewController.swift
//  HappyDayNew
//
//  Created by Thang Le Tan on 10/12/16.
//  Copyright © 2016 Thang Le Tan. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class ViewController: UIViewController {

    @IBOutlet weak var helpLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func requestPhotoPermission() {
        PHPhotoLibrary.requestAuthorization { (status: PHAuthorizationStatus) in
            DispatchQueue.main.async {
                if status == PHAuthorizationStatus.authorized {
                    self.requestRecordPermission()
                } else {
                    self.helpLabel.text = "Photo Permission was declined, please enable it in Setting and tap Continue again!"
                }
            }
        }
        ////plist key: NSPhotoLibraryUsageDescription
    }
    
    func requestRecordPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { (allowed) in
            DispatchQueue.main.async {
                if allowed {
                    self.requestTranscribePermission()
                } else {
                    self.helpLabel.text = "Audio Record permission was declined, please enable it in Settings and tap continue again"
                }
            }
        }
        //// NSMicrophoneUsageDescription
        
    }
    
    func requestTranscribePermission() {
        SFSpeechRecognizer.requestAuthorization { (status: SFSpeechRecognizerAuthorizationStatus) in
            DispatchQueue.main.async {
                if status == SFSpeechRecognizerAuthorizationStatus.authorized {
                    self.authorizationComplete()
                } else {
                    self.helpLabel.text = "Transcribe Permission was declined, please enable it in Settings and tap countinue again!"
                }
            }
        }
        //// NSSpeechRecognitionUsageDescription
    }
    
    func authorizationComplete() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func requestPermission(_ sender: AnyObject) {
        requestPhotoPermission()
    }
}
