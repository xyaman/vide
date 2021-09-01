#import "Tweak.h"

CSScrollView *lsScrollView = nil;

float adjunctWidth = 0;
float adjunctHeight = 0;

// Temporary fix
UIColor *backgroundColor = nil;
UIColor *tintColor = nil;

NSData *oldArtworkData = nil;

// Only used when artwork color is enabled
%group ArtworkColorNotification
%hook SBMediaController
// This method is for sending the new song artwork
-(void)setNowPlayingInfo:(NSDictionary *)arg1 {
    %orig;

    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
        NSDictionary *info = (__bridge NSDictionary *)(information);

        NSData *artworkData = [info objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData];
        
        if([oldArtworkData isEqualToData:artworkData]) {
            return;
        }

        oldArtworkData = artworkData; 

        if(artworkData) {
            UIImage *artwork = [UIImage imageWithData:artworkData]; // TODO: Check if artwork can be null
            backgroundColor = [Kuro getPrimaryColor:artwork];

            UIColor *tint = [Kuro isDarkImage:artwork] ? [UIColor whiteColor] : [UIColor blackColor];
            tintColor = tint;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:videUpdateColors object:nil userInfo:nil];
    });
}
%end
%end

// Here we save an instance of CSScrollView
// we need it to use swipe gestures, instead of this view pan gestures
%hook CSScrollView
-(instancetype)initWithFrame:(CGRect)frame {
    id orig = %orig;

    lsScrollView = self;

    return orig;
}
%end

// We use this class to get the adjunct size
%hook CSMediaControlsViewController
-(CGRect)_suggestedFrameForMediaControls {
    CGRect rect = %orig;

    if(!adjunctHeight || !adjunctWidth) {
        adjunctHeight = rect.size.height;
        adjunctWidth = rect.size.width;
    } else {
        return rect;
    }

    if(prefLSHideTime) adjunctHeight -= 48;
    if(prefLSHideControls) adjunctHeight -= 55;
    if(prefLSHideVolume) adjunctHeight -= 48;
    return rect;
}
%end

// LS media player main view
%hook CSAdjunctItemView
%property (nonatomic, retain) SNAWaveView *sona;
- (void) didMoveToWindow {
    %orig;
    PLPlatterView *pv = [self valueForKey:@"_platterView"];

    // Alpha
    pv.backgroundView.alpha = [prefLSAlpha floatValue];

    // Radius
    pv.backgroundView.layer.cornerRadius = [prefLSRadius floatValue];
    pv.backgroundView.clipsToBounds = YES;

    // Background color
    if([prefLSBackgroundStyle intValue] == 1) {
        pv.backgroundView.backgroundColor = backgroundColor;
    
    } else if([prefLSBackgroundStyle intValue] == 2) {
        pv.backgroundView.backgroundColor = [GcColorPickerUtils colorWithHex:prefLSCustomColor];
    }

    // Waves
    if(prefLSShowWave && !self.sona) {
        self.sona = [[SNAWaveView alloc] initWithFrame:pv.frame];
        self.sona.coloringStyle = SNAColoringStyleSolid;
        self.sona.yOffset = 20;
        self.sona.alpha = [prefLSWaveAlpha floatValue];
        self.sona.pointSensitivity = [prefLSWaveSens floatValue];
        self.sona.pointNumber = 8;

        if([prefLSWaveColorStyle intValue] == 1) {
            self.sona.pointColor = [Kuro isDarkColor:backgroundColor] ? [Kuro lighterColorForColor:backgroundColor] : [Kuro darkerColorForColor:backgroundColor];;
            [self.sona updateColors];
        
        } else if([prefLSWaveColorStyle intValue] == 2) {
            self.sona.pointColor = [GcColorPickerUtils colorWithHex:prefLSWaveCustomColor];
            [self.sona updateColors]; 
        }

        [pv.backgroundView insertSubview:self.sona atIndex:0];

        if([[%c(SBMediaController) sharedInstance] isPlaying]) [self.sona start];
    }

    if(prefLSShowWave || [prefLSBackgroundStyle intValue] == 1) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:videUpdateColors object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColor:) name:videUpdateColors object:nil];
    }
}

%new
- (void) updateColor:(NSNotification *) notification {
    PLPlatterView *pv = [self valueForKey:@"_platterView"];
    if([prefLSBackgroundStyle intValue] == 1) pv.backgroundView.backgroundColor = backgroundColor;

    if(self.sona) {

        if([[%c(SBMediaController) sharedInstance] isPlaying]) {
            [self.sona start];
        
        } else {
            [self.sona stop];
            self.sona.hidden = NO;
        }

        if([prefLSWaveColorStyle intValue] == 1) {
            self.sona.pointColor = [Kuro isDarkColor:backgroundColor] ? [Kuro lighterColorForColor:backgroundColor] : [Kuro darkerColorForColor:backgroundColor];
            [self.sona updateColors];
        }
    }
}

- (CGSize)intrinsicContentSize {
    if(prefKumquatComp) return %orig;

    self.sona.frame = CGRectMake(0, 0, self.frame.size.width, adjunctHeight);
    // 1000 temp fix
    return CGSizeMake(self.superview.frame.size.width, adjunctHeight);
}

- (void) removeFromSuperview {
    %orig;
    [self.sona stop];
}
%end

/*----------------------
   MRU
   context == 2 LS Media player (Content but no for notification -> CSAdjunctItemView)
   context == 1 (and 0?) CC Media player
 -----------------------*/
%hook MRUNowPlayingView
%property (nonatomic, retain) SNAWaveView *sona;
- (void) didMoveToWindow {
    %orig;

    // LS (not background, radius, alpha, for this check CSAdjunctItemView)
    if(self.context == 2) {
       if(prefLSUseSwipeGestures) [self addSwipeGestures];
    
    // CC (eveything)
    } else if(self.context != 2) {
       if(prefCCUseSwipeGestures) [self addSwipeGestures]; 

        // if([prefCCBackgroundStyle intValue] == 1) {
            // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColor:) name:videUpdateColors object:nil];

        if([prefCCBackgroundStyle intValue] == 2) {
            self.backgroundColor = [GcColorPickerUtils colorWithHex:prefCCCustomColor];
        }

        if(prefCCShowWave && !self.sona) {
            self.sona = [[SNAWaveView alloc] initWithFrame:self.frame];
            self.sona.coloringStyle = SNAColoringStyleSolid;
            self.sona.yOffset = 20;
            self.sona.alpha = [prefCCWaveAlpha floatValue];
            self.sona.pointSensitivity = [prefCCWaveSens floatValue];
            self.sona.pointNumber = 4;

            if([prefCCWaveColorStyle intValue] == 1) {
                self.sona.pointColor = [Kuro isDarkColor:backgroundColor] ? [Kuro lighterColorForColor:backgroundColor] : [Kuro darkerColorForColor:backgroundColor];;
                [self.sona updateColors];
            
            } else if([prefCCWaveColorStyle intValue] == 2) {
                self.sona.pointColor = [GcColorPickerUtils colorWithHex:prefCCWaveCustomColor];
                [self.sona updateColors]; 
            }

            [self insertSubview:self.sona atIndex:0];

            if([[%c(SBMediaController) sharedInstance] isPlaying]) [self.sona start];
        }

        if(prefCCShowWave || [prefCCBackgroundStyle intValue] == 1) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:videUpdateColors object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColor:) name:videUpdateColors object:nil]; 
        }
    }

}

- (void) setFrame:(CGRect) frame {
    %orig;
    if(self.sona) self.sona.frame = frame;
}

%new 
- (void) updateColor:(NSNotification *)notification {
    // NSDictionary *userInfo = [notification userInfo];
    // self.backgroundColor = [userInfo objectForKey:@"background"];
    if([prefCCBackgroundStyle intValue] == 1) self.backgroundColor = backgroundColor;

    if(self.sona) {

        if([[%c(SBMediaController) sharedInstance] isPlaying]) {
            [self.sona start];
        
        } else {
            [self.sona stop];
            self.sona.hidden = NO;
        }

        if([prefCCWaveColorStyle intValue] == 1) {
            self.sona.pointColor = [Kuro isDarkColor:backgroundColor] ? [Kuro lighterColorForColor:backgroundColor] : [Kuro darkerColorForColor:backgroundColor];
            [self.sona updateColors];
        }
    }
}

%new
- (void) addSwipeGestures {
    // Add gestures
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(prevTrack)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:leftSwipe];
    if(self.context == 2) [lsScrollView.panGestureRecognizer requireGestureRecognizerToFail:leftSwipe];

    // Play/Pause
    if(self.context == 2) {;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(play)];
        [self addGestureRecognizer:tap];

        // UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(openPlayingApp)];
        // [self addGestureRecognizer:longTap];
    }

    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextTrack)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:rightSwipe];
    if(self.context == 2) [lsScrollView.panGestureRecognizer requireGestureRecognizerToFail:rightSwipe];
}

%new
- (void) play {
   if(prefLSUseTapticFeedback) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] init];
        [feedback prepare];
        [[%c(SBMediaController) sharedInstance] togglePlayPauseForEventSource:0];
        [feedback impactOccurred]; 
        return;
    }    

    [[%c(SBMediaController) sharedInstance] togglePlayPauseForEventSource:0]; 
}

// %new
// - (void) openPlayingApp {
//     SBApplication *nowPlayingApp = [[%c(SBMediaController) sharedInstance] nowPlayingApplication];
// 	if(nowPlayingApp) {
// 		[[UIApplication sharedApplication] launchApplicationWithIdentifier:nowPlayingApp.bundleIdentifier suspended:NO];
// 	}
// }

%new
- (void) prevTrack {
    if(self.context == 2 && prefLSUseTapticFeedback) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] init];
        [feedback prepare];
        [[%c(SBMediaController) sharedInstance] changeTrack:-1 eventSource:0];
        [feedback impactOccurred]; 

        return;
    
    } else if(self.context != 2 && prefCCUseTapticFeedback) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] init];
        [feedback prepare];
        [[%c(SBMediaController) sharedInstance] changeTrack:-1 eventSource:0];
        [feedback impactOccurred]; 

        return; 
    }

    [[%c(SBMediaController) sharedInstance] changeTrack:-1 eventSource:0];

}

%new
- (void) nextTrack {
    if(self.context == 2 && prefLSUseTapticFeedback) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] init];
        [feedback prepare];
        [[%c(SBMediaController) sharedInstance] changeTrack:1 eventSource:0];
        [feedback impactOccurred]; 

        return;
    
    } else if(self.context != 2 && prefCCUseTapticFeedback) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] init];
        [feedback prepare];
        [[%c(SBMediaController) sharedInstance] changeTrack:1 eventSource:0];
        [feedback impactOccurred]; 

        return; 
    }

    [[%c(SBMediaController) sharedInstance] changeTrack:1 eventSource:0];
}

%end

// Song artwork
%hook MRUArtworkView
- (void) didMoveToWindow {
    %orig;

    self.clipsToBounds = YES;

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    if(![controller respondsToSelector:@selector(context)]) return;
    long long context = controller.context;

    // LS
    if(context == 2) {
        self.layer.cornerRadius = [prefLSArtworkRadius floatValue];

    // CC (in this case same as else, but just for maintain the same style)
    } else if(context != 2) {
        self.layer.cornerRadius = [prefCCArtworkRadius floatValue];
    }
}

// hide src icon
-(void) setIconImage:(UIImage *)arg1 {

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    if(![controller respondsToSelector:@selector(context)]) return %orig;
    long long context = controller.context;

    // LS
    if(context == 2 && prefLSHideSourceIcon) {
        return %orig(nil);

    // CC
    } else if(context != 2 && prefCCHideSourceIcon) {
        return %orig(nil);
    }

    %orig;
}
%end

// Media player labels
%hook MRUNowPlayingLabelView
- (void) updateVisualStyling {
    %orig;

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    if(![controller respondsToSelector:@selector(context)]) return;
    long long context = controller.context;

    // LS
    if(context == 2) {
        if([prefLSTintStyle intValue] == 1) {
            [self colorLabels:tintColor];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:videUpdateColors object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTint:) name:videUpdateColors object:nil];
        
        } else if([prefLSTintStyle intValue] == 2) {
            UIColor *tint = [GcColorPickerUtils colorWithHex:prefCCTintCustomColor];
            [self colorLabels:tint];
        }

    // CC
    } else if(context != 2) {

        if([prefCCTintStyle intValue] == 1) {
            [self colorLabels:tintColor];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:videUpdateColors object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTint:) name:videUpdateColors object:nil];
        
        } else if([prefCCTintStyle intValue] == 2) {
            UIColor *tint = [GcColorPickerUtils colorWithHex:prefCCTintCustomColor];
            [self colorLabels:tint];
        }
    }
}

%new
- (void) updateTint:(NSNotification *)notification {

    // NSDictionary *userInfo = [notification userInfo];
    // [self colorLabels:[userInfo objectForKey:@"tint"]];

    [self colorLabels:tintColor];
}


%new
- (void) colorLabels:(UIColor *)tint {

    if(self.routeLabel.layer.filters.count) self.routeLabel.layer.filters = nil;
    if(self.routeLabel.titleLabel.layer.filters.count) self.routeLabel.titleLabel.layer.filters = nil;
    self.routeLabel.textColor = tint;
    self.routeLabel.titleLabel.textColor = tint;

    if(self.titleLabel.layer.filters.count) self.titleLabel.layer.filters = nil;
    self.titleLabel.textColor = tint;

    if(self.subtitleLabel.layer.filters.count) self.subtitleLabel.layer.filters = nil;
    self.subtitleLabel.textColor = tint;
}
%end

// Media player airplay
%hook MRUNowPlayingRoutingButton
%property (nonatomic, retain) UIVisualEffectView *blurView;

- (void) didMoveToWindow {
    %orig;

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    if(![controller respondsToSelector:@selector(context)]) return;
    long long context = controller.context;

    if(context == 2) {

        // if([prefLSTintStyle intValue] == 1) {

        //     if(self.imageView.layer.filters.count) self.imageView.layer.filters = nil;
        //     self.imageView.tintColor = tintColor;
            
        //     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTint:) name:videUpdateColors object:nil];
        
        // } else if([prefLSTintStyle intValue] == 2) {
        //     // UIColor *tint = [GcColorPickerUtils colorWithHex:prefLSTintCustomColor];
        //     // [self colorLabels:tint];
        // }
        

        if(prefLSAirplayBlur && !self.blurView) {
            self.backgroundColor = [UIColor clearColor];
            // self.layer.cornerRadius = self.frame.size.width / 2;
            // self.clipsToBounds = YES;

            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            self.blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            self.blurView.userInteractionEnabled = NO;
        
            self.blurView.frame = self.bounds;
            self.blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

            [self insertSubview:self.blurView atIndex:0];
        }
    }
}

- (void) setFrame:(CGRect) frame {
    %orig;
    self.layer.cornerRadius = self.frame.size.width / 2;
    self.clipsToBounds = YES;
}

// %new
// - (void) updateTint:(NSNotification *) notication {
//     if(self.imageView.layer.filters.count) self.imageView.layer.filters = nil;
//     self.imageView.tintColor = tintColor; 
// }

%end

// Media player time slider
%hook MRUNowPlayingTimeControlsView
- (void) didMoveToWindow {
    %orig;
    
    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    long long context = controller.context;

    // LS
    if(context == 2) {
        if(prefLSHideTime) self.hidden = YES;

        if([prefLSTintStyle intValue] == 1) {
            self.elapsedTrack.backgroundColor = tintColor; 
            [[NSNotificationCenter defaultCenter] removeObserver:self name:videUpdateColors object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTint:) name:videUpdateColors object:nil];
        
        } else if([prefLSTintStyle intValue] == 2) {
            self.elapsedTrack.backgroundColor = [GcColorPickerUtils colorWithHex:prefLSTintCustomColor];
        }

    // CC
    } else if(context != 2) {
        if(prefCCHideTime) self.hidden = YES;

        if([prefCCTintStyle intValue] == 1) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:videUpdateColors object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTint:) name:videUpdateColors object:nil];
        
        } else if([prefCCTintStyle intValue] == 2) {
            self.elapsedTrack.backgroundColor = [GcColorPickerUtils colorWithHex:prefCCTintCustomColor];
        }
    }
}

%new
- (void) updateTint:(NSNotification *)notification {

    // NSDictionary *userInfo = [notification userInfo];
    // self.elapsedTrack.backgroundColor = [userInfo objectForKey:@"tint"];

    self.elapsedTrack.backgroundColor = tintColor;
}
%end

// Media player controls
%hook MRUNowPlayingTransportControlsView
- (void) didMoveToWindow {
    %orig;

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    long long context = controller.context;

    // LS
    if(context == 2) {
        if(prefLSHideControls) self.hidden = YES;

        if([prefLSTintStyle intValue] == 1) {
            [self changeButtonsColor:tintColor];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:videUpdateColors object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTint:) name:videUpdateColors object:nil];
        
        } else if([prefLSTintStyle intValue] == 2) {
            UIColor *tint = [GcColorPickerUtils colorWithHex:prefLSTintCustomColor];
            [self changeButtonsColor:tint];
        }
    
    // CC
    } else if(context != 2) {
        if(prefCCHideControls) self.hidden = YES;

        if([prefCCTintStyle intValue] == 1) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:videUpdateColors object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTint:) name:videUpdateColors object:nil];
        
        } else if([prefCCTintStyle intValue] == 2) {
            UIColor *tint = [GcColorPickerUtils colorWithHex:prefCCTintCustomColor];
            [self changeButtonsColor:tint];
        }
    }

}

- (void) setFrame:(CGRect)frame {

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    long long context = controller.context;

    float newY = frame.origin.y;

    if(context == 2) {
        if(prefLSHideTime) newY -= 44;
    } else {
        // if(prefCCHideTime) newY -= 44;
    }
    return %orig(CGRectMake(frame.origin.x, newY, frame.size.width, frame.size.height));;
}

%new
- (void) updateTint:(NSNotification *)notification {

    // NSDictionary *userInfo = [notification userInfo];
    // [self changeButtonsColor:[userInfo objectForKey:@"tint"]];

    [self changeButtonsColor:tintColor];
}

%new
- (void) changeButtonsColor:(UIColor *)tint {
    [self.leftButton setStylingProvider:nil];
    [self.middleButton setStylingProvider:nil];
    [self.rightButton setStylingProvider:nil];


    if(self.leftButton.imageView.layer.filters.count) self.leftButton.imageView.layer.filters = nil;
    self.leftButton.imageView.tintColor = tint;

    if(self.middleButton.imageView.layer.filters.count) self.middleButton.imageView.layer.filters = nil;
    self.middleButton.imageView.tintColor = tint;

    if(self.rightButton.imageView.layer.filters.count) self.rightButton.imageView.layer.filters = nil;
    self.rightButton.imageView.tintColor = tint;
}
%end



// Media player volume slider
%hook MRUNowPlayingVolumeControlsView

- (void) didMoveToWindow {
    %orig;


    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    long long context = controller.context;

    // LS
    if(context == 2) {
        if(prefLSHideVolume) self.hidden = YES;

        if([prefLSTintStyle intValue] == 1) {
            self.slider.minimumTrackTintColor = tintColor;
            [[NSNotificationCenter defaultCenter] removeObserver:self name:videUpdateColors object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTint:) name:videUpdateColors object:nil];
        
        } else if([prefLSTintStyle intValue] == 2) {
            self.slider.minimumTrackTintColor = [GcColorPickerUtils colorWithHex:prefLSTintCustomColor];
        }

    // CC
    } else if(context != 2) {
        if(prefCCHideVolume) self.hidden = YES;

        if([prefCCTintStyle intValue] == 1) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:videUpdateColors object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTint:) name:videUpdateColors object:nil];
        
        } else if([prefCCTintStyle intValue] == 2) {
            self.slider.minimumTrackTintColor = [GcColorPickerUtils colorWithHex:prefCCTintCustomColor];
        }
    }
}

%new
- (void) updateTint:(NSNotification *)notification {

    // NSDictionary *userInfo = [notification userInfo];
    // self.slider.minimumTrackTintColor = [userInfo objectForKey:@"tint"];

    self.slider.minimumTrackTintColor = tintColor;
}

- (void) setFrame:(CGRect) frame {

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    long long context = controller.context;

    float newY = frame.origin.y;

    if(context == 2) {
        if(prefLSHideTime) newY -= 44;
        if(prefLSHideControls) newY -= 54;
    
    } else {
        if(prefCCHideTime) newY -= 44;
        if(prefCCHideControls) newY -= 54;
    }

    return %orig(CGRectMake(frame.origin.x, newY, frame.size.width, frame.size.height));
}

%end


%ctor {
    preferences = [[HBPreferences alloc] initWithIdentifier:@"com.xyaman.videpreferences"];

    [preferences registerBool:&isEnabled default:NO forKey:@"isEnabled"];
    if(!isEnabled) return;

    [preferences registerBool:&prefKumquatComp default:NO forKey:@"kumquatComp"];

    // LS Swipe gestures
    [preferences registerBool:&prefLSUseSwipeGestures default:NO forKey:@"LSUseSwipeGestures"];
    [preferences registerBool:&prefLSUseTapticFeedback default:YES forKey:@"LSUseTapticFeedback"];

    // LS player radius
    [preferences registerObject:&prefLSRadius default:@"13" forKey:@"LSRadius"];
    [preferences registerBool:&prefLSAirplayBlur default:NO forKey:@"LSAirplayBlur"];

    // LS player coloring
    [preferences registerObject:&prefLSBackgroundStyle default:0 forKey:@"LSBackgroundStyle"];
    [preferences registerObject:&prefLSCustomColor default:@"000000" forKey:@"LSCustomColor"];
    [preferences registerObject:&prefLSTintStyle default:0 forKey:@"LSTintStyle"];
    [preferences registerObject:&prefLSTintCustomColor default:@"000000" forKey:@"LSTintCustomColor"];

    // LS Wave
    [preferences registerBool:&prefLSShowWave default:NO forKey:@"LSShowWave"];
    [preferences registerObject:&prefLSWaveColorStyle default:@(1) forKey:@"LSWaveColorStyle"];
    [preferences registerObject:&prefLSWaveCustomColor default:@"000000" forKey:@"LSWaveCustomColor"];
    [preferences registerObject:&prefLSWaveSens default:@(4) forKey:@"LSWaveSens"];
    [preferences registerObject:&prefLSWaveAlpha default:@(0.6) forKey:@"LSWaveAlpha"];

    // LS Hiding
    [preferences registerBool:&prefLSHideTime default:YES forKey:@"LSHideTime"];
    [preferences registerBool:&prefLSHideControls default:NO forKey:@"LSHideControls"];
    [preferences registerBool:&prefLSHideVolume default:YES forKey:@"LSHideVolume"];

    // Media player alpha
    [preferences registerObject:&prefLSAlpha default:@"1.0" forKey:@"LSAlpha"];

    // Song artwork
    [preferences registerObject:&prefLSArtworkRadius default:@"0" forKey:@"LSArtworkRadius"];
    [preferences registerBool:&prefLSHideSourceIcon default:NO forKey:@"LSHideSourceIcon"];


    // CC swipe gestures
    [preferences registerBool:&prefCCUseSwipeGestures default:NO forKey:@"CCUseSwipeGestures"];
    [preferences registerBool:&prefCCUseTapticFeedback default:YES forKey:@"CCUseTapticFeedback"];

    // CC wave
    [preferences registerBool:&prefCCShowWave default:NO forKey:@"CCShowWave"];
    [preferences registerObject:&prefCCWaveColorStyle default:@(1) forKey:@"CCWaveColorStyle"];
    [preferences registerObject:&prefCCWaveCustomColor default:@"000000" forKey:@"CCWaveCustomColor"];
    [preferences registerObject:&prefCCWaveSens default:@(4) forKey:@"CCWaveSens"];
    [preferences registerObject:&prefCCWaveAlpha default:@(0.6) forKey:@"CCWaveAlpha"];

    // CC Hiding
    [preferences registerBool:&prefCCHideTime default:NO forKey:@"CCHideTime"];
    [preferences registerBool:&prefCCHideControls default:NO forKey:@"CCHideControls"];
    [preferences registerBool:&prefCCHideVolume default:NO forKey:@"CCHideVolume"];

    // CC coloring
    [preferences registerObject:&prefCCBackgroundStyle default:@"0" forKey:@"CCBackgroundStyle"];
    [preferences registerObject:&prefCCCustomColor default:@"000000" forKey:@"CCCustomColor"];
    [preferences registerObject:&prefCCTintStyle default:@(0) forKey:@"CCTintStyle"];
    [preferences registerObject:&prefCCTintCustomColor default:@"000000" forKey:@"CCTintCustomColor"];

    // CC Song artwork
    [preferences registerObject:&prefCCArtworkRadius default:@"0" forKey:@"CCArtworkRadius"];
    [preferences registerBool:&prefCCHideSourceIcon default:NO forKey:@"CCHideSourceIcon"];

    backgroundColor = [UIColor whiteColor];
    tintColor = [UIColor whiteColor];

    %init;
    if([prefLSBackgroundStyle intValue] == 1 || [prefCCBackgroundStyle intValue] == 1 || prefLSShowWave) %init(ArtworkColorNotification);
}