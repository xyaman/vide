#import "Tweak.h"

CSScrollView *lsScrollView = nil;

float adjunctHeight = 0;

// Here we save an instance of CSScrollView
// we need it to use swipe gestures, instead of this view pan gestures
%hook CSScrollView
-(instancetype)initWithFrame:(CGRect)frame {
    id orig = %orig;

   lsScrollView = self;

   return orig;
}
%end

%hook CSMediaControlsViewController
-(CGRect)_suggestedFrameForMediaControls {
    CGRect rect = %orig;

    if(!adjunctHeight) {
        adjunctHeight = rect.size.height;
    } else {
        return rect;
    }

    if(prefLSHideTime) adjunctHeight -= 46;
    if(prefLSHideControls) adjunctHeight -= 54;
    if(prefLSHideVolume) adjunctHeight -= 46;
    return rect;
}
%end

// LS media player main view
%hook CSAdjunctItemView
%property(nonatomic, retain) NSLayoutDimension *height;
- (void) didMoveToWindow {
    %orig;

    PLPlatterView *pv = [self valueForKey:@"_platterView"];

    // Alpha
    pv.backgroundView.alpha = [prefLSAlpha floatValue];

    // Radius
    pv.backgroundView.layer.cornerRadius = [prefLSRadius floatValue];

    // Background color
    if(prefUseLSCustomColor) pv.backgroundView.backgroundColor = [GcColorPickerUtils colorWithHex:prefLSCustomColor];

    // Add gestures
    if(prefLSUseSwipeGestures) {
        UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(prevTrack)];
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:leftSwipe];
        
        [lsScrollView.panGestureRecognizer requireGestureRecognizerToFail:leftSwipe];

        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextTrack)];
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self addGestureRecognizer:rightSwipe];
        
        [lsScrollView.panGestureRecognizer requireGestureRecognizerToFail:rightSwipe];
    }
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(self.frame.size.width, adjunctHeight);
}

%new
- (void) prevTrack {
    [[%c(SBMediaController) sharedInstance] changeTrack:-1 eventSource:0];
}

%new
- (void) nextTrack {
    [[%c(SBMediaController) sharedInstance] changeTrack:1 eventSource:0];
}

%end

/*----------------------
   MRU
   context == 2 LS Media player
   context == 1 CC Media player
 -----------------------*/
%hook MRUNowPlayingViewController
- (void) loadView {
    %orig;

    // Only works for CC (I guess)
    // if(self.context == 2) {
    //    [self addSwipeGestures];
    
    // }
    if(self.context != 2) {
       if(prefCCUseSwipeGestures) [self addSwipeGestures]; 
    }

}

%new
- (void) addSwipeGestures {

    // Add gestures
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(prevTrack)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:leftSwipe];

    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextTrack)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipe];
    
}

%new
- (void) play {}

%new
- (void) prevTrack {
    [[%c(SBMediaController) sharedInstance] changeTrack:-1 eventSource:0];
}

%new
- (void) nextTrack {
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

// Media player time slider
%hook MRUNowPlayingTimeControlsView
- (void) didMoveToWindow {
    %orig;
    
    MRUNowPlayingViewController *controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
    long long context = controller.context;

    // LS
    if(context == 2) {
        if(prefLSHideTime) self.hidden = YES;
        if(prefUseLSTintCustomColor) self.elapsedTrack.backgroundColor = [GcColorPickerUtils colorWithHex:prefLSTintCustomColor];

    // CC
    } else if(context != 2) {
        if(prefCCHideTime) self.hidden = YES;
        if(prefUseCCTintCustomColor) self.elapsedTrack.backgroundColor = [GcColorPickerUtils colorWithHex:prefCCTintCustomColor];
    }
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

        if(prefUseLSTintCustomColor) {
            UIColor *tint = [GcColorPickerUtils colorWithHex:prefLSTintCustomColor];
            [self changeButtonsColor:tint];
        }
    
    // CC
    } else if(context != 2) {
        if(prefCCHideControls) self.hidden = YES;

        if(prefUseCCTintCustomColor) {
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
        if(prefUseLSTintCustomColor) self.slider.minimumTrackTintColor = [GcColorPickerUtils colorWithHex:prefLSTintCustomColor];

    // CC
    } else if(context != 2) {
        if(prefCCHideVolume) self.hidden = YES;
        if(prefUseCCTintCustomColor) self.slider.minimumTrackTintColor = [GcColorPickerUtils colorWithHex:prefCCTintCustomColor];
    }
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

    // LS Swipe gestures
    [preferences registerBool:&prefLSUseSwipeGestures default:NO forKey:@"LSUseSwipeGestures"];

    // LS player radius
    [preferences registerObject:&prefLSRadius default:@"13" forKey:@"LSRadius"];

    // LS player coloring
    [preferences registerBool:&prefUseLSCustomColor default:NO forKey:@"useLSCustomColor"];
    [preferences registerObject:&prefLSCustomColor default:@"000000" forKey:@"LSCustomColor"];

    // Controls color
    [preferences registerBool:&prefUseLSTintCustomColor default:NO forKey:@"useLSTintCustomColor"];
    [preferences registerObject:&prefLSTintCustomColor default:@"000000" forKey:@"LSTintCustomColor"];

    // LS Hiding
    [preferences registerBool:&prefLSHideTime default:NO forKey:@"LSHideTime"];
    [preferences registerBool:&prefLSHideControls default:NO forKey:@"LSHideControls"];
    [preferences registerBool:&prefLSHideVolume default:NO forKey:@"LSHideVolume"];

    // Media player alpha
    [preferences registerObject:&prefLSAlpha default:@"1.0" forKey:@"LSAlpha"];

    // Song artwork
    [preferences registerObject:&prefLSArtworkRadius default:@"0" forKey:@"LSArtworkRadius"];
    [preferences registerBool:&prefLSHideSourceIcon default:NO forKey:@"LSHideSourceIcon"];


    // CC swipe gestures
    [preferences registerBool:&prefCCUseSwipeGestures default:NO forKey:@"CCUseSwipeGestures"];

    // CC Hiding
    [preferences registerBool:&prefCCHideTime default:NO forKey:@"CCHideTime"];
    [preferences registerBool:&prefCCHideControls default:NO forKey:@"CCHideControls"];
    [preferences registerBool:&prefCCHideVolume default:NO forKey:@"CCHideVolume"];

    // CC tint
    [preferences registerBool:&prefUseCCTintCustomColor default:NO forKey:@"useCCTintCustomColor"];
    [preferences registerObject:&prefCCTintCustomColor default:@"000000" forKey:@"CCTintCustomColor"];

    // CC Song artwork
    [preferences registerObject:&prefCCArtworkRadius default:@"0" forKey:@"CCArtworkRadius"];
    [preferences registerBool:&prefCCHideSourceIcon default:NO forKey:@"CCHideSourceIcon"];

    %init;
}