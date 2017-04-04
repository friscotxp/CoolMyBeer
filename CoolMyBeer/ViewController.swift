//
//  ViewController.swift
//  CoolMyBeer
//
//  Created by Francisco Palma on 02-04-17.
//  Copyright © 2017 Francisco Palma. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var tituloPrincipal: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var barraEnfriar: UISlider!
    
    var resumeTapped = false;
    var player: AVAudioPlayer?
    var isRunning = false;
    var enfriar = Float(0);
    
    var seconds = 10 //2700 This variable will hold a starting value of seconds. It could be any amount above 0.
    var timer = Timer();
    var isTimerRunning = false; //This will be used to make sure only one timer is created at a time.
    
    let audioSession = AVAudioSession.sharedInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tituloPrincipal.text = "Coloca la cerveza en el congelador!";
        if (enfriar == 0.0){
            enfriar = Float(1);
        }else{
            barraEnfriar.value = enfriar;
        }
    }
    
    func setSegundos(_ sec:Int){
        seconds = sec;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }

    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                     selector: (#selector(ViewController.updateTimer)),
                                     userInfo: nil, repeats: true)
    }
    
    func updateTimer() {
        if seconds < 1 {
            if timer.isValid { playSound(play: true); }
            timer.invalidate();
            //Send alert to indicate "time's up!"
        } else {
            seconds -= 1
            timerLabel.text = timeString(time: TimeInterval(seconds))
        }
    }
    
    func playSound(play: DarwinBoolean) {
        let url = Bundle.main.url(forResource: "BOMB_SIREN", withExtension: "wav")!
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord);
            try audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker);
        } catch {
            print("Error: \(error)")
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            if play.boolValue {
                guard let player = player else { return }
                player.prepareToPlay();
                player.play();
            }else{
                player?.stop();
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    @IBOutlet weak var actionEnfriar: UIButton!
    @IBAction func actionEnviar(_ sender: UIButton) {
        if isRunning == false {
            actionEnfriar.setTitle("Detener", for: .normal);
            isRunning = true;
            runTimer();
        }else{
            isRunning = false;
            playSound(play: false);
            timer.invalidate();
            actionEnfriar.setTitle("Enfriar", for: .normal);
        }
        print("isRunnind: \(isRunning)")
    }
    
    @IBAction func barraEnfriar(_ sender: UISlider) {
        if (sender.value < 0.5){
            enfriar = 0;
            sender.value = 0;
            setSegundos(1800);
        }else
            if (sender.value >= 0.5 && sender.value < 1.5){
                enfriar = 1;
                sender.value = 1;
                setSegundos(2700);
        }else
                if (sender.value > 1.5){
                    enfriar = 2;
                    sender.value = 2;
                    setSegundos(3600);
        }
        print(enfriar);
        //enfriar = Float(sender.value);
    }
}

