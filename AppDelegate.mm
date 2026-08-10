#import "AppDelegate.h"
#import "WebViewController.h"
#import "OAuthViewController.h"
#import "AudioPlayer.h"
#import "KeychainHelper.h"
#import "MiniPlayerView.h"

static NSString *const kClientId = @"b399db89f01e4bd4965cef1f7973ee05";
static NSString *const kRedirectURI = @"yandexmusic://auth/callback";

static UIImage *halfSizeImage(NSString *name) {
    UIImage *img = [UIImage imageNamed:name];
    if (!img) return nil;
    CGSize half = CGSizeMake(img.size.width * 0.5, img.size.height * 0.5);
    UIGraphicsBeginImageContextWithOptions(half, NO, img.scale);
    [img drawInRect:CGRectMake(0, 0, half.width, half.height)];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

static UIImage *concertIcon(CGFloat size, BOOL active) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    UIColor *color = active ? [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0] : [UIColor colorWithWhite:0.6 alpha:1.0];
    [color setStroke];
    [color setFill];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    // Microphone body (rounded rect via UIBezierPath)
    CGFloat cx = size / 2, cy = size * 0.38;
    CGFloat rw = size * 0.16, rh = size * 0.28;
    UIBezierPath *micBody = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(cx - rw, cy - rh, rw * 2, rh * 2) cornerRadius:rw];
    [micBody fill];
    // Mic stand arc
    CGFloat standY = cy + rh;
    CGContextSetLineWidth(ctx, 1.5);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, cx - size * 0.25, standY + size * 0.12);
    CGContextAddQuadCurveToPoint(ctx, cx - size * 0.25, standY + size * 0.25, cx, standY + size * 0.25);
    CGContextAddQuadCurveToPoint(ctx, cx + size * 0.25, standY + size * 0.25, cx + size * 0.25, standY + size * 0.12);
    CGContextStrokePath(ctx);
    // Stand line
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, cx, standY + size * 0.25);
    CGContextAddLineToPoint(ctx, cx, size * 0.88);
    CGContextStrokePath(ctx);
    // Base
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, cx - size * 0.2, size * 0.88);
    CGContextAddLineToPoint(ctx, cx + size * 0.2, size * 0.88);
    CGContextStrokePath(ctx);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

static UIImage *collectionIcon(CGFloat size, BOOL active) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    UIColor *color = active ? [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0] : [UIColor colorWithWhite:0.6 alpha:1.0];
    [color setFill];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat m = size * 0.18;
    CGFloat cw = (size - m * 3) / 2;
    CGFloat ch = cw * 1.3;
    CGFloat baseY = size * 0.15;
    // Stack of 3 items
    for (int i = 0; i < 3; i++) {
        CGFloat x = m + i * (cw * 0.15);
        CGFloat y = baseY + i * (ch * 0.2);
        CGContextFillRect(ctx, CGRectMake(x, y, cw, ch));
    }
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    // Try to load token from Keychain
    self.accessToken = [KeychainHelper loadToken];

    // Setup audio session for background playback
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];

    if (self.accessToken && self.accessToken.length > 0) {
        self.isGuestMode = NO;
        [self showMainApp];
    } else {
        [self showOAuth];
    }

    [self.window makeKeyAndVisible];
    return YES;
}

- (void)showOAuth {
    OAuthViewController *oauthVC = [[OAuthViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:oauthVC];
    nav.navigationBarHidden = YES;
    self.window.rootViewController = nav;
}

- (void)showMainApp {
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.delegate = (id)self;

    // Tab 1: Моя Волна
    WebViewController *waveVC = [[WebViewController alloc] initWithPage:@"wave" title:@"Моя Волна"];
    UINavigationController *waveNav = [[UINavigationController alloc] initWithRootViewController:waveVC];
    waveNav.tabBarItem.image = halfSizeImage(@"tab_wave");
    waveNav.tabBarItem.selectedImage = halfSizeImage(@"tab_wave_active");
    waveNav.tabBarItem.title = @"Моя волна";
    waveNav.navigationBarHidden = YES;

    // Tab 2: Что послушать
    WebViewController *exploreVC = [[WebViewController alloc] initWithPage:@"explore" title:@"Что послушать"];
    UINavigationController *exploreNav = [[UINavigationController alloc] initWithRootViewController:exploreVC];
    exploreNav.tabBarItem.image = halfSizeImage(@"tab_home");
    exploreNav.tabBarItem.selectedImage = halfSizeImage(@"tab_home_active");
    exploreNav.tabBarItem.title = @"Что послушать";
    exploreNav.navigationBarHidden = YES;

    // Tab 3: Концерты
    WebViewController *concertsVC = [[WebViewController alloc] initWithPage:@"concerts" title:@"Концерты"];
    UINavigationController *concertsNav = [[UINavigationController alloc] initWithRootViewController:concertsVC];
    UIImage *concertImg = halfSizeImage(@"tab_concert");
    UIImage *concertImgActive = halfSizeImage(@"tab_concert_active");
    if (concertImg) {
        concertsNav.tabBarItem.image = concertImg;
    } else {
        concertsNav.tabBarItem.image = concertIcon(25, NO);
    }
    if (concertImgActive) {
        concertsNav.tabBarItem.selectedImage = concertImgActive;
    } else {
        concertsNav.tabBarItem.selectedImage = concertIcon(25, YES);
    }
    concertsNav.tabBarItem.title = @"Концерты";
    concertsNav.navigationBarHidden = YES;

    // Tab 4: Коллекция
    WebViewController *collectionVC = [[WebViewController alloc] initWithPage:@"collection" title:@"Коллекция"];
    UINavigationController *collectionNav = [[UINavigationController alloc] initWithRootViewController:collectionVC];
    collectionNav.tabBarItem.image = collectionIcon(25, NO);
    collectionNav.tabBarItem.selectedImage = collectionIcon(25, YES);
    collectionNav.tabBarItem.title = @"Коллекция";
    collectionNav.navigationBarHidden = YES;

    self.tabBarController.viewControllers = @[waveNav, exploreNav, concertsNav, collectionNav];

    // Style the tab bar
    self.tabBarController.tabBar.barTintColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    self.tabBarController.tabBar.tintColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.6 alpha:1.0], NSFontAttributeName: [UIFont systemFontOfSize:9]} forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0], NSFontAttributeName: [UIFont systemFontOfSize:9]} forState:UIControlStateSelected];

    self.window.rootViewController = self.tabBarController;

    // Add mini player above tab bar after layout
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setupMiniPlayer];
    });
}

- (void)setupMiniPlayer {
    if (!self.tabBarController) return;

    UITabBar *tabBar = self.tabBarController.tabBar;
    CGRect tabFrame = tabBar.frame;
    CGFloat playerH = 44;
    CGFloat playerY = tabFrame.origin.y - playerH;
    CGFloat playerW = tabFrame.size.width;

    MiniPlayerView *miniPlayer = [MiniPlayerView sharedPlayer];
    miniPlayer.frame = CGRectMake(0, playerY, playerW, playerH);
    miniPlayer.hidden = YES;

    [self.tabBarController.view addSubview:miniPlayer];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[url scheme] isEqualToString:@"yandexmusic"]) {
        NSString *fragment = [url fragment];
        if (fragment) {
            NSDictionary *params = [self parseURLFragment:fragment];
            NSString *token = params[@"access_token"];
            if (token && token.length > 0) {
                self.accessToken = token;
                self.isGuestMode = NO;
                [KeychainHelper saveToken:token];
                [self showMainApp];
            }
        }
        return YES;
    }
    return NO;
}

- (NSDictionary *)parseURLFragment:(NSString *)fragment {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSArray *pairs = [fragment componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        if (kv.count == 2) {
            NSString *key = [kv[0] stringByRemovingPercentEncoding];
            NSString *value = [kv[1] stringByRemovingPercentEncoding];
            dict[key] = value;
        }
    }
    return dict;
}

- (void)logout {
    self.accessToken = nil;
    self.isGuestMode = NO;
    [KeychainHelper deleteToken];
    [[AudioPlayer sharedPlayer] stop];
    [MiniPlayerView sharedPlayer].hidden = YES;
    [self showOAuth];
}

@end
