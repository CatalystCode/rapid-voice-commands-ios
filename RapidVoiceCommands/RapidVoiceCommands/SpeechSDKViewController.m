//
//  SpeechSDKViewController.m
//  RapidVoiceCommands
//
//  Created by Andrei Ermilov on 06/10/2016.
//  Copyright © 2016 Andrei Ermilov. All rights reserved.
//

#import "SpeechSDKViewController.h"

@interface SpeechSDKViewController ()


@property (strong, nonatomic) IBOutlet UITextView *PartialResultTextView;
@property (strong, nonatomic) IBOutlet UITextView *FinalResultTextView;
@property (strong, nonatomic) IBOutlet UITextView *LuisResultTextView;
@property (strong, nonatomic) IBOutlet UITextView *ActionIssuedTextView;
@property (strong, nonatomic) IBOutlet UIButton *StartListeningButton;

// Clears the text from all text views.
- (void)clearText;

// Updates the text for a specific text view.
- (void)updateText:(NSString*)text forUIElement:(TextViewElement)textViewElement;

// Try and recognise the phrase locally before submiting to LUIS.
- (Boolean)tryAndRecognisePhrase:(NSString *)phrase;

// Start listening button pressed event.
- (IBAction)StartListeningButtonPressed:(id)sender;

// Start listening task.
- (void)startListening;

// Online intent extraction with LUIS.
- (void)extractLuisIntent:(NSString*)query;

@end

@implementation SpeechSDKViewController
{
@private
    SFSpeechRecognizer * speechRecognizer;
    SFSpeechAudioBufferRecognitionRequest * speechRecognitionRequest;
    SFSpeechRecognitionTask * speechRecognitionTask;
    AVAudioEngine * audioEngine;
    
    // The command execution boolean.
    Boolean _commandExecuted;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize.
    NSBundle * mainBundle = [NSBundle mainBundle];
    _rapidCommandsDictionary = [mainBundle objectForInfoDictionaryKey:@"RapidCommandsDictionary"];
    _luisAppId = [mainBundle objectForInfoDictionaryKey:@"LuisAppId"];
    _luisSubscriptionId = [mainBundle objectForInfoDictionaryKey:@"LuisSubscriptionId"];
    
    [self clearText];
    
    speechRecognizer = [[SFSpeechRecognizer alloc] init];
    audioEngine = [[AVAudioEngine alloc] init];
    _StartListeningButton.enabled = true;
    
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                    _StartListeningButton.enabled = true;
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                [self updateText:@"User denied access to the microphone." forUIElement:PartialResultTextView];
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                [self updateText:@"There is rescricted access to the microphone on this device." forUIElement:PartialResultTextView];
                break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                [self updateText:@"Could not determine status for microphone." forUIElement:PartialResultTextView];
                break;
            default:
                break;
        }
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (Boolean)tryAndRecognisePhrase:(NSString *)phrase
{
    if([_rapidCommandsDictionary objectForKey:[phrase lowercaseString]])
    {
        _commandExecuted = YES;
    }
    
    return _commandExecuted;
}

- (void)clearText
{
    _commandExecuted = NO;
    
    [self updateText:@"" forUIElement:ActionIssuedTextView];
    [self updateText:@"" forUIElement:LuisResultTextView];
    [self updateText:@"" forUIElement:FinalResultTextView];
    [self updateText:@"Press start listening and speak a command!" forUIElement:PartialResultTextView];
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

- (IBAction)StartListeningButtonPressed:(id)sender
{
    if([audioEngine isRunning])
    {
        [audioEngine stop];
        if(speechRecognitionRequest != nil)
        {
            [speechRecognitionRequest endAudio];
        }
        
        [_StartListeningButton setTitle:@"Start listening" forState:UIControlStateNormal];
    }
    else
    {
        [_StartListeningButton setTitle:@"Stop listening" forState:UIControlStateNormal];
        [self startListening];
    }
}

- (void)extractLuisIntent:(NSString*)query
{
    NSString* encodedQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    
    NSString * luisString = [NSString stringWithFormat:@"https://api.projectoxford.ai/luis/v1/application?id=%@&subscription-key=%@&q=%@", _luisAppId, _luisSubscriptionId, encodedQuery];
    NSURL * luisURL = [NSURL URLWithString:luisString];
    
    // Construct the URL request.
    NSMutableURLRequest * mutableURLRequest = [NSMutableURLRequest requestWithURL:luisURL];
    
    // The completion handler.
    DataTaskCompletionHandler completionHandler = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        _StartListeningButton.enabled = YES;
        [_StartListeningButton setTitle:@"Start listening" forState:UIControlStateNormal];
        
        // Handle connection errors.
        if (error)
        {
            return;
        }
        
        NSMutableDictionary* json = nil;
        NSString *finalIntentName = @"NONE";
        
        if (nil != data)
        {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
            NSArray *intentsArray=[json objectForKey:@"intents"];
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
                [self updateText:@"The intent returned from LUIS was not found in the local dictionary. If appropiate, include this intent in the Rapid Commands Dictionary, or train the model." forUIElement:ActionIssuedTextView];
            }
            
        }
        
        if (error || !json)
        {
            NSLog(@"Could not parse loaded json with error:%@", error);
        }
    };
    
    // Send the URL request.
    NSURLSessionDataTask * task = [[NSURLSession sharedSession] dataTaskWithRequest:mutableURLRequest
                                                                  completionHandler:completionHandler];
    [task resume];
}

- (void)startListening
{
    if(speechRecognitionTask != nil)
    {
        [speechRecognitionTask cancel];
        speechRecognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioSession setMode:AVAudioSessionModeMeasurement error:nil];
    [audioSession setActive:YES error:nil];
    
    speechRecognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode * inputNode = [audioEngine inputNode];
    
    speechRecognitionRequest.shouldReportPartialResults = YES;
    [self clearText];
    [self updateText:@"Speak a command!" forUIElement:PartialResultTextView];
    
    speechRecognitionTask = [speechRecognizer recognitionTaskWithRequest:speechRecognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        Boolean isFinal = NO;
        
        if(_commandExecuted)
            return;
        
        if(result != nil)
        {
            NSString* response = [[result bestTranscription] formattedString];
            
            [self updateText:[[result bestTranscription] formattedString] forUIElement:PartialResultTextView];
            isFinal = [result isFinal];
            
            if([self tryAndRecognisePhrase:response])
            {
                [self updateText:[NSString stringWithFormat:@"Action succesfully issued: %@, using local dictionary matching.", (NSString*)[_rapidCommandsDictionary objectForKey:[response lowercaseString]]] forUIElement:ActionIssuedTextView];
                
                isFinal = YES;
                _commandExecuted = YES;
            }
        }
        
        if(isFinal)
        {
            [self updateText:[[result bestTranscription] formattedString] forUIElement:FinalResultTextView];
        }
        
        if(error != nil || isFinal)
        {
            [audioEngine stop];
            [inputNode removeTapOnBus: 0];
            if(speechRecognitionRequest != nil)
            {
                [speechRecognitionRequest endAudio];
            }
            
            speechRecognitionRequest = nil;
            speechRecognitionTask = nil;
            
            if(error)
            {
                [self updateText:@"An error occured starting the Speech service. Try again later." forUIElement:PartialResultTextView];
                return;
            }
            
            if(_commandExecuted)
            {
                _StartListeningButton.enabled = YES;
                [_StartListeningButton setTitle:@"Start listening" forState:UIControlStateNormal];
            }
            else
            {
                [self updateText:@"Command was not found in local dictionary. Reaching to LUIS for intent extraction" forUIElement:ActionIssuedTextView];
                
                [self extractLuisIntent:[[result bestTranscription] formattedString]];
            }
        }
    }];
    
    AVAudioFormat* recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format: recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [speechRecognitionRequest appendAudioPCMBuffer:buffer];
    }];
    
    [audioEngine prepare];
    [audioEngine startAndReturnError:nil];
}


@end
