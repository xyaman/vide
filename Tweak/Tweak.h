#import <UIKit/UIkit.h>
#import <Cephei/HBPreferences.h>

#import <GcUniversal/GcColorPickerUtils.h>

// Preferences
HBPreferences *preferences = nil;

BOOL prefUseLSCustomColor = NO;
NSString *prefLSCustomColor = nil;
NSString *prefLSAlpha = nil;
NSString *prefLSRadius = nil;

NSString *prefLSArtworkRadius = nil;
BOOL prefLSHideSourceIcon = NO;

BOOL prefUseLSTintCustomColor = NO;
NSString *prefLSTintCustomColor = nil;

// LS Hiding
BOOL prefLSHideTime = NO;
BOOL prefLSHideControls = NO;
BOOL prefLSHideVolume = NO;

// LS gestures
BOOL prefLSUseSwipeGestures = NO;

// CC
BOOL prefUseCCTintCustomColor = NO;
NSString *prefCCTintCustomColor = nil;

// CC Hiding
BOOL prefCCHideTime = NO;
BOOL prefCCHideControls = NO;
BOOL prefCCHideVolume = NO;

// CC gestures
BOOL prefCCUseSwipeGestures = NO;

NSString *prefCCArtworkRadius = nil;
BOOL prefCCHideSourceIcon = NO;


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

@interface SBMediaController : NSObject
+ (id)sharedInstance;
- (BOOL) isPlaying;
- (BOOL)changeTrack:(int)arg1 eventSource:(long long)arg2;
@end

@interface MRUNowPlayingViewController : UIViewController
@property(assign,nonatomic) long long context;
- (void) addSwipeGestures;
@end

@interface CSAdjunctItemView : UIView
@property(nonatomic, retain) NSLayoutDimension *height;
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

@interface MRUNowPlayingControlsView : UIView
@property(nonatomic,readonly) MRUNowPlayingTransportControlsView *transportControlsView;
-(void)setStylingProvider:(id)arg1; 
@end

@interface MRUArtworkView : UIView
@end