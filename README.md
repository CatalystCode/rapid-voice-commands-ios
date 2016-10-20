# Rapid voice commands iOS

An Objective-C sample app that shows how to design and implement accurate and fast voice commands on iOS. The architecture of this solution was used in Cities Unlocked, a collaboration between Microsoft and Guide Dogs to help visually impaired navigate cities. The users keep the phone in their pocket and use a custom headset to issue voice commands like "Where am I?", "What's around me" and "Take me to Starbucks".

You can find an in-depth explanation of the solution in the blog post: [Developing an accurate and fast speech recognition for visually impaired users on iOS]().

## What you will find in this repo
- iOS Cognitive Services Speech SDK integration to establish a real-time stream and return partial and final string results as the user is speaking.
- Local intent extraction using a cache system.
- Online intent extraction using LUIS. 
- An Objective-C implementation of the iOS 10 Speech SDK.

## Getting started

1. You must obtain a Speech API subscription key by following the instructions on our website (https://www.microsoft.com/cognitive-services/en-us/sign-up).
2. You need to sign up to [Language Understanding Intelligent Service (LUIS)](https://www.luis.ai/) with any Microsoft account. 
3. Create a new application in LUIS. ![](https://cloud.githubusercontent.com/assets/10086264/19569132/80392aec-96ec-11e6-88ea-491e9a68984b.png)
4. To match the example dictionary, add two new intents (Orientate and Location) and their respective utterances ("What are the points of interest around me" and "What is my current location"). ![](https://cloud.githubusercontent.com/assets/10086264/19569171/b0dfc52a-96ec-11e6-9a1a-34259bb479dc.png) ![](https://cloud.githubusercontent.com/assets/10086264/19569192/c9ea2a24-96ec-11e6-9379-cf2feea41f30.png)
5. Train the model (bottom left button) and publish the application (top left). 
6. In the publish window, copy the App Id and the Subscription Key from the URL. ![](https://cloud.githubusercontent.com/assets/10086264/19569329/3f74f6c0-96ed-11e6-9b4f-c96415b90cd9.png) 
7. Open RapidVoiceCommands\Info.plist and add the keys obtained in step 1 and 6. ![](https://cloud.githubusercontent.com/assets/10086264/19569386/6d355500-96ed-11e6-88ad-bc6d66b66e74.png)
8. Start the sample app, press Start Listening button and speak a command! You can switch between Cognitive Services and iOS 10 Speech SDK for Speech to Text.
 
**Please note that iOS 10 Speech SDK does not work in emulator. You need to deploy to a device. **

## License

Copyright (c) Microsoft Corporation, licensed under [The MIT License (MIT)](https://github.com/CatalystCode/rapid-voice-commands-ios/blob/master/LICENSE).
