#import <UIKit/UIkit.h>
#import <Cephei/HBPreferences.h>
#import <MediaRemote/MediaRemote.h>

#import <GcUniversal/GcColorPickerUtils.h>
#import <Kuro/libKuro.h>
#import <Sona/SNAWaveView.h>

// Preferences
HBPreferences *preferences = nil;
BOOL isEnabled = NO;

NSString *prefLSAlpha = nil;
NSString *prefLSRadius = nil;
BOOL prefLSAirplayBlur = NO;
BOOL prefKumquatComp = NO;

// LS Coloring
NSNumber *prefLSBackgroundStyle = nil;
NSString *prefLSCustomColor = nil;
NSNumber *prefLSTintStyle = nil;
NSString *prefLSTintCustomColor = nil;

NSString *prefLSArtworkRadius = nil;
BOOL prefLSHideSourceIcon = NO;

// LS Wave
BOOL prefLSShowWave = NO;
NSNumber *prefLSWaveColorStyle = nil;
NSString *prefLSWaveCustomColor = nil;
NSNumber *prefLSWaveSens = nil;
NSNumber *prefLSWaveAlpha = nil;

// LS Hiding
BOOL prefLSHideTime = NO;
BOOL prefLSHideControls = NO;
BOOL prefLSHideVolume = NO;

// LS gestures
BOOL prefLSUseSwipeGestures = NO;
BOOL prefLSUseTapticFeedback = YES;

// CC Coloring
NSString *prefCCBackgroundStyle = nil;
NSString *prefCCCustomColor = nil;
NSNumber *prefCCTintStyle = nil;
NSString *prefCCTintCustomColor = nil;

// CC Wave
BOOL prefCCShowWave = NO;
NSNumber *prefCCWaveColorStyle = nil;
NSString *prefCCWaveCustomColor = nil;
NSNumber *prefCCWaveSens = nil;
NSNumber *prefCCWaveAlpha = nil;

// CC Hiding
BOOL prefCCHideTime = NO;
BOOL prefCCHideControls = NO;
BOOL prefCCHideVolume = NO;

// CC gestures
BOOL prefCCUseSwipeGestures = NO;
BOOL prefCCUseTapticFeedback = YES;

NSString *prefCCArtworkRadius = nil;
BOOL prefCCHideSourceIcon = NO;

/*----------------------
 / Notifications
 -----------------------*/
NSString *videUpdateColors = @"videUpdateColors";


// @interface CSMediaControlsViewController : UIViewController
// @end
// @interface MRPlatterViewController : UIViewController
// @end

// Use to get a instance and use gestures
@interface CSScrollView : UIScrollView
@end

@interface UIView (Private)
-(UIViewController *)_viewControllerForAncestor;
@end

@interface SBApplication : NSObject
@property (nonatomic, readonly) NSString *bundleIdentifier;                                                                                     //@synthesize bundleIdentifier=_bundleIdentifier - In the implementation block
@end

@interface SBMediaController : NSObject
+ (id)sharedInstance;
- (BOOL) isPlaying;
- (BOOL)changeTrack:(int)arg1 eventSource:(long long)arg2;
- (BOOL)togglePlayPauseForEventSource:(long long)arg1;
- (SBApplication *)nowPlayingApplication;
@end

@interface UIApplication ()
-(BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2 ;
@end

@interface MRUNowPlayingViewController : UIViewController
@property(assign,nonatomic) long long context;
- (void) addSwipeGestures;
@end

@interface MRUNowPlayingView : UIView
@property(assign,nonatomic) long long context;
@property(nonatomic, retain) SNAWaveView *sona;
- (void) addSwipeGestures;
@end

@interface CSAdjunctItemView : UIView
@property(nonatomic, retain) SNAWaveView *sona;
- (void) setSizeToMimic:(CGSize)arg1;
- (void) _updateSizeToMimic;
@end

@interface MTMaterialView : UIView
@end

@interface PLPlatterView : UIView
@property(nonatomic,retain) MTMaterialView *backgroundView;
@end

// Media button
@interface MRUTransportButton : UIButton
-(void)setStylingProvider:(id)arg1;
@end

// Media controls buttons
@interface MRUNowPlayingTransportControlsView : UIView
@property(nonatomic,retain) MRUTransportButton *leftButton;
@property(nonatomic,retain) MRUTransportButton *middleButton;
@property(nonatomic,retain) MRUTransportButton *rightButton;
- (void) changeButtonsColor:(UIColor *)tint;
@end

// Media time slider
@interface MRUNowPlayingTimeControlsView : UIView
@property(nonatomic,retain) UIView *elapsedTrack;
@end

// Media volume slider
@interface MRUNowPlayingVolumeControlsView : UIView
@property(nonatomic,readonly) UISlider *slider;
@end

@interface MPRouteLabel : UILabel
@property(nonatomic,retain) UILabel * titleLabel;
@end

// Media labels
@interface MRUNowPlayingLabelView : UIView
@property(nonatomic,retain) MPRouteLabel *routeLabel;
@property(nonatomic,retain) UILabel *titleLabel;
@property(nonatomic,retain) UILabel *subtitleLabel;

- (void) colorLabels:(UIColor *)tint;
- (void) updateVisualStyling;
@end

@interface MRUNowPlayingRoutingButton : UIButton
@property(nonatomic, retain) UIVisualEffectView *blurView;
@end

@interface MRUNowPlayingControlsView : UIView
@property(nonatomic,readonly) MRUNowPlayingTransportControlsView *transportControlsView;
-(void)setStylingProvider:(id)arg1; 
@end

@interface MRUArtworkView : UIView
@end