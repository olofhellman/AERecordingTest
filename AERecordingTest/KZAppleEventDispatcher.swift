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
       event.dump(str: "in dispatchToSelf()")
  
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
    
        appleEvent.dump(str: "entered dispatch()")

        let dontSend = options?.contains(.dontExecute) ?? false
        let waitForReply = options?.contains(.waitForReply) ?? false
        
        var sendOptions = options ?? NSAppleEventDescriptor.SendOptions.defaultOptions
        sendOptions.insert(.dontExecute)
        if (waitForReply) {
            sendOptions.remove(.waitForReply)
            sendOptions.insert(.noReply)
        }
        
        // Seems like sending AppleEvent to self requires some
        // arcane permissions
         appleEvent.dump(str: "calling sendEvent()")
        let recordingResult = try? appleEvent.sendEvent(options: sendOptions, timeout: 60)
         appleEvent.dump(str: "called sendEvent()")
       
        // result can be nil if we said noReply
        if let recordingResult {
            print("recording result: \(recordingResult)")
        }
        else {
            print("recording result was nil")
        }
        
        if dontSend {
           return (noErr, nil)
        }
        
        if (waitForReply) {
            sendOptions.insert(.waitForReply)
            sendOptions.remove(.noReply)
        }
 
          appleEvent.dump(str: "calling dispatchToSelf()")

        let (_, reply) = dispatchToSelf(appleEvent, reply: nil, refcon: refcon)
        print ( "reply  code is \(reply?.debugDescription ?? "nil descriptor")")
        guard let result = reply?.forKeyword(keyAEResult) else {
            return (OSStatus(errAEReplyNotValid), nil)
        }
 
        return (noErr, result)
    }

}
