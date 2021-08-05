#import "Tweak.h"


// Media player controller
// %hook CSMediaControlsViewController
// - (void) loadView {
//     %orig;

//     self.view.clipsToBounds = YES;

//     MRPlatterViewController *pvc = [self valueForKey:@"_platterViewController"];
//     if (!pvc) return;

//     // Styling
//     // pvc.view.layer.cornerRadius = [prefPlayerRadius floatValue];
// }
// %end

// %hook MRUNowPlayingViewController
// - (void) viewDidAppear {
//     %orig;

//     NSLog(@"[VideTweak] %llu", self.context);

//     // [self.view.heightAnchor constraintEqualToConstant:100].active = YES;
//     self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, 100);
// }
// %end

// Media player main view
%hook CSAdjunctItemView
- (void) didMoveToWindow {
    %orig;

    PLPlatterView *pv = [self valueForKey:@"_platterView"];

    // Alpha
    pv.backgroundView.alpha = [prefPlayerAlpha floatValue];

    // Radius
    pv.backgroundView.layer.cornerRadius = [prefPlayerRadius floatValue];

    // Background color
    if(prefUsePlayerCustomColor) pv.backgroundView.backgroundColor = [GcColorPickerUtils colorWithHex:prefPlayerCustomColor];
}
%end

// MRU
// context == 2 Media Player notification
// context == 1 CC Media player

// Media player controls
%hook MRUNowPlayingTransportControlsView
- (void) didMoveToWindow {

    %orig;

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    if([controller respondsToSelector:@selector(context)] && controller.context == 2) {

        // Media player buttons
        if(prefUseTintCustomColor) {

            [self.leftButton setStylingProvider:nil];
            [self.middleButton setStylingProvider:nil];
            [self.rightButton setStylingProvider:nil];

            UIColor *tint = [GcColorPickerUtils colorWithHex:prefTintCustomColor];

            if(self.leftButton.imageView.layer.filters.count) self.leftButton.imageView.layer.filters = nil;
            self.leftButton.imageView.tintColor = tint;

            if(self.middleButton.imageView.layer.filters.count) self.middleButton.imageView.layer.filters = nil;
            self.middleButton.imageView.tintColor = tint;

            if(self.rightButton.imageView.layer.filters.count) self.rightButton.imageView.layer.filters = nil;
            self.rightButton.imageView.tintColor = tint;
        }
    }

}
%end

// Media player time slider
%hook MRUNowPlayingTimeControlsView
- (void) didMoveToWindow {
    %orig;

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    if([controller respondsToSelector:@selector(context)] && controller.context == 2) {
        if(prefUseTintCustomColor) self.elapsedTrack.backgroundColor = [GcColorPickerUtils colorWithHex:prefTintCustomColor];
    }
}
%end

// Media player volume slider
%hook MRUNowPlayingVolumeControlsView

- (void) didMoveToWindow {
    %orig;

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    if([controller respondsToSelector:@selector(context)] && controller.context == 2) {

        if(prefUseTintCustomColor) self.slider.minimumTrackTintColor = [GcColorPickerUtils colorWithHex:prefTintCustomColor];
    }
}
%end

// Song artwork
%hook MRUArtworkView
- (id) initWithFrame:(CGRect) frame {
    id orig = %orig;

    self.clipsToBounds = YES;
    self.layer.cornerRadius = [prefArtworkRadius floatValue]; 

    return orig;
}

// hide src icon
-(void) setIconImage:(UIImage *)arg1 {
    prefHideSourceIcon ? %orig(nil) : %orig;
}
%end

// Media player label
%hook MRUNowPlayingLabelView
- (void) updateVisualStyling {
    %orig;

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    if(prefUseTintCustomColor && [controller respondsToSelector:@selector(context)] && controller.context == 2) {

        UIColor *tint = [GcColorPickerUtils colorWithHex:prefTintCustomColor];

        if(self.routeLabel.layer.filters.count) self.routeLabel.layer.filters = nil;
        if(self.routeLabel.titleLabel.layer.filters.count) self.routeLabel.titleLabel.layer.filters = nil;
        self.routeLabel.textColor = tint;
        self.routeLabel.titleLabel.textColor = tint;

        // if(self.titleLabel.layer.filters.count) self.titleLabel.layer.filters = nil;
        self.titleLabel.textColor = tint;

        self.subtitleLabel.textColor = tint;
    }
}
%end


%ctor {
    preferences = [[HBPreferences alloc] initWithIdentifier:@"com.xyaman.videpreferences"];

    // Media player radius
    [preferences registerObject:&prefPlayerRadius default:@"13" forKey:@"playerRadius"];

    // Media player coloring
    [preferences registerBool:&prefUsePlayerCustomColor default:NO forKey:@"usePlayerCustomColor"];
    [preferences registerObject:&prefPlayerCustomColor default:@"000000" forKey:@"playerCustomColor"];

    // Controls color
    [preferences registerBool:&prefUseTintCustomColor default:NO forKey:@"useTintCustomColor"];
    [preferences registerObject:&prefTintCustomColor default:@"000000" forKey:@"tintCustomColor"];

    // Media player alpha
    [preferences registerObject:&prefPlayerAlpha default:@"1.0" forKey:@"playerAlpha"];

    // Song artwork
    [preferences registerObject:&prefArtworkRadius default:@"0" forKey:@"artworkRadius"];
    [preferences registerBool:&prefHideSourceIcon default:NO forKey:@"hideSourceIcon"];

    %init;
}