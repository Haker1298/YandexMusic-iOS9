#import "AppDelegate.h"
#import "WebViewController.h"
#import "OAuthViewController.h"
#import "AudioPlayer.h"
#import "KeychainHelper.h"
#import "MiniPlayerView.h"

static NSString *const kClientId = @"23cabbbdc6cd44269f782aa40abda634";
static NSString *const kRedirectURI = @"yandexmusic://auth/callback";

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
    waveNav.tabBarItem.image = [UIImage imageNamed:@"tab_wave"];
    waveNav.tabBarItem.selectedImage = [UIImage imageNamed:@"tab_wave_active"];
    waveNav.tabBarItem.title = @"Волна";
    waveNav.navigationBarHidden = YES;

    // Tab 2: Поиск
    WebViewController *searchVC = [[WebViewController alloc] initWithPage:@"search" title:@"Поиск"];
    UINavigationController *searchNav = [[UINavigationController alloc] initWithRootViewController:searchVC];
    searchNav.tabBarItem.image = [UIImage imageNamed:@"tab_home"];
    searchNav.tabBarItem.selectedImage = [UIImage imageNamed:@"tab_home_active"];
    searchNav.tabBarItem.title = @"Поиск";
    searchNav.navigationBarHidden = YES;

    // Tab 3: Мне нравится
    WebViewController *likesVC = [[WebViewController alloc] initWithPage:@"likes" title:@"Мне нравится"];
    UINavigationController *likesNav = [[UINavigationController alloc] initWithRootViewController:likesVC];
    likesNav.tabBarItem.image = [UIImage imageNamed:@"tab_likes"];
    likesNav.tabBarItem.selectedImage = [UIImage imageNamed:@"tab_likes_active"];
    likesNav.tabBarItem.title = @"Любимые";
    likesNav.navigationBarHidden = YES;

    // Tab 4: Подкасты
    WebViewController *podcastsVC = [[WebViewController alloc] initWithPage:@"podcasts" title:@"Подкасты"];
    UINavigationController *podcastsNav = [[UINavigationController alloc] initWithRootViewController:podcastsVC];
    podcastsNav.tabBarItem.image = [UIImage imageNamed:@"tab_podcast"];
    podcastsNav.tabBarItem.selectedImage = [UIImage imageNamed:@"tab_podcast_active"];
    podcastsNav.tabBarItem.title = @"Подкасты";
    podcastsNav.navigationBarHidden = YES;

    self.tabBarController.viewControllers = @[waveNav, searchNav, likesNav, podcastsNav];

    // Style the tab bar
    self.tabBarController.tabBar.barTintColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    self.tabBarController.tabBar.tintColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.6 alpha:1.0]} forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0]} forState:UIControlStateSelected];

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
    CGFloat playerH = 56;
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
            // Parse access_token from URL fragment: access_token=xxx&token_type=bearer&expires_in=xxx
            NSDictionary *params = [self parseURLFragment:fragment];
            NSString *token = params[@"access_token"];
            if (token && token.length > 0) {
                self.accessToken = token;
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
    [KeychainHelper deleteToken];
    [[AudioPlayer sharedPlayer] stop];
    [MiniPlayerView sharedPlayer].hidden = YES;
    [self showOAuth];
}

@end
