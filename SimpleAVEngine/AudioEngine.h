//
//  AudioEngine.h
//  
//
//  Created by Thierry Sansaricq on 7/21/15.
//
//

#import <Foundation/Foundation.h>
//@import AVFoundation;

#ifndef _AudioEngine_h
#define _AudioEngine_h


#endif


@protocol AudioEngineDelegate <NSObject>

@optional
- (void)engineWasInterrupted;
- (void)engineConfigurationHasChanged;
- (void)mixerOutputFilePlayerHasStopped;

@end


@interface AudioEngine : NSObject


@property (weak) id<AudioEngineDelegate> delegate;


- (void)toggleMarimba;
- (void)playMidiNote;
- (void)playMidiNote2;
- (void)stopMidiNote2;
- (void)addInstrument;
- (void)removeInstrument;
- (void)playMidiFile;
- (void)stopMidiFile;
- (void)resetMidiFilePosition;

- (void)handleInterruption:(NSNotification *)notification;
- (void)handleRouteChange:(NSNotification *)notification;
- (void)handleMediaServicesReset:(NSNotification *)notification;

@end

