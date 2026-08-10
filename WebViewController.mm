#import "WebViewController.h"
#import "AppDelegate.h"
#import "AudioPlayer.h"
#import "MiniPlayerView.h"

static NSString *const kApiBase = @"https://api.music.yandex.net";

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

    BOOL showLogo = [self.pageName isEqualToString:@"wave"];
    [self setupTopBar:showLogo];

    CGRect webFrame = self.view.bounds;
    CGFloat topOffset = 32;
    if (showLogo) topOffset = 58; // 32 topBar + 4 gap + ~22 logo
    webFrame.origin.y = topOffset;
    webFrame.size.height -= topOffset;

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = [[WKUserContentController alloc] init];

    [config.userContentController addScriptMessageHandler:self name:@"ymapi"];
    [config.userContentController addScriptMessageHandler:self name:@"ymplayer"];
    [config.userContentController addScriptMessageHandler:self name:@"ymnav"];
    [config.userContentController addScriptMessageHandler:self name:@"ymlogout"];

    self.webView = [[WKWebView alloc] initWithFrame:webFrame configuration:config];
    self.webView.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];
    self.webView.scrollView.bounces = YES;
    self.webView.opaque = NO;
    [self.view addSubview:self.webView];

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
    if (self.webView.URL) {
        [self injectToken];
    }
}

- (void)setupTopBar:(BOOL)showLogo {
    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 32)];
    topBar.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];
    topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:topBar];

    // Account button (left)
    UIButton *accountBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *profileImg = [UIImage imageNamed:@"nav_profile"];
    if (profileImg) {
        accountBtn.frame = CGRectMake(8, 4, 24, 24);
        [accountBtn setImage:profileImg forState:UIControlStateNormal];
        [accountBtn setTintColor:[UIColor whiteColor]];
    } else {
        accountBtn.frame = CGRectMake(8, 4, 24, 24);
        [accountBtn setTitle:@"\u2302" forState:UIControlStateNormal];
        [accountBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        accountBtn.titleLabel.font = [UIFont systemFontOfSize:18];
    }
    [accountBtn addTarget:self action:@selector(accountTapped) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:accountBtn];

    // Search button (right) — always present
    UIButton *searchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *searchImg = [UIImage imageNamed:@"nav_search"];
    if (searchImg) {
        searchBtn.frame = CGRectMake(topBar.bounds.size.width - 32, 4, 24, 24);
        [searchBtn setImage:searchImg forState:UIControlStateNormal];
        [searchBtn setTintColor:[UIColor whiteColor]];
    } else {
        searchBtn.frame = CGRectMake(topBar.bounds.size.width - 32, 4, 24, 24);
        [searchBtn setTitle:@"\u2315" forState:UIControlStateNormal];
        [searchBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        searchBtn.titleLabel.font = [UIFont systemFontOfSize:18];
    }
    [searchBtn addTarget:self action:@selector(searchTapped) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:searchBtn];

    // Logo BELOW the top bar — only on wave page
    if (showLogo) {
        UIImage *logoImg = [UIImage imageNamed:@"yandex_music_text_logo_white"];
        if (logoImg) {
            CGFloat scale = 0.264; // 0.22 * 1.2 = 26.4%
            CGFloat logoW = logoImg.size.width * scale;
            CGFloat logoH = logoImg.size.height * scale;
            CGFloat logoY = 36; // 32px topBar + 4px gap
            UIImageView *logoView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - logoW) / 2, logoY, logoW, logoH)];
            logoView.contentMode = UIViewContentModeScaleAspectFit;
            logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            [self.view addSubview:logoView];
        } else {
            UILabel *logoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 36, self.view.bounds.size.width, 18)];
            logoLabel.text = @"\u042F\u043D\u0434\u0435\u043A\u0441 \u041C\u0443\u0437\u044B\u043A\u0430";
            logoLabel.textAlignment = NSTextAlignmentCenter;
            logoLabel.textColor = [UIColor whiteColor];
            logoLabel.font = [UIFont boldSystemFontOfSize:12];
            logoLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            [self.view addSubview:logoLabel];
        }
    }
}

- (void)accountTapped {
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
    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (del.tabBarController && del.tabBarController.viewControllers.count > 1) {
        del.tabBarController.selectedIndex = 1;
    }
}

- (void)injectToken {
    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (del.accessToken) {
        NSString *js = [NSString stringWithFormat:@"window.__YM_TOKEN__ = '%@'; window.__GUEST__ = false; if(window.onTokenReady) window.onTokenReady();", del.accessToken];
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

- (BOOL)isPublicPath:(NSString *)path {
    if ([path hasPrefix:@"/search"] || [path hasPrefix:@"/landing3/"]) {
        return YES;
    }
    return NO;
}

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

    if (!token && [self isPublicPath:path]) {
        // Allow without auth
    } else if (!token) {
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
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    if (token) {
        [request setValue:[NSString stringWithFormat:@"OAuth %@", token] forHTTPHeaderField:@"Authorization"];
    }

    if (reqBody && [method isEqualToString:@"POST"]) {
        NSError *jsonErr;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:reqBody options:0 error:&jsonErr];
        if (jsonData) {
            request.HTTPBody = jsonData;
        }
    }

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *resultStr = @"{}";
        NSInteger statusCode = 0;
        if (error) {
            // Return structured error with status code hint
            resultStr = [NSString stringWithFormat:@"{\"error\":{\"message\":\"%@\",\"code\":-1}}", error.localizedDescription];
        } else if (data) {
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            statusCode = httpResp.statusCode;
            resultStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (!resultStr) resultStr = @"{}";
            
            // Wrap HTTP error status into JSON error object
            if (statusCode >= 400) {
                // Try to parse original response and keep its structure
                // but ensure there's a clear error message
                if (![resultStr containsString:@"\"error\""]) {
                    NSString *statusMsg = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
                    resultStr = [NSString stringWithFormat:@"{\"error\":{\"message\":\"%@ (HTTP %ld)\",\"code\":%ld}}", statusMsg, (long)statusCode, (long)statusCode];
                }
            }
        }

        // Base64 encode to avoid JS string escaping issues
        NSData *resultData = [resultStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *b64 = [resultData base64EncodedStringWithOptions:0];
        NSString *js = [NSString stringWithFormat:@"window.__ymApiCallback('%@', window.atob('%@'));", callbackId, b64];

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

    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (del.isGuestMode) {
        NSString *js = @"window.__ymPlayerUpdate({\"error\":\"guest\",\"message\":\"\u0412\u043E\u0439\u0434\u0438\u0442\u0435 \u0432 \u0430\u043A\u043A\u0430\u0443\u043D\u0442 \u0434\u043B\u044F \u043F\u0440\u043E\u0441\u043B\u0443\u0448\u0438\u0432\u0430\u043D\u0438\u044F\"});";
        [self.webView evaluateJavaScript:js completionHandler:nil];
        return;
    }

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
        AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        del.tabBarController.selectedIndex = 0;
    }
}

@end