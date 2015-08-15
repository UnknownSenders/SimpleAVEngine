//
//  ViewController.h
//  SimpleAVEngine
//
//  Created by Thierry Sansaricq on 7/21/15.
//  Copyright (c) 2015 Thierry Sansaricq. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AudioEngine;


@interface ViewController : UIViewController{
    AudioEngine *engine;
}

@property (unsafe_unretained, nonatomic) IBOutlet UIButton *marimbaPlayButton;

@property (nonatomic, strong) IBOutlet UIButton *drumButton;

- (IBAction) startPlayMidNote:(id)sender;
- (IBAction) addInstrument:(id)sender;
- (IBAction) playMidi2:(id)sender;
- (IBAction) stopMidi2:(id)sender;
- (IBAction) playMidiFile:(id)sender;
- (IBAction) stopMidiFile:(id)sender;
- (IBAction) resetMidiFile:(id)sender;
- (IBAction) playSequence:(id)sender;
- (IBAction) stopSequence:(id)sender;


- (IBAction)togglePlayMarimba:(id)sender;

@end

