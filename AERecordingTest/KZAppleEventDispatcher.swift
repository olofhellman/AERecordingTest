//
//  KZAppleEventDispatcher.swift
//  AERecordingTest
//
//  Created by Olof Hellman on 11/30/25.
//

import Foundation
import AppKit

public class KZAppleEventDispatcher {

    var appleEventHandler: AEEventHandlerUPP
    
    init() {
        appleEventHandler = KZGenericHandler()
        KZInstallRequiredSuiteHandlers()
        self.installSuiteAppleEventHandler(suiteID: kAECoreSuite)
        Task {
        _ = KZTriggerPermissionsDialog()
        }
        // Task {
        //     KZAppleEventDispatcher.launchScriptEditor()
        // }
    }
 
    public func installSuiteAppleEventHandler(suiteID: OSType) {
        _ = KZInstallInstallSuiteWildcardHandler(suiteID)
    }
 
    public func removeAppleEventHandlers() {

    }
 
    
    // the refcon here is used to tunnel file data through if AppleScript
    // doesn't allow permissions for external file access
    // the refcon refers to a token that can be used to redeem stashed data in the
    // application object
    @MainActor
    public func dispatchToSelf(_ event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor? = nil, refcon: Int32 = 0) -> (OSStatus, NSAppleEventDescriptor?) {
    
        let useReply = reply ?? NSAppleEventDescriptor.appleEvent( withEventClass: event.eventClass,
            eventID: kAEAnswer,
            targetDescriptor: nil,
            returnID: 0,
            transactionID:AETransactionID(kAnyTransactionID))
  
        let kzAppleEvent = KZAppleEvent(nsAppleEvent: event, nsAppleEventReply: useReply, refcon: refcon)
        let eventResult = kzAppleEvent.handleAppleEvent()
        if eventResult != noErr {
            print( "AppleEvent dispatch failed with error \(eventResult)")
            return (eventResult, nil)
        }
        return (noErr, useReply)
    }
    
    @MainActor
    public func dispatch(_ appleEvent: NSAppleEventDescriptor, sendOptions options: NSAppleEventDescriptor.SendOptions?, refcon: Int32 = 0) -> (OSStatus, NSAppleEventDescriptor?) {
    
        // dispatchExternally() sends the event normally
        // if an AppleScript Editor window turns on recording, the delivery will fail
 
        // dispatchInternallyWithRecording() sends the event with .dontExecute
        // but then calls the AppleEventHandler on its own
        // This is a workaround for the fact that if recording is turned on
        // dispatchExternally() will fail
        // if an AppleScript Editor window turns on recording, the delivery will fail
        // However, sending events from AppleScript Editor will still faile
        // if recording is turned on
 
        // Use one of the following two lines:
        // return dispatchExternally(appleEvent, sendOptions: options, refcon: refcon)
        return dispatchInternallyWithRecording(appleEvent, sendOptions: options, refcon: refcon)
    }
    
    @MainActor
    public func dispatchExternally(_ appleEvent: NSAppleEventDescriptor, sendOptions options: NSAppleEventDescriptor.SendOptions?, refcon: Int32 = 0) -> (OSStatus, NSAppleEventDescriptor?) {
         
        var sendOptions = options ?? NSAppleEventDescriptor.SendOptions.defaultOptions
        
        let result = try? appleEvent.sendEvent(options: sendOptions, timeout: 60)
       
        // result can be nil if we said noReply
        if let result {
            print("externalDispatch result: \(result)")
        }
        else {
            print("externalDispatch result was nil")
        }
        return (noErr, result)
    }
    
    @MainActor
    public func dispatchInternallyWithRecording(_ appleEvent: NSAppleEventDescriptor, sendOptions options: NSAppleEventDescriptor.SendOptions?, refcon: Int32 = 0) -> (OSStatus, NSAppleEventDescriptor?) {

        let dontSend = options?.contains(.dontExecute) ?? false
        let waitForReply = options?.contains(.waitForReply) ?? false
        
        var sendOptions = options ?? NSAppleEventDescriptor.SendOptions.defaultOptions
        sendOptions.insert(.dontExecute)
        if (waitForReply) {
            sendOptions.remove(.waitForReply)
            sendOptions.insert(.noReply)
        }

        if let appleEventForRecording = appleEvent.copy() as? NSAppleEventDescriptor {
            print("sending .dontExecute event for recording")
            let recordingResult = try? appleEventForRecording.sendEvent(options: sendOptions, timeout: 60)
            // result will be nil if we said noReply
        }
        
        if dontSend {
           return (noErr, nil)
        }

        let (_, reply) = dispatchToSelf(appleEvent, reply: nil, refcon: refcon)
        print ( "reply  code is \(reply?.debugDescription ?? "nil descriptor")")
        guard let result = reply?.forKeyword(keyAEResult) else {
            return (OSStatus(errAEReplyNotValid), nil)
        }
 
        return (noErr, result)
    }

}
