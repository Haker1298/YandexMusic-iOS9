#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;
@property (strong, nonatomic) NSString *accessToken;
@property (nonatomic) BOOL isGuestMode;
- (void)showMainApp;
- (void)showOAuth;
- (void)logout;
@end