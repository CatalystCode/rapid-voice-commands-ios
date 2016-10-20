//
//  RapidVoiceCommands.h
//  RapidVoiceCommands
//
//  Created by Andrei Ermilov on 06/10/2016.
//  Copyright © 2016 Andrei Ermilov. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef RapidVoiceCommands_h
#define RapidVoiceCommands_h

// Data task completion handler
typedef void (^DataTaskCompletionHandler)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);

// Text Views enumeration
typedef NS_ENUM(NSUInteger, TextViewElement)
{
    PartialResultTextView,
    FinalResultTextView,
    LuisResultTextView,
    ActionIssuedTextView
};

#endif /* RapidVoiceCommands_h */
