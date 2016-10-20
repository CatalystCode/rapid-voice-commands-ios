//
//  SpeechSDKViewController.h
//  RapidVoiceCommands
//
//  Created by Andrei Ermilov on 06/10/2016.
//  Copyright © 2016 Andrei Ermilov. All rights reserved.
//

#import "RapidVoiceCommands.h"
#import <Speech/SFSpeechRecognizer.h>
#import <Speech/SFSpeechRecognitionRequest.h>
#import <Speech/SFSpeechRecognitionTask.h>
#import <Speech/SFSpeechRecognitionResult.h>
#import <Speech/SFTranscription.h>

@interface SpeechSDKViewController : UIViewController <SFSpeechRecognizerDelegate>

@property (nonatomic, nullable)     NSString * luisAppId;
@property (nonatomic, nullable)     NSString * luisSubscriptionId;

@property (nonatomic, nullable)     NSDictionary * rapidCommandsDictionary;

@end
