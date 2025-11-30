//
//  AppDelegate.swift
//  AERecordingTest
//
//  Created by Olof Hellman on 11/30/25.
//

import Cocoa

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


}

