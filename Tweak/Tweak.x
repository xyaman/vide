#import "Tweak.h"

// Background color globals
NSData *prevArtworkData = nil;
UIColor *artworkPrimaryColor = nil;
UIColor *artworkForegroundColor = nil;

%hook SBMediaController
// This method is for sending the new song artwork
-(void)setNowPlayingInfo:(NSDictionary *)arg1 {
    %orig;

    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
        NSDictionary *info = (__bridge NSDictionary *)(information);
        NSData *artworkData = [info objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData];
        
        // This method is called many times, we want to update colors only when received data is different than the old one
        if(!artworkData || [prevArtworkData isEqualToData:artworkData]) return;
        prevArtworkData = artworkData; 

        UIImage *artwork = [UIImage imageWithData:artworkData];
        artworkPrimaryColor = [Kuro getPrimaryColor:artwork];
        artworkForegroundColor = [Kuro isDarkImage:artwork] ? [UIColor whiteColor] : [UIColor blackColor];

        [[NSNotificationCenter defaultCenter] postNotificationName:videArtworkChanged object:nil userInfo:nil];
    });
}
%end

%hook CSMediaControlsViewController
-(CGRect)_suggestedFrameForMediaControls {
    CGRect rect = %orig;
    return rect;
}

-(void)setContainerSize:(CGSize)arg0 {
    %orig;
}
%end

/*----------------------
  Lockscreen media player
 -----------------------*/
%hook CSAdjunctItemView

- (void) didMoveToWindow {
    PLPlatterView *pv = [self valueForKey:@"_platterView"];

    // Alpha
    pv.backgroundView.alpha = [prefLSAlpha floatValue];

    // Radius
    self.layer.cornerRadius = [prefLSRadius floatValue];
    self.clipsToBounds = YES;
    // pv.backgroundView.clipsToBounds = YES;

    // Background Coloring
    // Its not optimal, but we need to update background color here, instead of doing on MRUNowPlayingView
    // to have a better user experience
    if([prefLSBackgroundStyle intValue] == 1) { // Adaptive
        pv.backgroundView.backgroundColor = artworkPrimaryColor; // TODO: Update this
        [[NSNotificationCenter defaultCenter] removeObserver:self name:videArtworkChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBackground) name:videArtworkChanged object:nil];

    } else if([prefLSBackgroundStyle intValue] == 2) { // Custom user color
        pv.backgroundView.backgroundColor = [GcColorPickerUtils colorWithHex:prefLSCustomColor];
    }
        
}

%new
- (void) updateBackground {
    PLPlatterView *pv = [self valueForKey:@"_platterView"];
    pv.backgroundView.backgroundColor = artworkPrimaryColor; // TODO: Update this
}

// Size for LS UIStackView
- (CGSize)intrinsicContentSize {
    CGSize originalRect = %orig;

    return originalRect;
}
%end

/*----------------------
  MRU
  context == 2 LS Media player (Content but no for notification -> CSAdjunctItemView)
  context == 1 (and 0?) CC Media player
 -----------------------*/
%hook MRUNowPlayingView
- (void) didMoveToWindow {
    %orig;

    // Lockscreen
    if(self.context == 2) {
        // Radius (We also need to round view corner, mainly because sona)
        self.layer.cornerRadius = [prefLSRadius floatValue];
        self.clipsToBounds = YES;

        // Background is set on CSAdjunctItemView
        

    // CC
    } else {

        if([prefCCBackgroundStyle intValue] == 1) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColors) name:videArtworkChanged object:nil];
        }

        if([prefCCBackgroundStyle intValue] == 2) { // Custom user color
            self.backgroundColor = [GcColorPickerUtils colorWithHex:prefCCCustomColor];
        }
    }
}

%new
- (void) updateColors {
    self.backgroundColor = artworkPrimaryColor;
}
%end

/*----------------------
  Song artwork
 -----------------------*/
%hook MRUArtworkView
- (void) didMoveToWindow {
    %orig;

    self.clipsToBounds = YES;

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    if(![controller respondsToSelector:@selector(context)]) return;

    // LS
    if(controller.context == 2) {
        self.layer.cornerRadius = [prefLSArtworkRadius floatValue];

    // CC 
    } else {
        self.layer.cornerRadius = [prefCCArtworkRadius floatValue];
    }
}

// hide src icon
-(void) setIconImage:(UIImage *)arg1 {

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    if(![controller respondsToSelector:@selector(context)]) return %orig;

    // LS
    if(controller.context == 2 && prefLSHideSourceIcon) {
        return %orig(nil);

    // CC
    } else if(controller.context != 2 && prefCCHideSourceIcon) {
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

    // LS
    if(controller.context == 2) {

        if([prefLSTintStyle intValue] == 1) { // Based on background color
            [self colorLabels:artworkForegroundColor];

            // This method is called many times, so we remove old observers first
            [[NSNotificationCenter defaultCenter] removeObserver:self name:videArtworkChanged object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTintColor) name:videArtworkChanged object:nil];
        
        } else if([prefLSTintStyle intValue] == 2) { // Custom user color
            UIColor *tint = [GcColorPickerUtils colorWithHex:prefLSTintCustomColor];
            [self colorLabels:tint];
        }

    // CC
    } else {

        if([prefCCTintStyle intValue] == 1) { // Based on background color
            [self colorLabels:artworkForegroundColor];

            // This method is called many times, so we remove old observers first
            [[NSNotificationCenter defaultCenter] removeObserver:self name:videArtworkChanged object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTintColor) name:videArtworkChanged object:nil];
        
        } else if([prefCCTintStyle intValue] == 2) { // Custom user color
            UIColor *tint = [GcColorPickerUtils colorWithHex:prefCCTintCustomColor];
            [self colorLabels:tint];
        }
    }
}

%new
- (void) updateTintColor {
    [self colorLabels:artworkForegroundColor];
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

    artworkPrimaryColor = [UIColor clearColor];
    artworkForegroundColor = [UIColor labelColor];

    %init;
    // if([prefLSBackgroundStyle intValue] == 1 || [prefCCBackgroundStyle intValue] == 1 || prefLSShowWave) %init(ArtworkColorNotification);
}