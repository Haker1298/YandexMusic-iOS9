#import "WebViewController.h"
#import "AppDelegate.h"
#import "AudioPlayer.h"
#import "MiniPlayerView.h"

static NSString *const kApiBase = @"https://api.music.yandex.net";
static NSString *const kCoverBase = @"https://"; // prepend to cover URLs

@implementation WebViewController

- (id)initWithPage:(NSString *)page title:(NSString *)title {
    self = [super init];
    if (self) {
        _pageName = [page copy];
        self.title = title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];

    // Create top bar
    [self setupTopBar];

    // Create WKWebView
    CGRect webFrame = self.view.bounds;
    webFrame.origin.y = 44; // below top bar
    webFrame.size.height -= 44;

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = [[WKUserContentController alloc] init];

    // Register JS message handlers
    [config.userContentController addScriptMessageHandler:self name:@"ymapi"];
    [config.userContentController addScriptMessageHandler:self name:@"ymplayer"];
    [config.userContentController addScriptMessageHandler:self name:@"ymnav"];
    [config.userContentController addScriptMessageHandler:self name:@"ymlogout"];

    self.webView = [[WKWebView alloc] initWithFrame:webFrame configuration:config];
    self.webView.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];
    self.webView.scrollView.bounces = YES;
    self.webView.opaque = NO;
    [self.view addSubview:self.webView];

    // Load local HTML
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:self.pageName ofType:@"html" inDirectory:@"resources"];
    if (!htmlPath) {
        htmlPath = [[NSBundle mainBundle] pathForResource:self.pageName ofType:@"html"];
    }
    if (htmlPath) {
        NSURL *htmlURL = [NSURL fileURLWithPath:htmlPath];
        NSURL *resURL = [[htmlURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent];
        [self.webView loadFileURL:htmlURL allowingReadAccessToURL:resURL];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Inject token after page loads
    if (self.webView.URL) {
        [self injectToken];
    }
}

- (void)setupTopBar {
    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    topBar.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];
    topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:topBar];

    // Account button (left)
    UIButton *accountBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *profileImg = [UIImage imageNamed:@"nav_profile"];
    if (profileImg) {
        accountBtn.frame = CGRectMake(12, 8, 28, 28);
        [accountBtn setImage:profileImg forState:UIControlStateNormal];
        [accountBtn setTintColor:[UIColor whiteColor]];
    } else {
        accountBtn.frame = CGRectMake(12, 8, 28, 28);
        [accountBtn setTitle:@"\u2302" forState:UIControlStateNormal];
        [accountBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        accountBtn.titleLabel.font = [UIFont systemFontOfSize:22];
    }
    [accountBtn addTarget:self action:@selector(accountTapped) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:accountBtn];

    // Logo (center)
    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"yandex_music_text_logo_white"]];
    if (logoView.image) {
        CGFloat logoW = logoView.image.size.width * 0.45;
        CGFloat logoH = logoView.image.size.height * 0.45;
        logoView.frame = CGRectMake((topBar.bounds.size.width - logoW) / 2, (44 - logoH) / 2, logoW, logoH);
        logoView.contentMode = UIViewContentModeScaleAspectFit;
        [topBar addSubview:logoView];
    } else {
        UILabel *logoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, topBar.bounds.size.width, 24)];
        logoLabel.text = @"\u042F\u043D\u0434\u0435\u043A\u0441 \u041C\u0443\u0437\u044B\u043A\u0430";
        logoLabel.textAlignment = NSTextAlignmentCenter;
        logoLabel.textColor = [UIColor whiteColor];
        logoLabel.font = [UIFont boldSystemFontOfSize:16];
        [topBar addSubview:logoLabel];
    }

    // Search button (right)
    UIButton *searchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *searchImg = [UIImage imageNamed:@"nav_search"];
    if (searchImg) {
        searchBtn.frame = CGRectMake(topBar.bounds.size.width - 40, 8, 28, 28);
        [searchBtn setImage:searchImg forState:UIControlStateNormal];
        [searchBtn setTintColor:[UIColor whiteColor]];
    } else {
        searchBtn.frame = CGRectMake(topBar.bounds.size.width - 40, 8, 28, 28);
        [searchBtn setTitle:@"\u2315" forState:UIControlStateNormal];
        [searchBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        searchBtn.titleLabel.font = [UIFont systemFontOfSize:22];
    }
    [searchBtn addTarget:self action:@selector(searchTapped) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:searchBtn];
}

- (void)accountTapped {
    // Show account/logout menu
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Аккаунт"
                                                   message:@"Выйти из аккаунта?"
                                                  delegate:self
                                         cancelButtonTitle:@"Отмена"
                                         otherButtonTitles:@"Выйти", nil];
    alert.tag = 100;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 100 && buttonIndex == 1) {
        AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [del logout];
    }
}

- (void)searchTapped {
    // Switch to search tab
    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (del.tabBarController && del.tabBarController.viewControllers.count > 1) {
        del.tabBarController.selectedIndex = 1;
    }
}

- (void)injectToken {
    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (del.accessToken) {
        NSString *js = [NSString stringWithFormat:@"window.__YM_TOKEN__ = '%@'; if(window.onTokenReady) window.onTokenReady();", del.accessToken];
        [self.webView evaluateJavaScript:js completionHandler:nil];
    } else {
        [self.webView evaluateJavaScript:@"window.__GUEST__ = true; if(window.onTokenReady) window.onTokenReady();" completionHandler:nil];
    }
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([[message name] isEqualToString:@"ymapi"]) {
        [self handleApiCall:message.body];
    } else if ([[message name] isEqualToString:@"ymplayer"]) {
        [self handlePlayerAction:message.body];
    } else if ([[message name] isEqualToString:@"ymnav"]) {
        [self handleNavAction:message.body];
    } else if ([[message name] isEqualToString:@"ymlogout"]) {
        AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [del logout];
    }
}

#pragma mark - API Calls

- (void)handleApiCall:(id)body {
    if (![body isKindOfClass:[NSDictionary class]]) return;
    NSDictionary *params = (NSDictionary *)body;
    NSString *path = params[@"path"];
    NSString *method = params[@"method"] ?: @"GET";
    NSString *callbackId = params[@"callbackId"];
    NSDictionary *reqBody = params[@"body"];

    if (!path) return;

    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *token = del.accessToken;
    if (!token) {
        NSString *js = [NSString stringWithFormat:@"window.__ymApiCallback('%@', '{\"error\":\"guest\",\"guestMode\":true}');", callbackId];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.webView evaluateJavaScript:js completionHandler:nil];
        });
        return;
    }

    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kApiBase, path];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method;
    [request setValue:[NSString stringWithFormat:@"OAuth %@", token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    if (reqBody && [method isEqualToString:@"POST"]) {
        NSError *jsonErr;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:reqBody options:0 error:&jsonErr];
        if (jsonData) {
            request.HTTPBody = jsonData;
        }
    }

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *resultStr = @"{}";
        if (error) {
            resultStr = [NSString stringWithFormat:@"{\"error\":\"%@\"}", error.localizedDescription];
        } else if (data) {
            resultStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (!resultStr) resultStr = @"{}";
        }

        NSString *escaped = [resultStr stringByReplacingOccurrencesOfString:@"\\'" withString:@"\\\\'"];
        escaped = [escaped stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
        escaped = [escaped stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        NSString *js = [NSString stringWithFormat:@"window.__ymApiCallback('%@', '%@');", callbackId, escaped];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.webView evaluateJavaScript:js completionHandler:nil];
        });
    }];
    [task resume];
}

#pragma mark - Player Actions

- (void)handlePlayerAction:(id)body {
    if (![body isKindOfClass:[NSDictionary class]]) return;
    NSDictionary *params = (NSDictionary *)body;
    NSString *action = params[@"action"];

    AudioPlayer *player = [AudioPlayer sharedPlayer];
    player.webVC = self;

    if ([action isEqualToString:@"play"]) {
        NSString *trackId = params[@"trackId"];
        NSString *title = params[@"title"] ?: @"";
        NSString *artist = params[@"artist"] ?: @"";
        NSString *cover = params[@"cover"] ?: @"";
        NSNumber *duration = params[@"duration"];
        NSString *albumId = params[@"albumId"];
        NSArray *queue = params[@"queue"];

        if (queue && [queue isKindOfClass:[NSArray class]]) {
            player.queue = (NSArray *)queue;
            player.currentQueueIndex = 0;
            // Find current track in queue
            for (int i = 0; i < queue.count; i++) {
                NSDictionary *t = queue[i];
                if ([t[@"id"] isEqualToString:trackId]) {
                    player.currentQueueIndex = i;
                    break;
                }
            }
        }

        player.currentTrackId = trackId;
        player.currentTitle = title;
        player.currentArtist = artist;
        player.currentCoverUrl = cover;
        if (duration) player.currentDuration = [duration doubleValue];

        [player playTrack:trackId albumId:albumId];
    } else if ([action isEqualToString:@"pause"]) {
        [player pause];
    } else if ([action isEqualToString:@"resume"]) {
        [player resume];
    } else if ([action isEqualToString:@"next"]) {
        [player playNext];
    } else if ([action isEqualToString:@"prev"]) {
        [player playPrev];
    } else if ([action isEqualToString:@"seek"]) {
        double time = [params[@"time"] doubleValue];
        [player seekTo:time];
    } else if ([action isEqualToString:@"getState"]) {
        [self updatePlayerState:@{
            @"playing": @(player.isPlaying),
            @"trackId": player.currentTrackId ?: @"",
            @"title": player.currentTitle ?: @"",
            @"artist": player.currentArtist ?: @"",
            @"cover": player.currentCoverUrl ?: @"",
            @"currentTime": @(player.currentTime),
            @"duration": @(player.currentDuration)
        }];
    }
}

- (void)updatePlayerState:(NSDictionary *)state {
    NSError *err;
    NSData *data = [NSJSONSerialization dataWithJSONObject:state options:0 error:&err];
    if (!data) return;
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *escaped = [json stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    NSString *js = [NSString stringWithFormat:@"window.__ymPlayerUpdate(%@);", escaped];
    [self.webView evaluateJavaScript:js completionHandler:nil];

    // Update mini player
    MiniPlayerView *mp = [MiniPlayerView sharedPlayer];
    mp.hidden = NO;
    mp.titleLabel.text = state[@"title"];
    mp.artistLabel.text = state[@"artist"];
}

#pragma mark - Nav Actions

- (void)handleNavAction:(id)body {
    if (![body isKindOfClass:[NSDictionary class]]) return;
    NSDictionary *params = (NSDictionary *)body;
    NSString *action = params[@"action"];

    if ([action isEqualToString:@"playTrack"]) {
        // Navigate to wave tab and play
        AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        del.tabBarController.selectedIndex = 0;
    }
}

@end