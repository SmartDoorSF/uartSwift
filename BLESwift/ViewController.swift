//
//  ViewController.swift
//  BLESwift
//
//  Created by Ryan Jones on 6/14/16.
//  Copyright © 2016 Ryan Jones. All rights reserved.
//

import CoreBluetooth
import UIKit

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager!
    var peripherals: Array<CBPeripheral> = Array<CBPeripheral>()
    var peripheralObjects = [AnyObject]()
    var readRSSITimer: NSTimer!
    var peripheral: CBPeripheral!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func centralManagerDidUpdateState(central: CBCentralManager) {
        if (central.state == CBCentralManagerState.PoweredOn) {
            //this can be changed to have <#T##serviceUUIDs: [CBUUID]?##[CBUUID]?#>, options: <#T##[String : AnyObject]?#>
            self.centralManager?.scanForPeripheralsWithServices(nil, options: nil)
        } else {
            //alert that it isn't on
            print("device isn't on")
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        peripherals.append(peripheral)
        if (peripheral.name != nil && peripheral.name! == "Nordic_UART"){
            self.peripheral = peripheral
            self.centralManager.connectPeripheral(self.peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
        }
//        if (peripheral.name != nil && peripheral.name! == "Nordic_UART"){
//            peripheralObjects.append([peripheral.name!, RSSI])
//        }
//        print("these are the peripherals", peripheralObjects)
//        print("This is the RSSI", RSSI)
    }
    
// new after here
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        peripheral.readRSSI()
        self.startReadRSSI()
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?){
        self.stopReadRSSI()
        if self.peripheral != nil {
            self.peripheral.delegate = nil
            self.peripheral = nil
        }
    }
    
    func stopScan(){
        self.centralManager.stopScan()
    }
    
    func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        print("RSSI = \(RSSI)")
    }
    
    func readRSSI(){
        if (self.peripheral != nil){
            self.peripheral.delegate = self
            print("RSSI Request - \(peripheral.name!)")
            self.peripheral.readRSSI()
        } else {
            print("peripheral = nil")
        }
    }
    
    func startReadRSSI() {
        if self.readRSSITimer == nil {
            self.readRSSITimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(self.readRSSI), userInfo: nil, repeats: true)
        }
    }
    
    func stopReadRSSI() {
        if (self.readRSSITimer != nil){
            self.readRSSITimer.invalidate()
            self.readRSSITimer = nil
        }
    }
    
}

