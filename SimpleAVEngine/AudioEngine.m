//
//  AudioEngine.m
//  
//
//  Created by Thierry Sansaricq on 7/21/15.
//
//

#import "AudioEngine.h"

@import AVFoundation;
@import Accelerate;

@interface AudioEngine() {
    AVAudioEngine       *_engine;
    AVAudioPlayerNode   *_marimbaPlayer;
    
    //AVAudioPlayerNode   *_drumPlayer;
    //AVAudioUnitDelay    *_delay;
    //AVAudioUnitReverb   *_reverb;
    AVAudioPCMBuffer    *_marimbaLoopBuffer;
    AVAudioUnitSampler  *_midiInstrument;
    AVAudioUnitSampler  *_midiInstrument2;
    AVMIDIPlayer        *_midiPlayer;
    
    //AVAudioPCMBuffer    *_drumLoopBuffer;
    
    
    unsigned int        _numInstruments;
    
    // for the node tap
    //NSURL               *_mixerOutputFileURL;
    //AVAudioPlayerNode   *_mixerOutputFilePlayer;
    //BOOL                _mixerOutputFilePlayerIsPaused;
    //BOOL                _isRecording;
}


//- (void)handleInterruption:(NSNotification *)notification;
//- (void)handleRouteChange:(NSNotification *)notification;


@end


#pragma mark AudioEngine implementation

@implementation AudioEngine


- (instancetype)init
{
    if (self = [super init]) {
        
        
        NSError *error;
        
        _numInstruments = 0;
        
        _marimbaPlayer = [[AVAudioPlayerNode alloc] init];
        _midiInstrument = [[AVAudioUnitSampler alloc] init];
        _midiInstrument2 = [[AVAudioUnitSampler alloc] init];
        
        
        // create an instance of the engine and attach the nodes
        [self createEngineAndAttachNodes];
       
       
        NSURL *sampleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"shakyC2" ofType:@"aupreset"]];
        //NSURL *sampleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"defaultInstrument" ofType:@"aupreset"]];
        [_midiInstrument loadInstrumentAtURL:sampleURL error:&error];
        
        
        [self addInstrument];
        
        
        // load marimba loop
        NSURL *marimbaLoopURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"marimbaLoop" ofType:@"caf"]];
        AVAudioFile *marimbaLoopFile = [[AVAudioFile alloc] initForReading:marimbaLoopURL error:&error];
        _marimbaLoopBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:[marimbaLoopFile processingFormat] frameCapacity:(AVAudioFrameCount)[marimbaLoopFile length]];
        NSAssert([marimbaLoopFile readIntoBuffer:_marimbaLoopBuffer error:&error], @"couldn't read marimbaLoopFile into buffer, %@", [error localizedDescription]);
        
        
        
        //Read in a .mid file
        //NSURL *midiContentURL;
        
       
        NSURL *midiFileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Bee_Gees_-_Jive_Talkin'" ofType:@"mid"]];
        //NSURL *sbURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"organ'" ofType:@"sf2"]];
        NSURL *sbURL = [[NSBundle mainBundle] URLForResource:@"Yamaha_XG_Sound_Set" withExtension:@"sf2"];
        NSData *midiData = [NSData dataWithContentsOfFile:[midiFileURL path]];

       
        NSAssert(_midiPlayer = [[AVMIDIPlayer alloc] initWithData:midiData soundBankURL:sbURL error:&error],@"couldn't initialize midiPlayer", "%@",[error localizedDescription]);
        if(_midiPlayer)
            [_midiPlayer prepareToPlay];
       
        
       
        
        // sign up for notifications from the engine if there's a hardware config change
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioEngineConfigurationChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            // if we've received this notification, something has changed and the engine has been stopped
            // re-wire all the connections and start the engine
            NSLog(@"Received a %@ notification!", AVAudioEngineConfigurationChangeNotification);
            NSLog(@"Re-wiring connections and starting once again");
            [self makeEngineConnections];
            [self startEngine];
            
            
            // post notification
            if ([self.delegate respondsToSelector:@selector(engineConfigurationHasChanged)]) {
                [self.delegate engineConfigurationHasChanged];
            }
            
            
        }];
        
        
        // AVAudioSession setup
        [self initAVAudioSession];
        
        // make engine connections
        [self makeEngineConnections];
       
        [self startEngine];
        
              //[_marimbaPlayer scheduleBuffer:_marimbaLoopBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
        //[_marimbaPlayer play];

        /*
        _marimbaPlayer.volume = 1.0;
        _engine.mainMixerNode.outputVolume = 1.0;
        */
        
        //[self playMidiNote];
    }
    
    
    return self;
        
}

- (void)startEngine
{
    // start the engine
    
    /*  startAndReturnError: calls prepare if it has not already been called since stop.
     
     Starts the audio hardware via the AVAudioInputNode and/or AVAudioOutputNode instances in
     the engine. Audio begins flowing through the engine.
     
     This method will return YES for sucess.
     
     Reasons for potential failure include:
     
     1. There is problem in the structure of the graph. Input can't be routed to output or to a
     recording tap through converter type nodes.
     2. An AVAudioSession error.
     3. The driver failed to start the hardware. */
    
    if (!_engine.isRunning) {
        NSError *error;
        /*
         [_engine startAndReturnError:&error];
        if (error) {
            NSLog(@"couldn't start engine, %@", [error localizedDescription]);
        }
         */
        NSAssert([_engine startAndReturnError:&error], @"couldn't start engine, %@", [error localizedDescription]);
    }
}


- (void)createEngineAndAttachNodes
{
    /*  An AVAudioEngine contains a group of connected AVAudioNodes ("nodes"), each of which performs
     an audio signal generation, processing, or input/output task.
     
     Nodes are created separately and attached to the engine.
     
     The engine supports dynamic connection, disconnection and removal of nodes while running,
     with only minor limitations:
     - all dynamic reconnections must occur upstream of a mixer
     - while removals of effects will normally result in the automatic connection of the adjacent
     nodes, removal of a node which has differing input vs. output channel counts, or which
     is a mixer, is likely to result in a broken graph. */
    
    _engine = [[AVAudioEngine alloc] init];
    
    /*  To support the instantiation of arbitrary AVAudioNode subclasses, instances are created
     externally to the engine, but are not usable until they are attached to the engine via
     the attachNode method. */
    
    [_engine attachNode:_marimbaPlayer];
    [_engine attachNode:_midiInstrument];
    [_engine attachNode:_midiInstrument2];
    
    
    //[_engine attachNode:_drumPlayer];
    //[_engine attachNode:_delay];
    //[_engine attachNode:_reverb];
    //[_engine attachNode:_mixerOutputFilePlayer];
}


#pragma mark AVAudioSession

- (void)initAVAudioSession
{
    // For complete details regarding the use of AVAudioSession see the AVAudioSession Programming Guide
    // https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html
    
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    NSError *error;
    
    // set the session category
    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);
    
    double hwSampleRate = 44100.0;
    success = [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
    if (!success) NSLog(@"Error setting preferred sample rate! %@\n", [error localizedDescription]);
    
    NSTimeInterval ioBufferDuration = 0.0029;
    success = [sessionInstance setPreferredIOBufferDuration:ioBufferDuration error:&error];
    if (!success) NSLog(@"Error setting preferred io buffer duration! %@\n", [error localizedDescription]);
    
    
    // add interruption handler
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:sessionInstance];
    
    // we don't do anything special in the route change notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:sessionInstance];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaServicesReset:)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
                                               object:sessionInstance];
    
    
    // activate the audio session
    success = [sessionInstance setActive:YES error:&error];
    if (!success) NSLog(@"Error setting session active! %@\n", [error localizedDescription]);
}


- (void)makeEngineConnections
{
    /*  The engine will construct a singleton main mixer and connect it to the outputNode on demand,
     when this property is first accessed. You can then connect additional nodes to the mixer.
     
     By default, the mixer's output format (sample rate and channel count) will track the format
     of the output node. You may however make the connection explicitly with a different format. */
    
    // get the engine's optional singleton main mixer node
    AVAudioMixerNode *mainMixer = [_engine mainMixerNode];
    
    // establish a connection between nodes
    
    /*  Nodes have input and output buses (AVAudioNodeBus). Use connect:to:fromBus:toBus:format: to
     establish connections betweeen nodes. Connections are always one-to-one, never one-to-many or
     many-to-one.
     
     Note that any pre-existing connection(s) involving the source's output bus or the
     destination's input bus will be broken.
     
     @method connect:to:fromBus:toBus:format:
     @param node1 the source node
     @param node2 the destination node
     @param bus1 the output bus on the source node
     @param bus2 the input bus on the destination node
     @param format if non-null, the format of the source node's output bus is set to this
     format. In all cases, the format of the destination node's input bus is set to
     match that of the source node's output bus. */
    
    [_engine connect:_marimbaPlayer to:mainMixer format:_marimbaLoopBuffer.format];
    
    /* 
        http://www.tmroyal.com/using-avaudiounitsampler-in-swift.html
     */
    
    [_engine connect:_midiInstrument to:mainMixer format:[_midiInstrument outputFormatForBus:0]];
    _numInstruments++;
    
    
    
    [_engine connect:_midiInstrument2 to:mainMixer format:[_midiInstrument2 outputFormatForBus:0]];
    _numInstruments++;
    
    // marimba player -> delay -> main mixer
    //[_engine connect: _marimbaPlayer to:_delay format:_marimbaLoopBuffer.format];
    //[_engine connect:_delay to:mainMixer format:_marimbaLoopBuffer.format];
    
    // drum player -> reverb -> main mixer
    //[_engine connect:_drumPlayer to:_reverb format:_drumLoopBuffer.format];
    //[_engine connect:_reverb to:mainMixer format:_drumLoopBuffer.format];
    
    // node tap player
    //[_engine connect:_mixerOutputFilePlayer to:mainMixer format:[mainMixer outputFormatForBus:0]];
}

- (void)toggleMarimba {
    if (!_marimbaPlayer.isPlaying) {
        [self startEngine];
        [_marimbaPlayer scheduleBuffer:_marimbaLoopBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
        [_marimbaPlayer play];
    } else
        [_marimbaPlayer stop];
}

- (void)playMidiNote{
    /*
     http://stackoverflow.com/questions/24230668/avaudiounitsampler-error-loadsoundbankaturl-unable-to-find-patch-0-bank-0x0-0
     http://www.tmroyal.com/using-avaudiounitsampler-in-swift.html
    */
    //[_midiInstrument startNote:45 withVelocity:80 onChannel:1];
    [_midiInstrument startNote:36 withVelocity:127 onChannel:1];
    
}

- (void)playMidiNote2{
    /*
     http://stackoverflow.com/questions/24230668/avaudiounitsampler-error-loadsoundbankaturl-unable-to-find-patch-0-bank-0x0-0
     http://www.tmroyal.com/using-avaudiounitsampler-in-swift.html
     */
    //[_midiInstrument startNote:45 withVelocity:80 onChannel:1];
    [_midiInstrument2 startNote:60 withVelocity:127 onChannel:1];
    
}

- (void)stopMidiNote2{
    [_midiInstrument2 stopNote:60 onChannel:1];
}


- (void)addInstrument{
    
    if(_numInstruments >= 2){
        return;
    }
    
    NSError *error;
    
    
    //if(!_midiInstrument2){
        
        /*
        NSURL *sampleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"defaultInstrument3" ofType:@"aupreset"]];

        [_midiInstrument2 loadInstrumentAtURL:sampleURL error:&error];
   */
        
        //NSURL *midiFileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Bee_Gees_-_Jive_Talkin'" ofType:@"mid"]];
        //NSURL *sbURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"organ'" ofType:@"sf2"]];
        NSURL *sbURL = [[NSBundle mainBundle] URLForResource:@"Yamaha_XG_Sound_Set" withExtension:@"sf2"];
        //NSData *midiData = [NSData dataWithContentsOfFile:[midiFileURL path]];
        
        /*
         @param bankURL
         URL for a Soundbank file. The file can be either a DLS bank (.dls) or a SoundFont bank (.sf2).
         @param program
         program number for the instrument to load
         @param bankMSB
         MSB for the bank number for the instrument to load.  This is usually 0x79 for melodic
         instruments and 0x78 for percussion instruments.
         @param bankLSB
         LSB for the bank number for the instrument to load.  This is often 0, and represents the "bank variation".
         @param outError
         the status of the operation
         */
        [_midiInstrument2 loadSoundBankInstrumentAtURL:sbURL program:0 bankMSB:0x79 bankLSB:0 error:&error];
        

    
    
        /*
        // get the engine's optional singleton main mixer node
        AVAudioMixerNode *mainMixer = [_engine mainMixerNode];
    
    
        [_engine connect:_midiInstrument2 to:mainMixer format:[_midiInstrument2 outputFormatForBus:0]];
        */
    //}
    
    
    
}

- (void)removeInstrument{

}

- (void)playMidiFile{
    if(_midiPlayer.playing){
        return;
        //[_midiPlayer stop];
    }
    
    
    [_midiPlayer play:^{
        //<#code#>
        //NSTimeInterval t = 0.1;
        //_midiPlayer.currentPosition = t;
        NSLog(@"midiPlayer completion block was called");
    }];
    

}

- (void)stopMidiFile{
    if(_midiPlayer.playing){
        [_midiPlayer stop];
    }
}

- (void)resetMidiFilePosition{

    //NSTimeInterval t = 0.0;
    _midiPlayer.currentPosition = 0.0;
}


#pragma mark notifications

- (void)handleInterruption:(NSNotification *)notification
{
    UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    
    NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
    
    if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
        //[_drumPlayer stop];
        [_marimbaPlayer stop];
        //[self stopPlayingRecordedFile];
        //[self stopRecordingMixerOutput];
        
        if ([self.delegate respondsToSelector:@selector(engineWasInterrupted)]) {
            [self.delegate engineWasInterrupted];
        }
        
    }
    if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
        // make sure to activate the session
        NSError *error;
        bool success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (!success) NSLog(@"AVAudioSession set active failed with error: %@", [error localizedDescription]);
        
        // start the engine once again
        [self startEngine];
    }
}

- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
}

- (void)handleMediaServicesReset:(NSNotification *)notification
{
    // if we've received this notification, the media server has been reset
    // re-wire all the connections and start the engine
    NSLog(@"Media services have been reset!");
    NSLog(@"Re-wiring connections and starting once again");
    
    [self createEngineAndAttachNodes];
    [self initAVAudioSession];
    [self makeEngineConnections];
    [self startEngine];
    
    
    // post notification
    if ([self.delegate respondsToSelector:@selector(engineConfigurationHasChanged)]) {
        [self.delegate engineConfigurationHasChanged];
    }
    
    
}



@end
