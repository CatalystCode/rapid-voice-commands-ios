//
//  MainPageViewController.m
//  RapidVoiceCommands
//
//  Created by Andrei Ermilov on 25/08/2016.
//  Copyright © 2016 Andrei Ermilov. All rights reserved.
//

#import "MainPageViewController.h"

@interface MainPageViewController ()

@property (strong, nonatomic) IBOutlet UITextView *PartialResultTextView;
@property (strong, nonatomic) IBOutlet UITextView *FinalResultTextView;
@property (strong, nonatomic) IBOutlet UITextView *LuisResultTextView;
@property (strong, nonatomic) IBOutlet UITextView *ActionIssuedTextView;
@property (strong, nonatomic) IBOutlet UIButton *StartListeningButton;

// Start Listening button pressed event
- (IBAction)StartListeningButtonPressed:(id)sender;

// Converts an integer error code to an error string.
- (NSString*)convertSpeechErrorToString:(int)errorCode;

// Try and recognise the phrase locally before submiting to LUIS.
- (Boolean)tryAndRecognisePhrase:(NSString *)phrase;

// Clears the text from all text views.
- (void)clearText;

// Updates the text for a specific text view.
- (void)updateText:(NSString*)text forUIElement:(TextViewElement)textViewElement;

@end

@implementation MainPageViewController
{
@private
    // The command defintions.
    NSArray<NSString *> * _commandDefinitions;
    
    // The command execution boolean.
    Boolean _commandExecuted;
    
    // The Cognitive Services speech locale. Default en-us.
    NSString * _cognitiveSpeechServicesLocale;
    
    // The microphone client for Oxford SDK.
    MicrophoneRecognitionClient* _micClient;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self clearText];
    
    // Initialize.
    NSBundle * mainBundle = [NSBundle mainBundle];
    
    _cognitiveServicesPrimaryKey = [mainBundle objectForInfoDictionaryKey:@"SpeechCognitiveServicesPrimaryKey"];
    _cognitiveServicesSecondaryKey = [mainBundle objectForInfoDictionaryKey:@"SpeechCognitiveServicesSecondaryKey"];
    _luisAppId = [mainBundle objectForInfoDictionaryKey:@"LuisAppId"];
    _luisSubscriptionId = [mainBundle objectForInfoDictionaryKey:@"LuisSubscriptionId"];
    
    _rapidCommandsDictionary = [mainBundle objectForInfoDictionaryKey:@"RapidCommandsDictionary"];
    
    /* The language of the speech being recognized. Change for a different language. The supported languages are:
    * en-us American English
    * en-gb: British English
    * de-de: German
    * es-es: Spanish
    * fr-fr: French
    * it-it: Italian
    * zh-cn: Mandarin Chinese */
    _cognitiveSpeechServicesLocale = @"en-us";
    
    [self InitialiseOxfordClientWithPrimaryKey:_cognitiveServicesPrimaryKey
                                  secondaryKey:_cognitiveServicesSecondaryKey
                                     luisAppId:_luisAppId
                            luisSubscriptionId:_luisSubscriptionId];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)StartListeningButtonPressed:(id)sender
{
    // We are starting a new session, clear all text.
    [self clearText];
    
    OSStatus status = [_micClient startMicAndRecognition];
    if (status) {
        [self updateText:[NSString stringWithFormat:@"Error starting audio. %@",[self convertSpeechErrorToString:status]] forUIElement:FinalResultTextView];
    }
}

- (void)clearText
{
    _commandExecuted = NO;
    [self updateText:@"" forUIElement:ActionIssuedTextView];
    [self updateText:@"" forUIElement:LuisResultTextView];
    [self updateText:@"" forUIElement:FinalResultTextView];
    [self updateText:@"" forUIElement:PartialResultTextView];
}

- (void)updateText:(NSString*)text forUIElement:(TextViewElement)textViewElement
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        switch (textViewElement)
        {
            case ActionIssuedTextView:
                _ActionIssuedTextView.text = text;
                break;
            case LuisResultTextView:
                _LuisResultTextView.text = text;
                break;
            case FinalResultTextView:
                _FinalResultTextView.text = text;
                break;
            case PartialResultTextView:
                _PartialResultTextView.text = text;
                break;
            default:
                break;
        }
    });
}

- (void)InitialiseOxfordClientWithPrimaryKey:(nonnull NSString*)primaryKey
                                secondaryKey:(nonnull NSString*)secondarykey
                                   luisAppId:(nonnull NSString*)luisAppId
                          luisSubscriptionId:(nonnull NSString*)luisSubscriptionId
{
    _micClient = [SpeechRecognitionServiceFactory createMicrophoneClientWithIntent:_cognitiveSpeechServicesLocale
                                                                    withPrimaryKey:primaryKey
                                                                  withSecondaryKey:secondarykey
                                                                     withLUISAppID:luisAppId
                                                                    withLUISSecret:luisSubscriptionId
                                                                      withProtocol:(self)];
}

- (Boolean)tryAndRecognisePhrase:(NSString *)phrase
{
    if([_rapidCommandsDictionary objectForKey:[phrase lowercaseString]])
    {
        _commandExecuted = YES;
    }
    
    return _commandExecuted;
}

/**
 * Called when a final response is received.
 * @param response The final result.
 */
-(void)onFinalResponseReceived:(RecognitionResult*)response
{
    // Do we have a recognized phrase.
    if ([response.RecognizedPhrase count] == 0)
    {
        [self updateText:@"Could not recognise the phrase." forUIElement:ActionIssuedTextView];
        
        return;
    }
    else
    {
        // Pick the top one.
        RecognizedPhrase * phrase = response.RecognizedPhrase[0];
        
        [self updateText:[phrase DisplayText] forUIElement:FinalResultTextView];
        
        // Check if the partial recognition issued a command.
        if(!_commandExecuted)
        {
            [self updateText:@"Command was not found in local dictionary." forUIElement:ActionIssuedTextView];
        }
    }
}

/**
 * Called when a final response is received and its intent is parsed
 * @param result The intent result.
 */
-(void)onIntentReceived:(IntentResult*) result
{
    // We already executed a command, LUIS is not needed.
    if(_commandExecuted)
    {
        return;
    }
    
    NSString *finalIntentName = @"NONE";
    NSError *e = nil;
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[[result Body] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&e];

    NSArray *intentsArray=[jsonDict objectForKey:@"intents"];
    for (NSDictionary * intent in intentsArray)
    {
        NSString * scoreString = (NSString*)[intent objectForKey:@"score"];
        NSString * intentName =(NSString*)[intent objectForKey:@"intent"];
        double score = [scoreString doubleValue];
        
        if([intentName length] > 0)
        {
            finalIntentName = [intentName lowercaseString];
            
            [self updateText:[NSString stringWithFormat:@"Intent received: %@ \nConfidence level: %f", finalIntentName, score] forUIElement:LuisResultTextView];
            
            break;
        }
    }
    
    if(finalIntentName && [self tryAndRecognisePhrase:finalIntentName])
    {
        [self updateText:[NSString stringWithFormat:@"Action succesfully issued: %@, using LUIS intent extraction.", [_rapidCommandsDictionary objectForKey:[finalIntentName lowercaseString]]] forUIElement:ActionIssuedTextView];
    }
    else
    {
        [self updateText:@"The intent returned from LUIS was not found in the local dictionary. If appropiate, include this intent in the RapidCommandsDictionary, or train the model." forUIElement:ActionIssuedTextView];
    }
}

/**
 * Called when a partial response is received
 * @param response The partial result.
 */
-(void)onPartialResponseReceived:(NSString*) response
{
    [self updateText:response forUIElement:PartialResultTextView];
    
    if([self tryAndRecognisePhrase:response])
    {
        [self updateText:[NSString stringWithFormat:@"Action succesfully issued: %@, using local dictionary matching.", (NSString*)[_rapidCommandsDictionary objectForKey:[response lowercaseString]]] forUIElement:ActionIssuedTextView];

        // We issued a command. End the mic recognition.
        [_micClient endMicAndRecognition];
    }
}

/**
 * Called when an error is received
 * @param errorMessage The error message.
 * @param errorCode The error code.  Refer to SpeechClientStatus for details.
 */
-(void)onError:(NSString*)errorMessage withErrorCode:(int)errorCode
{
    [self updateText:[NSString stringWithFormat:@"Error occured: %@ - %@.", [self convertSpeechErrorToString:errorCode], errorMessage] forUIElement:PartialResultTextView];
}

/**
 * Called when the microphone status has changed.
 * @param recording The current recording state
 */
-(void)onMicrophoneStatus:(Boolean)recording
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _StartListeningButton.enabled = !recording;
    });
}

/**
 * Converts an integer error code to an error string.
 * @param errorCode The error code
 * @return The string representation of the error code.
 */
- (NSString*)convertSpeechErrorToString:(int)errorCode
{
    switch ((SpeechClientStatus)errorCode) {
        case SpeechClientStatus_SecurityFailed:         return @"SpeechClientStatus_SecurityFailed";
        case SpeechClientStatus_LoginFailed:            return @"LoginFailed. Please make sure you added the correct keys in Info.plist";
        case SpeechClientStatus_Timeout:                return @"SpeechClientStatus_Timeout";
        case SpeechClientStatus_ConnectionFailed:       return @"SpeechClientStatus_ConnectionFailed";
        case SpeechClientStatus_NameNotFound:           return @"SpeechClientStatus_NameNotFound";
        case SpeechClientStatus_InvalidService:         return @"SpeechClientStatus_InvalidService";
        case SpeechClientStatus_InvalidProxy:           return @"SpeechClientStatus_InvalidProxy";
        case SpeechClientStatus_BadResponse:            return @"SpeechClientStatus_BadResponse";
        case SpeechClientStatus_InternalError:          return @"SpeechClientStatus_InternalError";
        case SpeechClientStatus_AuthenticationError:    return @"SpeechClientStatus_AuthenticationError";
        case SpeechClientStatus_AuthenticationExpired:  return @"SpeechClientStatus_AuthenticationExpired";
        case SpeechClientStatus_LimitsExceeded:         return @"SpeechClientStatus_LimitsExceeded";
        case SpeechClientStatus_AudioOutputFailed:      return @"SpeechClientStatus_AudioOutputFailed";
        case SpeechClientStatus_MicrophoneInUse:        return @"SpeechClientStatus_MicrophoneInUse";
        case SpeechClientStatus_MicrophoneUnavailable:  return @"SpeechClientStatus_MicrophoneUnavailable";
        case SpeechClientStatus_MicrophoneStatusUnknown:return @"SpeechClientStatus_MicrophoneStatusUnknown";
        case SpeechClientStatus_InvalidArgument:        return @"SpeechClientStatus_InvalidArgument";
    }
    
    return [[NSString alloc] initWithFormat:@"Unknown error: %d\n", errorCode];
}

@end


