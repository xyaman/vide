#import <UIKit/UIkit.h>
#import <Cephei/HBPreferences.h>

#import <GcUniversal/GcColorPickerUtils.h>

// Preferences
HBPreferences *preferences = nil;

BOOL prefUsePlayerCustomColor = NO;
NSString *prefPlayerCustomColor = nil;
NSString *prefPlayerAlpha = nil;
NSString *prefPlayerRadius = nil;

NSString *prefArtworkRadius = nil;
BOOL prefHideSourceIcon = NO;

BOOL prefUseTintCustomColor = NO;
NSString *prefTintCustomColor = nil;


// @interface CSMediaControlsViewController : UIViewController
// @end
// @interface MRPlatterViewController : UIViewController
// @end

@interface UIView (Private)
-(UIViewController *)_viewControllerForAncestor;
@end

@interface CSAdjunctItemView : UIView
@end

@interface MTMaterialView : UIView
@end

@interface PLPlatterView : UIView
@property(nonatomic,retain) MTMaterialView *backgroundView;
@end

@interface MRUNowPlayingViewController : UIViewController
@property(assign,nonatomic) long long context;
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
@property (nonatomic,retain) UILabel * titleLabel;
@end

// Media labels
@interface MRUNowPlayingLabelView : UIView
@property(nonatomic,retain) MPRouteLabel *routeLabel;
@property(nonatomic,retain) UILabel *titleLabel;
@property(nonatomic,retain) UILabel *subtitleLabel;

-(void)updateVisualStyling;
@end

@interface MRUNowPlayingControlsView : UIView
@property(nonatomic,readonly) MRUNowPlayingTransportControlsView *transportControlsView;
-(void)setStylingProvider:(id)arg1; 
@end

@interface MRUArtworkView : UIView
@end