//
//  ViewController.swift
//  iBeaconSample
//
//  Created by gupuru on 2016/07/05.
//  Copyright © 2016年 kohei Niimi. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

class ViewController: UIViewController, CLLocationManagerDelegate, CBPeripheralManagerDelegate {
    
    @IBOutlet weak var logTextView: UITextView!
    
    private var locationManager: CLLocationManager?
    private var proximityUUID: NSUUID?
    private var beaconRegion: CLBeaconRegion?
    
    private var pheripheralManager: CBPeripheralManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let setting = UIUserNotificationSettings(forTypes: [.Sound, .Alert], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(setting)
        
        self.pheripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        if(CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion)) {
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
            
            // 取得精度の設定.
            self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            // 取得頻度の設定.(1mごとに位置情報取得)
            self.locationManager?.distanceFilter = 1
            
            
            self.proximityUUID = NSUUID(UUIDString: "74A23A96-A479-4330-AEFF-2421B6CF443C")
            if let uuid = self.proximityUUID {
//                self.beaconRegion = CLBeaconRegion(proximityUUID: uuid, major: CLBeaconMajorValue(1), minor: CLBeaconMinorValue(1), identifier: "ibeacon")
                
                self.beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "ibeacon")
                
            }
            //認証確認
            if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways {
                self.locationManager?.requestAlwaysAuthorization()
            } else {
                if let region = beaconRegion {
                    // ディスプレイがOffでもイベントが通知されるように設定(trueにするとディスプレイがOnの時だけ反応).
                    region.notifyEntryStateOnDisplay = false
                    // 入域通知の設定.
                    region.notifyOnEntry = true
                    // 退域通知の設定.
                    region.notifyOnExit = true
                    self.locationManager?.startMonitoringForRegion(region)
                }
            }
            
        }
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if self.pheripheralManager != nil && self.pheripheralManager!.isAdvertising {
            self.pheripheralManager?.stopAdvertising()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     (Delegate) 認証のステータスがかわったら呼び出される.
     */
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        // 認証のステータスをログで表示
        switch (status) {
        case .AuthorizedAlways:
            if let region = self.beaconRegion {
                self.locationManager?.startMonitoringForRegion(region)
            }
        case .AuthorizedWhenInUse:
            if let region = self.beaconRegion {
                self.locationManager?.startRangingBeaconsInRegion(region)
            }
        default:
            break
        }
    }
    
    /*
     STEP2(Delegate): LocationManagerがモニタリングを開始したというイベントを受け取る.
     */
    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        // STEP3: この時点でビーコンがすでにRegion内に入っている可能性があるので、その問い合わせを行う
        // (Delegate didDetermineStateが呼ばれる: STEP4)
        manager.requestStateForRegion(region)
        logTextView.text = logTextView.text + "\n\n" + "didStartMonitoringForRegion"
    }

    /*
     STEP4(Delegate): 現在リージョン内にいるかどうかの通知を受け取る.
     */
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        switch (state) {
        case .Inside:
            // リージョン内にいる
            print("CLRegionStateInside:");
            // STEP5: すでに入っている場合は、そのままRangingをスタートさせる
            // (Delegate didRangeBeacons: STEP6)
            manager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
            logTextView.text = logTextView.text + "\n\n" + "CLRegionStateInside"
        case .Outside:
            print("CLRegionStateOutside:")
            logTextView.text = logTextView.text + "\n\n" + "CLRegionStateOutside"
            // 外にいる、またはUknownの場合はdidEnterRegionが適切な範囲内に入った時に呼ばれるため処理なし
        case .Unknown:
            print("CLRegionStateUnknown:")
            logTextView.text = logTextView.text + "\n\n" + "CLRegionStateOutside"
            // 外にいる、またはUknownの場合はdidEnterRegionが適切な範囲内に入った時に呼ばれるため処理なし。
        }
    }
    
    /*
     STEP6(Delegate): ビーコンがリージョン内に入り、その中のビーコンをNSArrayで渡される.
     */
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        // 範囲内で検知されたビーコンはこのbeaconsにCLBeaconオブジェクトとして格納される
        // rangingが開始されると１秒毎に呼ばれるため、beaconがある場合のみ処理をするようにすること.
        if beacons.count > 0 {
            
            beacons.forEach {
                let beacon = $0 as CLBeacon
                
                let beaconUUID = beacon.proximityUUID
                let minorID = beacon.minor
                let majorID = beacon.major
                let rssi = beacon.rssi

                var distance: String = ""
                switch beacon.proximity {
                case .Unknown :
                    //不明
                    distance = "Proximity: Unknown"
                case .Far:
                    //遠い
                    distance = "Proximity: Far"
                case .Near:
                    //近い
                    distance = "Proximity: Near"
                case .Immediate:
                    //めっちゃ近い
                    distance = "Proximity: Immediate"
                }
                
                print(distance)
                
                logTextView.text = logTextView.text + "\n\n"
                    + "UUID: " + beaconUUID.UUIDString
                    + "\n minorID: " + String(minorID)
                    + "\n majorID: " + String(majorID)
                    + "\n RSSI: " + String(rssi)
                    + "\n" + distance
                
                sendLocalNotificationForMessage(distance)

            }
        }
    }
    
    /*
     (Delegate) リージョン内に入ったというイベントを受け取る.
     */
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("didEnterRegion");
        
        sendLocalNotificationForMessage("didEnterRegion")
        // Rangingを始める
        manager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
    }
    
    /*
     (Delegate) リージョンから出たというイベントを受け取る.
     */
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("didExitRegion");
        sendLocalNotificationForMessage("didExitRegion")

        // Rangingを停止する
        manager.stopRangingBeaconsInRegion(region as! CLBeaconRegion)
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        // iBeaconのUUID.
        let myProximityUUID = NSUUID(UUIDString: "74A23A96-A479-4330-AEFF-2421B6CF443C")
        // iBeaconのIdentifier.
        let myIdentifier = "ibeacon"
        
        // Major.
        let myMajor: CLBeaconMajorValue = 1
        
        // Minor.
        let myMinor: CLBeaconMinorValue = 1
        
        if let uuid = myProximityUUID {
            // BeaconRegionを定義.
            let myBeaconRegion = CLBeaconRegion(proximityUUID: uuid, major: myMajor, minor: myMinor, identifier: myIdentifier)
            // Advertisingのフォーマットを作成.
            let myBeaconPeripheralData = NSDictionary(dictionary: myBeaconRegion.peripheralDataWithMeasuredPower(nil))
            // Advertisingを発信.
            self.pheripheralManager?.startAdvertising(myBeaconPeripheralData as? [String : AnyObject])
        }
    }
    
    func sendLocalNotificationForMessage(message: String) {
        let localNotification:UILocalNotification = UILocalNotification()
        localNotification.alertBody = message
        localNotification.fireDate = NSDate(timeIntervalSinceNow: 1)
        localNotification.timeZone = NSTimeZone.defaultTimeZone()
        localNotification.soundName = UILocalNotificationDefaultSoundName
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
}

