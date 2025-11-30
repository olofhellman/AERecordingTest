//
//  KZAppleEventHandler.h
//  AERecordingTest
//
//  Created by Olof Hellman on 11/30/25.
//
 
#import <Foundation/Foundation.h>


extern const DescType kOSAErrorNumber;
extern const DescType kOSAErrorMessage;
extern const DescType kOSAErrorBriefMessage;
extern const DescType kOSAErrorApp;
extern const DescType kOSAErrorPartialResult;
extern const DescType kOSAErrorOffendingObject;
extern const DescType kOSAErrorRange;
extern const DescType kOSAErrorExpectedType;
extern const DescType errAEUnknownOperator;

AEEventHandlerUPP KZGenericHandler(void);
OSStatus KZTriggerPermissionsDialog(void);

OSErr KZInstallRequiredSuiteHandlers (void);
OSErr KZInstallInstallSuiteWildcardHandler (DescType suiteID);
OSErr KZAppleEventHandler (AppleEvent *event, AppleEvent * theReply, int32_t refcon);
