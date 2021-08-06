#import "Tweak.h"

CSAdjunctItemView *adjunct = nil;
float adjunctHeight = 0;
float volHeight = 0;


%hook CSMediaControlsViewController
-(CGRect)_suggestedFrameForMediaControls {
    CGRect rect = %orig;
    if(!adjunctHeight) adjunctHeight = rect.size.height;
    if(prefLSHideVolume) volHeight = 44;
    return rect;
}
%end

// LS media player main view
%hook CSAdjunctItemView
%property(nonatomic, retain) NSLayoutDimension *height;
- (void) didMoveToWindow {
    %orig;

    adjunct = self;

    PLPlatterView *pv = [self valueForKey:@"_platterView"];

    // Alpha
    pv.backgroundView.alpha = [prefLSAlpha floatValue];

    // Radius
    pv.backgroundView.layer.cornerRadius = [prefLSRadius floatValue];

    // Background color
    if(prefUseLSCustomColor) pv.backgroundView.backgroundColor = [GcColorPickerUtils colorWithHex:prefLSCustomColor];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(self.frame.size.width, adjunctHeight - volHeight);
}

%end

/*----------------------
   MRU
   context == 2 LS Media player
   context == 1 CC Media player
 -----------------------*/

// Media player controls
%hook MRUNowPlayingTransportControlsView
- (void) didMoveToWindow {

    %orig;

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    long long context = controller.context;

    // LS
    if(context == 2 && prefUseLSTintCustomColor) {
        UIColor *tint = [GcColorPickerUtils colorWithHex:prefLSTintCustomColor];
        [self changeButtonsColor:tint];
    
    // CC
    } else if(context != 2 && prefUseCCTintCustomColor) {
        UIColor *tint = [GcColorPickerUtils colorWithHex:prefCCTintCustomColor];
        [self changeButtonsColor:tint];
    }

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

// Media player time slider
%hook MRUNowPlayingTimeControlsView
- (void) didMoveToWindow {
    %orig;

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    long long context = controller.context;

    // LS
    if(context == 2 && prefUseLSTintCustomColor) {
        self.elapsedTrack.backgroundColor = [GcColorPickerUtils colorWithHex:prefLSTintCustomColor];

    // CC
    } else if(context != 2 && prefUseCCTintCustomColor) {
        self.elapsedTrack.backgroundColor = [GcColorPickerUtils colorWithHex:prefCCTintCustomColor];
    }
}
%end

// Media player volume slider
%hook MRUNowPlayingVolumeControlsView

- (void) didMoveToWindow {
    %orig;

    if(prefLSHideVolume) self.hidden = YES;

    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    long long context = controller.context;

    // LS
    if(context == 2 && prefUseLSTintCustomColor) {
        self.slider.minimumTrackTintColor = [GcColorPickerUtils colorWithHex:prefLSTintCustomColor];

    // CC
    } else if(context != 2 && prefUseCCTintCustomColor) {
        self.slider.minimumTrackTintColor = [GcColorPickerUtils colorWithHex:prefCCTintCustomColor];
    }
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
    if(context == 2 && prefUseLSTintCustomColor) {
        UIColor *tint = [GcColorPickerUtils colorWithHex:prefLSTintCustomColor];
        [self colorLabels:tint];

    // CC
    } else if(context != 2 && prefUseCCTintCustomColor) {
        UIColor *tint = [GcColorPickerUtils colorWithHex:prefCCTintCustomColor];
        [self colorLabels:tint];
    }
}

%new
- (void) colorLabels:(UIColor *)tint {

    if(self.routeLabel.layer.filters.count) self.routeLabel.layer.filters = nil;
    if(self.routeLabel.titleLabel.layer.filters.count) self.routeLabel.titleLabel.layer.filters = nil;
    self.routeLabel.textColor = tint;
    self.routeLabel.titleLabel.textColor = tint;

    // if(self.titleLabel.layer.filters.count) self.titleLabel.layer.filters = nil;
    self.titleLabel.textColor = tint;

    self.subtitleLabel.textColor = tint;
}
%end


%ctor {
    preferences = [[HBPreferences alloc] initWithIdentifier:@"com.xyaman.videpreferences"];

    // LS player radius
    [preferences registerObject:&prefLSRadius default:@"13" forKey:@"LSRadius"];

    // LS player coloring
    [preferences registerBool:&prefUseLSCustomColor default:NO forKey:@"useLSCustomColor"];
    [preferences registerObject:&prefLSCustomColor default:@"000000" forKey:@"LSCustomColor"];

    // Controls color
    [preferences registerBool:&prefUseLSTintCustomColor default:NO forKey:@"useLSTintCustomColor"];
    [preferences registerObject:&prefLSTintCustomColor default:@"000000" forKey:@"LSTintCustomColor"];

    // LS Hiding
    [preferences registerBool:&prefLSHideVolume default:NO forKey:@"LSHideVolume"];

    // Media player alpha
    [preferences registerObject:&prefLSAlpha default:@"1.0" forKey:@"LSAlpha"];

    // Song artwork
    [preferences registerObject:&prefLSArtworkRadius default:@"0" forKey:@"LSArtworkRadius"];
    [preferences registerBool:&prefLSHideSourceIcon default:NO forKey:@"LSHideSourceIcon"];

    // CC tint
    [preferences registerBool:&prefUseCCTintCustomColor default:NO forKey:@"useCCTintCustomColor"];
    [preferences registerObject:&prefCCTintCustomColor default:@"000000" forKey:@"CCTintCustomColor"];

    // CC Song artwork
    [preferences registerObject:&prefCCArtworkRadius default:@"0" forKey:@"CCArtworkRadius"];
    [preferences registerBool:&prefCCHideSourceIcon default:NO forKey:@"CCHideSourceIcon"];

    %init;
}