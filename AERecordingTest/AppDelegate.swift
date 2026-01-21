//
//  AppDelegate.swift
//  AERecordingTest
//
//  Created by Olof Hellman on 11/30/25.
//

import Cocoa
import AppKit

@main
public class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    static var shared: AppDelegate { NSApp.delegate as! AppDelegate }
    public var secret: String
    
    var appleEventDispatcher: KZAppleEventDispatcher

    override init () {
        secret = "secret"
        appleEventDispatcher = KZAppleEventDispatcher()
        super.init()
    }
   
    public func applicationDidFinishLaunching(_ aNotification: Notification) {
        appleEventDispatcher = KZAppleEventDispatcher()

        // Insert code here to initialize your application
    }

    public func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    public func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
 
    @IBAction func setSecretToRandomName(_ sender: Any) {
        let names = ["Chris", "Espinosa", "Quinn", "Eskimo", "Andy", "Bachorski", "Nebel", "Sal", "Soghoian"]
        let randomInt = Int.random(in: 0..<names.count)
        
        let newSecret = names[randomInt]
        NSLog("new secret \(newSecret)")
        let targetDescriptor = NSAppleEventDescriptor.currentProcess()
 
        let event = NSAppleEventDescriptor.appleEvent(
            withEventClass: AEEventClass(kAECoreSuite),
            eventID:kAESetData,
            targetDescriptor: targetDescriptor,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID))
         
        event.setParam(NSAppleEventDescriptor(string: newSecret), forKeyword: keyAEData)
        
        if let secretDescriptor = NSAppleEventDescriptor.createObjSpecifier(of: "prop".asDescType(), container: nil, form: formPropertyID, data: NSAppleEventDescriptor(typeCode: "Secr".asDescType())) {

            event.setParam(secretDescriptor, forKeyword: keyDirectObject)
        }
        
        var sendOptions = NSAppleEventDescriptor.SendOptions.defaultOptions
        // sendOptions.insert(.dontExecute)
        Task {
            appleEventDispatcher.dispatch(event, sendOptions: sendOptions)
        }
    }
 
}

