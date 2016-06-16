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
    var RSSIholder: NSNumber = 0
    
    @IBOutlet weak var currentState: UILabel!
    @IBOutlet weak var currentRSSI: UILabel!
    @IBOutlet weak var message: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.startManager()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func centralManagerDidUpdateState(central: CBCentralManager) {
        if (central.state == CBCentralManagerState.PoweredOn) {
            self.centralManager?.scanForPeripheralsWithServices(nil, options: nil)
            self.currentState.text = "Scanning"
        } else {
            print("device isn't on")
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        peripherals.append(peripheral)
        if (peripheral.name != nil && peripheral.name! == "Nordic_UART"){
            print("found Nordic_UART")
            self.peripheral = peripheral
            self.centralManager.connectPeripheral(self.peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        peripheral.readRSSI()
        self.startReadRSSI()
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        print("connected to \(peripheral)")
        self.currentState.text = "Connected to \(peripheral.name!)"
        self.stopScan()
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?){
        self.stopReadRSSI()
        if self.peripheral != nil {
            self.peripheral.delegate = nil
            self.peripheral = nil
        }
        print("did disconnect", error)
        self.currentState.text = "Disconnected"
        self.startManager()
    }
    
    func stopScan(){
        self.centralManager.stopScan()
    }
    
    func startManager(){
        centralManager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue())
    }
    
    func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        self.RSSIholder = Int(RSSI)
        print("RSSI = \(self.RSSIholder)")
        self.currentRSSI.text = String(RSSI)
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
    
    func writeValue(data: NSData, forCharacteristic characteristic: CBCharacteristic, type: CBCharacteristicWriteType, error: NSError?) {
        if error != nil {
            print("error from writing", error)
        } else if (Int(RSSIholder) > -70) {
            self.message.text = "Sent 1"
        }
    }
    
}

