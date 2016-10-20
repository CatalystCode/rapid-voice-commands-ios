//
//  CognitiveServicesViewController.h
//  RapidVoiceCommands
//
//  Created by Andrei Ermilov on 25/08/2016.
//  Copyright © 2016 Andrei Ermilov. All rights reserved.
//

#import "RapidVoiceCommands.h"
#import <SpeechSDK/SpeechRecognitionService.h>

@interface CognitiveServicesViewController : UIViewController <SpeechRecognitionProtocol>

@property (nonatomic, nullable)     NSString * luisAppId;
@property (nonatomic, nullable)     NSString * luisSubscriptionId;
@property (nonatomic, nullable)     NSString * cognitiveServicesPrimaryKey;
@property (nonatomic, nullable)     NSString * cognitiveServicesSecondaryKey;

@property (nonatomic, nullable)     NSDictionary * rapidCommandsDictionary;

// Initialise Oxford Client with keys.
- (void)InitialiseOxfordClientWithPrimaryKey:(nonnull NSString*)primaryKey
                                secondaryKey:(nonnull NSString*)secondarykey
                                   luisAppId:(nonnull NSString*)luisAppId
                          luisSubscriptionId:(nonnull NSString*)luisSubscriptionId;

@end
