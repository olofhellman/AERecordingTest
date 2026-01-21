//
//  KZAppleEventHandler.m
//  AERecordingTest
//
//  Created by Olof Hellman on 11/30/25.
//

#include "KZAppleEventHandler.h"
#include "AERecordingTest-Swift.h"

const DescType kOSAErrorNumber = 'errn';
const DescType kOSAErrorMessage = 'errs';
const DescType kOSAErrorBriefMessage = 'errb';
const DescType kOSAErrorApp = 'erap';
const DescType kOSAErrorPartialResult = 'ptlr';
const DescType kOSAErrorOffendingObject = 'erob';
const DescType kOSAErrorRange = 'erng';
const DescType kOSAErrorExpectedType = 'errt';
const DescType errAEUnknownOperator = '!KnO';


AEEventHandlerUPP KZGenericHandler(void)
{
    return NewAEEventHandlerUPP((AEEventHandlerProcPtr) KZAppleEventHandler);
}

OSStatus KZTriggerPermissionsDialog(void) {

    Boolean askUserIfNeeded = true;
    NSAppleEventDescriptor * address = [NSAppleEventDescriptor descriptorWithBundleIdentifier:@"com.apple.Safari"];
    AEEventClass eventClass = kAERequiredSuite;
    AEEventID eventID = kAEOpenApplication;
    
    OSStatus status = AEDeterminePermissionToAutomateTarget(address.aeDesc, eventClass, eventID, askUserIfNeeded);
    
    return status;
}

OSErr KZInstallRequiredSuiteHandlers(void)
{
     AEEventHandlerUPP handlerUPP = NewAEEventHandlerUPP((AEEventHandlerProcPtr) KZAppleEventHandler);

     OSStatus err = AEInstallEventHandler( kCoreEventClass, kAEOpenApplication, handlerUPP, 0L, false);
     if (err != noErr) {
         NSLog(@"err from installing AEHandler");
     }

     err = AEInstallEventHandler( kCoreEventClass, kAEOpenDocuments, handlerUPP, 0L, false);
     if (err != noErr) {
         NSLog(@"err from installing AEHandler");
     }
     
     err = AEInstallEventHandler( kCoreEventClass, kAEQuitApplication, handlerUPP, 0L, false);
     if (err != noErr) {
         NSLog(@"err from installing AEHandler");
     }
     return noErr;
}
OSErr KZInstallInstallUberHandler (void)
{
     AEEventHandlerUPP handlerUPP = NewAEEventHandlerUPP((AEEventHandlerProcPtr) KZAppleEventUberHandler);
     OSErr err = AEInstallEventHandler(typeWildCard ,typeWildCard, handlerUPP, 0L, false);
     if (err != noErr) {
         NSLog(@"err from installing Uber AEHandler");
     }
     return err;
}

OSErr KZInstallInstallSuiteWildcardHandler (DescType suiteID)
{
     AEEventHandlerUPP handlerUPP = NewAEEventHandlerUPP((AEEventHandlerProcPtr) KZAppleEventHandler);
     OSErr err = AEInstallEventHandler(suiteID ,typeWildCard, handlerUPP, 0L, false);
     if (err != noErr) {
         NSLog(@"err from installing Suite AEHandler");
     }
     return err;
}

OSErr KZAppleEventHandler ( AppleEvent *event, AppleEvent * reply, int32_t refcon)
{
    KZAppleEvent *kzAppleEvent = [[KZAppleEvent alloc] initWithEvent:event reply:reply refcon:refcon];
    OSErr err =  [kzAppleEvent handleAppleEvent];
    
    if ( err != 0 ) {
        NSLog (@"%@", [NSString stringWithFormat: @"KZAppleEventHandler error: %ld", (long) err]);
        return noErr;
    }
    return err;
}

OSErr KZAppleEventUberHandler ( AppleEvent *event, AppleEvent * reply, int32_t refcon)
{
    KZAppleEvent *kzAppleEvent = [[KZAppleEvent alloc] initWithEvent:event reply:reply refcon:refcon];
    NSLog (@"%@", [NSString stringWithFormat: @"KZAppleEventUberHandler called:"]);
 
    return noErr;
}
