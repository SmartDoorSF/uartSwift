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
    // var peripherals: Array<CBPeripheral> = Array<CBPeripheral>()
    var peripheralObjects = [AnyObject]()
    var readRSSITimer: NSTimer!
    var peripheral: CBPeripheral!
    var RSSIholder: NSNumber = 0
    var inputValue: Int = 2
    let txCharacteristic = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    var currentCharacteristic: CBCharacteristic! = nil
    var status: String = "closed"
    var autoStatus: String = "on"
    
    @IBOutlet weak var currentState: UILabel!
    @IBOutlet weak var currentRSSI: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var openLock1: UIButton!
    @IBOutlet weak var closeLock1: UIButton!
    @IBOutlet weak var autoLock1: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.startManager()
        openLock1.enabled = false
        closeLock1.enabled = false
        autoLock1.enabled = false
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
            print("BLE not on")
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        // peripherals.append(peripheral)
        if (peripheral.name != nil && peripheral.name! == "Nordic_UART"){
            print("found Nordic_UART")
            self.peripheral = peripheral
            self.centralManager.connectPeripheral(self.peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
            self.openLock1.enabled = true
            self.closeLock1.enabled = true
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
        self.currentRSSI.text = "0"
        self.openLock1.enabled = false
        self.closeLock1.enabled = false
        self.autoLock1.enabled = false
        self.startManager()
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?){
        print("connection failed", error)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?){
//        print("services \(peripheral.services)")
        peripheral.discoverCharacteristics(nil, forService: peripheral.services![0])
    }
    

    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?){
        print("characteristics \(service.characteristics)")
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            if thisCharacteristic.UUID == txCharacteristic{
                self.currentCharacteristic = thisCharacteristic
            }
        }
        if let error = error {
            print("characteristics error", error)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?){
        print("updated characteristic \(characteristic.value)")
        if let error = error {
            print("updated error", error)
        }
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
        if (Int(self.RSSIholder) > -70 && self.status == "closed" && self.autoStatus == "on") {
            let openValue = "1".dataUsingEncoding(NSUTF8StringEncoding)!
            print("value \(openValue)")
            self.peripheral.writeValue(openValue, forCharacteristic: self.currentCharacteristic, type: CBCharacteristicWriteType.WithResponse)
            self.status = "open"
            self.message.text = "message: open"
        } else if (Int(self.RSSIholder) < -80 && self.status == "open" && self.autoStatus == "on"){
            let closeValue = "2".dataUsingEncoding(NSUTF8StringEncoding)!
            print("value \(closeValue)")
            self.peripheral.writeValue(closeValue, forCharacteristic: self.currentCharacteristic, type: CBCharacteristicWriteType.WithResponse)
            self.status = "closed"
            self.message.text = "message: close"
        }

    }

    @IBAction func openLock(sender: UIButton) {
        let openValue = "1".dataUsingEncoding(NSUTF8StringEncoding)!
        print("value \(openValue)")
        self.peripheral.writeValue(openValue, forCharacteristic: self.currentCharacteristic, type: CBCharacteristicWriteType.WithResponse)
        self.autoStatus = "off"
        self.status = "open"
        self.message.text = "message: open"
        self.autoLock1.enabled = true
    }
    
    @IBAction func closeLock(sender: UIButton) {
        let closeValue = "2".dataUsingEncoding(NSUTF8StringEncoding)!
        print("value \(closeValue)")
        self.peripheral.writeValue(closeValue, forCharacteristic: self.currentCharacteristic, type: CBCharacteristicWriteType.WithResponse)
        self.autoStatus = "off"
        self.status = "closed"
        self.message.text = "message: close"
        self.autoLock1.enabled = true
    }
    
    @IBAction func autoOpen(sender: UIButton) {
        self.autoStatus = "on"
        self.autoLock1.enabled = false
    }
    
    func startReadRSSI() {
        if self.readRSSITimer == nil {
            self.readRSSITimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(self.readRSSI), userInfo: nil, repeats: true)
        }
    }
    
    func stopReadRSSI() {
        if (self.readRSSITimer != nil){
            self.readRSSITimer.invalidate()
            self.readRSSITimer = nil
        }
    }
    
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?){
        if let error = error {
            print("Writing error", error)
        } else {
            print("Succeeded")
        }
    }
    
}

