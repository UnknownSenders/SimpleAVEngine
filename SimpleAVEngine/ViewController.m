//
//  ViewController.m
//  SimpleAVEngine
//
//  Created by Thierry Sansaricq on 7/21/15.
//  Copyright (c) 2015 Thierry Sansaricq. All rights reserved.
//

#import "ViewController.h"
#import "AudioEngine.h"


@interface ViewController () <AudioEngineDelegate>

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    engine = [[AudioEngine alloc] init];
    engine.delegate = self;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)togglePlayMarimba:(id)sender {
    [engine toggleMarimba];
    
    //[self styleButton: _marimbaPlayButton isPlaying: engine.marimbaPlayerIsPlaying];
}

// Play the mid note
- (IBAction) startPlayMidNote:(id)sender {
    [engine playMidiNote];
}

//add the second instrument
- (IBAction)addInstrument:(id)sender{
    //[engine addInstrument];
}

- (IBAction)playMidi2:(id)sender{
    [engine playMidiNote2];
}

- (IBAction)stopMidi2:(id)sender{

    [engine stopMidiNote2];
}

- (IBAction)playMidiFile:(id)sender{
    [engine playMidiFile];
}

- (IBAction)stopMidiFile:(id)sender{
    [engine stopMidiFile];
}

- (IBAction)resetMidiFile:(id)sender{
    [engine resetMidiFilePosition];
}

#pragma mark protocol methos

- (void)engineConfigurationHasChanged
{
    //[self updateUIElements];
}

- (void)engineWasInterrupted
{
    /*
    _playing = NO;
    _recording = NO;
    [self updateUIElements];
     */
}

- (void)mixerOutputFilePlayerHasStopped
{
    /*
    _playing = NO;
    [self updateButtonStates];
     */
}



@end
