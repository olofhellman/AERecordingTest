//
//  KZAppleEvent.swift
//  AERecordingTest
//
//  Created by Olof Hellman on 11/30/25.
//


import Foundation
import CFNetwork
import CoreFoundation
import CoreServices
import AppKit

@objc
public class KZAppleEvent: NSObject {
    var m_nsEvent: NSAppleEventDescriptor? // was "AppleEvent"
    var m_nsEventReply: NSAppleEventDescriptor? // was "AppleEvent"
    var m_eventID: DescType
    var m_eventClass: DescType
    var m_eventReturnValue: OSStatus
    var m_offendingObject: NSAppleEventDescriptor?
    var m_errNumber: OSStatus
    var m_errorString: String?
    var m_expectedType: DescType?
    var m_result: NSAppleEventDescriptor
    var m_refcon: Int32

    override init() {
        self.m_nsEvent = nil
        self.m_nsEventReply = nil
        self.m_eventID = 0
        self.m_eventClass = 0
        self.m_eventReturnValue = noErr
        self.m_offendingObject = nil
        self.m_errNumber = 0
        self.m_errorString = nil
        self.m_expectedType = nil
        self.m_result = NSAppleEventDescriptor()
        self.m_refcon = 0
    }

    convenience init(eventID: DescType, eventClass: DescType, refcon: Int32) {
        self.init()
        self.m_eventID = eventID
        self.m_eventClass = eventClass
        self.m_refcon = refcon
    }

    convenience init(nsAppleEvent: NSAppleEventDescriptor, nsAppleEventReply: NSAppleEventDescriptor, refcon: Int32) {
        self.init()
        self.m_nsEvent = nsAppleEvent
        self.m_nsEventReply = nsAppleEventReply
        self.m_eventID = nsAppleEvent.eventID
        self.m_eventClass = nsAppleEvent.eventClass
        self.m_refcon = refcon
    }

    @objc
    convenience init(event: UnsafePointer<AppleEvent>, reply: UnsafePointer<AppleEvent>, refcon: Int32) {
        self.init()
        self.m_nsEvent = NSAppleEventDescriptor(aeDescNoCopy: event)
        self.m_nsEventReply = NSAppleEventDescriptor(aeDescNoCopy: reply)
        self.m_refcon = refcon

        var actualType: DescType = 0
        var actualSize: Int = 0

        AEGetAttributePtr(event, keyEventClassAttr, typeType, &actualType, &m_eventClass, MemoryLayout.size(ofValue: m_eventClass), &actualSize)
        AEGetAttributePtr(event, keyEventIDAttr, typeType, &actualType, &m_eventID, MemoryLayout.size(ofValue: m_eventID), &actualSize)
    }
    
    public func eventParamDescriptor(key: DescType, desiredType: DescType) -> NSAppleEventDescriptor? {
        guard let m_nsEvent, let resultParam = m_nsEvent.paramDescriptor(forKeyword: key) else {
            return nil
        }
        return resultParam
    }
    
    public func eventAttributeDescriptor(key: DescType, desiredType: DescType) -> NSAppleEventDescriptor? {
        guard let m_nsEvent, let resultParam = m_nsEvent.attributeDescriptor(forKeyword: key) else {
            return nil
        }
        return resultParam
    }
    
    
    func eventIs(_ eventType: OSType) -> Bool {
        return eventID() == DescType(eventType)
    }
    
    @MainActor func handleGetDataAppleEvent() {
        m_result = NSAppleEventDescriptor(string: AppDelegate.shared.secret)
    }
    
    @MainActor func handleSetDataAppleEvent() {
        let dataParam = self.eventParamDescriptor(key: keyAEData, desiredType: typeWildCard)
        if let newSecret = dataParam?.stringValue {
            AppDelegate.shared.secret = newSecret
        }
    }
    
    @objc(handleAppleEvent)
    @MainActor public func handleAppleEvent() -> OSStatus {
        self.dump()
        // for the purposes of this demo, handle only get and set
        if (m_eventID == kAEOpenApplication) {
            return noErr
        }
        else if (m_eventID == kAEGetData) {
            handleGetDataAppleEvent()
        }
        else if (m_eventID == kAESetData) {
            handleSetDataAppleEvent()
        } else {
            m_errNumber = OSStatus(errAEEventNotHandled)
        }
        
        return self.finish()
    }
     

 
    
    public func packageAEReply() {
        if self.m_errNumber == noErr {
            if let m_nsEventReply, m_result.descriptorType != typeNull {
                m_nsEventReply.setParam(m_result, forKeyword: keyAEResult)
            }
        }
        else {
            self.packageErrorsInAEReply()
        }
    }
    
    func finish() -> OSStatus {
        self.packageAEReply()
        return self.m_errNumber
    }

    func refcon() -> Int32 {
       return m_refcon
    }

    public func eventID() -> DescType {
        return m_eventID
    }
    
    public func eventClass() -> DescType {
        return m_eventClass
    }

    func resultDescType() -> DescType {
        return m_result.descriptorType
    }

    func eraseErrors() {
        setErrorNumber(noErr)
        m_offendingObject = nil
        m_errorString = ""
        m_expectedType = typeNull
    }

    // was setErrorStringDesc -- cant us OSAScripting anymore
    public func setErrorString(_ errString: String?) {
        m_errorString = errString
    }

    public func setErrorNumber(_ errNumber: Int32) {
        m_errNumber = errNumber
    }

    func setOffendingObject(_ offendingObject: NSAppleEventDescriptor) {
         m_offendingObject = offendingObject
    }

    func setExpectedType(_ expectedType: DescType) {
        m_expectedType = expectedType
    }

    func packageErrorsInAEReply() {
        let errorResult = NSAppleEventDescriptor.record()
 
        if m_errNumber != 0 {
            errorResult.setDescriptor(NSAppleEventDescriptor(int32: m_errNumber), forKeyword: keyErrorNumber)
        }

        if let m_errorString {
            errorResult.setDescriptor(NSAppleEventDescriptor(string: m_errorString), forKeyword: keyErrorString)
        }

        if let m_offendingObject, m_offendingObject.descriptorType != typeNull {
            errorResult.setDescriptor(m_offendingObject, forKeyword: kOSAErrorOffendingObject)
        }

        if let m_expectedType,  m_expectedType != typeNull {
            errorResult.setDescriptor(NSAppleEventDescriptor(typeCode: m_expectedType), forKeyword: kOSAErrorExpectedType)
        }

        if let m_nsEventReply, m_result.descriptorType != typeNull {
            m_nsEventReply.setParam(errorResult, forKeyword: keyAEResult)
        }
    }

    public func setResult(_ result: NSAppleEventDescriptor) {
        m_result = result;
    }

    func result() -> NSAppleEventDescriptor {
        return m_result
    }

    public func getParamDescriptor(_ key: DescType, desiredType: DescType) -> NSAppleEventDescriptor? {
        
        guard let m_nsEvent, let descriptor = m_nsEvent.paramDescriptor(forKeyword: key) else {
            // KZLog.info("KZAppleEvent", "failed getting param descriptor for key: \(key.asString())")
            return nil
        }
        if (descriptor.descriptorType == desiredType) || (desiredType == typeWildCard) {
            return descriptor
        }
        return descriptor.coerce(toDescriptorType: desiredType)
    }

    func getFCCParam(_ key: DescType) -> (OSStatus, DescType?) {
        guard let descriptor = getParamDescriptor(key, desiredType: typeType) else {
            return (OSStatus(errAEParamMissed), nil)
        }
        return (noErr, descriptor.typeCodeValue)
    }
 

    public func getBoolParam(_ key: DescType) -> (OSStatus, Bool?) {
        guard let descriptor = getParamDescriptor(key, desiredType: typeBoolean) else {
            return (OSStatus(errAEParamMissed), nil)
        }
        return (noErr, descriptor.booleanValue)
    }


    func dump() {
        print("KZAppleEvent " + "eventClass: \(m_eventClass)")
        print("KZAppleEvent " + "eventID: \(m_eventID)")
        print("KZAppleEvent " + "eventParams:  ")
        guard let m_nsEvent, m_nsEvent.isRecordDescriptor else {
            print("KZAppleEvent " + "    m_event was not a record descriptor")
            return
        }
        let nItems = m_nsEvent.numberOfItems
        for n in 0..<nItems {
            print("KZAppleEvent " + "    \(n): \(String(describing: m_nsEvent.atIndex(n)))")
        }
        return
     }
}
