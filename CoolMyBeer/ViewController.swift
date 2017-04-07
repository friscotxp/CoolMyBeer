//
//  ViewController.swift
//  CoolMyBeer
//
//  Created by Francisco Palma on 02-04-17.
//  Copyright © 2017 Francisco Palma. All rights reserved.
//

import UIKit
import AVFoundation
import UserNotifications

class ViewController: UIViewController {

    @IBOutlet weak var tituloPrincipal: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var barraEnfriar: UISlider!
    
    var backgroundUpdateTask: UIBackgroundTaskIdentifier!
    
    var resumeTapped = false;
    var player: AVAudioPlayer?
    var isRunning = false;
    var enfriar = Float(0);
    var nowBackground = Date();
    
    var seconds         = 2700; //2700 This variable will hold a starting value of seconds.
    var secondsOriginal = 2700;
    
    var timer = Timer();
    var isTimerRunning = false; //This will be used to make sure only one timer is created at a time.
    var isGrantedNotificationAccess:Bool = false
    
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
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert,.sound,.badge],
            completionHandler: { (granted,error) in
                self.isGrantedNotificationAccess = granted
        }
        )
    }
    
    
    //UIApplication.sharedApplication().backgroundTimeRemaining
    
    func setSegundos(_ sec:Int){
        seconds = sec;
        secondsOriginal  = sec;
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
        print("runTimer: INICIANDO \(seconds)");

        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                          selector: (#selector(ViewController.updateTimer)),
                                          userInfo: nil, repeats: true);
    }
    
    func appMovedToBackground() {
        print("App moved to background!")
        DispatchQueue.global(qos: .background).async {
            print("This is run on the background queue, registering Notifiction!!")
            self.sendNotification(self.seconds);
            //self.sendNotification(10);
            DispatchQueue.main.async {
                //print("This is run on the main queue, after the previous code in outer block");
            }
        }
    }
    
    func compareDates(){
        let now = Date();
        let string = (Calendar.current.dateComponents([.second], from: self.nowBackground, to: now).second ?? 0)
        let differencia = secondsOriginal - seconds + 1;
        //print("Counted Diff: \(differencia)");
        //print("Elapsed time: \(string)");
        if (differencia<string){
            seconds = secondsOriginal - string + 1;
            if seconds < 0 {
                seconds = 0;
            }else{
                print("Deleting notification request...")
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["Cool.My.Beer"])
            }
        }
    }
    
    func updateTimer() {
        if seconds < 1 {
            if timer.isValid { playSound(play: true); }
            timer.invalidate();
            //Send alert to indicate "time's up!"
        } else {
            compareDates();
            if seconds > 1 {
                seconds -= 1
            }
            timerLabel.text = timeString(time: TimeInterval(seconds))
            print("seconds: \(seconds)");
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
            actionEnfriar.setImage(UIImage(named:"Stop.png"), for: .normal)
            isRunning = true;
            seconds = secondsOriginal;
            runTimer();
            nowBackground = Date();
        }else{
            isRunning = false;
            playSound(play: false);
            timer.invalidate();
            actionEnfriar.setTitle("Enfriar", for: .normal);
            actionEnfriar.setImage(UIImage(named:"Congelar.png"), for: .normal)
        }
        print("isRunnind: \(isRunning)")
    }
    
    @IBAction func barraEnfriar(_ sender: UISlider) {
        if (sender.value < 0.5){
            enfriar = 0;
            sender.value = 0;
            //setSegundos(1800);
            setSegundos(15);
            timerLabel.text = timeString(time: TimeInterval(seconds))
        }else
            if (sender.value >= 0.5 && sender.value < 1.5){
                enfriar = 1;
                sender.value = 1;
                setSegundos(2700);
                timerLabel.text = timeString(time: TimeInterval(seconds))
        }else
                if (sender.value > 1.5){
                    enfriar = 2;
                    sender.value = 2;
                    setSegundos(3600);
                    timerLabel.text = timeString(time: TimeInterval(seconds))
        }
        //print(enfriar);
        //enfriar = Float(sender.value);
    }
    
    func sendNotification(_ sendSeconds: Int) {
        if isGrantedNotificationAccess{
            //add notification code here
            
            print("Adding notification request...")
            
            //Set the content of the notification
            let content = UNMutableNotificationContent()
            content.title = "Vaya a sacar su cerveza!!"
            //content.subtitle = "De CoolMyBeer"
            content.body = "Su cerveza está lista favor retirar del congelador!!"
            content.sound = UNNotificationSound.default()
            
            var trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(sendSeconds),
                repeats: false) //true
            
            if (seconds > 60){
                //Set the trigger of the notification -- here a timer.
                trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: TimeInterval(sendSeconds),
                    repeats: true) //true
            }
            
            //Set the request for the notification from the above
            let request = UNNotificationRequest(
                identifier: "Cool.My.Beer",
                content: content,
                trigger: trigger
            )
            
            //Add the notification to the currnet notification center
            UNUserNotificationCenter.current().add(
                request, withCompletionHandler: nil)
            
        }
    }
}

