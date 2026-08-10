#import "OAuthViewController.h"
#import "AppDelegate.h"
#import "KeychainHelper.h"

// Official Yandex Music web client ID — you CANNOT create your own OAuth app for Yandex Music
// Source: https://github.com/MarshalX/yandex-music-api
static NSString *const kClientId = @"23cabbbdc6cd418abb4b39c32c41195d";
static NSString *const kRedirectURI = @"https://music.yandex.ru/";

@implementation OAuthViewController {
    UIView *loginView;
    UIView *tokenInputView;
    WKWebView *authWebView;
    UIView *webViewContainer;
    UILabel *errorLabel;
    UILabel *statusLabel;
    BOOL _tokenCaptured;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];
    [self buildLoginView];
}

#pragma mark - Login Main Screen

- (void)buildLoginView {
    loginView = [[UIView alloc] initWithFrame:self.view.bounds];
    loginView.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];
    loginView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    CGFloat cy = self.view.bounds.size.height;
    CGFloat cx = self.view.bounds.size.width;
    
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"app_icon"]];
    if (logo.image) {
        CGFloat s = 90;
        logo.frame = CGRectMake((cx - s) / 2, cy * 0.15, s, s);
        logo.contentMode = UIViewContentModeScaleAspectFit;
        logo.layer.cornerRadius = 20;
        logo.layer.masksToBounds = YES;
        [loginView addSubview:logo];
    }
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, cy * 0.15 + 108, cx, 30)];
    titleLabel.text = @"\u042F\u043D\u0434\u0435\u043A\u0441 \u041C\u0443\u0437\u044B\u043A\u0430";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:22];
    [loginView addSubview:titleLabel];
    
    UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, cy * 0.15 + 140, cx, 20)];
    subLabel.text = @"\u0412\u0445\u043E\u0434 \u0447\u0435\u0440\u0435\u0437 \u042F\u043D\u0434\u0435\u043A\u0441 ID";
    subLabel.textAlignment = NSTextAlignmentCenter;
    subLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    subLabel.font = [UIFont systemFontOfSize:14];
    [loginView addSubview:subLabel];
    
    CGFloat bottomY = cy - 160;
    
    UIButton *loginBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    loginBtn.frame = CGRectMake(30, bottomY, cx - 60, 50);
    loginBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
    [loginBtn setTitle:@"\u0412\u043E\u0439\u0442\u0438 \u0447\u0435\u0440\u0435\u0437 \u042F\u043D\u0434\u0435\u043A\u0441 ID" forState:UIControlStateNormal];
    [loginBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    loginBtn.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    loginBtn.layer.cornerRadius = 12;
    loginBtn.clipsToBounds = YES;
    [loginBtn addTarget:self action:@selector(showWebViewLogin) forControlEvents:UIControlEventTouchUpInside];
    [loginView addSubview:loginBtn];
    
    UIButton *guestBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    guestBtn.frame = CGRectMake(30, bottomY + 66, cx - 60, 44);
    guestBtn.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    [guestBtn setTitle:@"\u0413\u043E\u0441\u0442\u0435\u0432\u043E\u0439 \u0440\u0435\u0436\u0438\u043C" forState:UIControlStateNormal];
    [guestBtn setTitleColor:[UIColor colorWithWhite:0.6 alpha:1.0] forState:UIControlStateNormal];
    guestBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    guestBtn.layer.cornerRadius = 10;
    guestBtn.layer.borderColor = [UIColor colorWithWhite:0.25 alpha:1.0].CGColor;
    guestBtn.layer.borderWidth = 1;
    guestBtn.clipsToBounds = YES;
    [guestBtn addTarget:self action:@selector(enterGuestMode) forControlEvents:UIControlEventTouchUpInside];
    [loginView addSubview:guestBtn];
    
    UIButton *manualBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    manualBtn.frame = CGRectMake(0, bottomY + 124, cx, 30);
    [manualBtn setTitle:@"\u0412\u0432\u0435\u0441\u0442\u0438 \u0442\u043E\u043A\u0435\u043D \u0432\u0440\u0443\u0447\u043D\u0443\u044E" forState:UIControlStateNormal];
    [manualBtn setTitleColor:[UIColor colorWithWhite:0.35 alpha:1.0] forState:UIControlStateNormal];
    manualBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [manualBtn addTarget:self action:@selector(showTokenInput) forControlEvents:UIControlEventTouchUpInside];
    [loginView addSubview:manualBtn];
    
    [self.view addSubview:loginView];
}

#pragma mark - Token Input Screen

- (void)showTokenInput {
    [loginView removeFromSuperview];
    
    tokenInputView = [[UIView alloc] initWithFrame:self.view.bounds];
    tokenInputView.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];
    tokenInputView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    CGFloat cx = self.view.bounds.size.width;
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    backBtn.frame = CGRectMake(10, 20, 70, 36);
    [backBtn setTitle:@"< \u041D\u0430\u0437\u0430\u0434" forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    backBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [backBtn addTarget:self action:@selector(backToLoginFromToken) forControlEvents:UIControlEventTouchUpInside];
    [tokenInputView addSubview:backBtn];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, cx, 28)];
    titleLabel.text = @"\u0412\u0432\u043E\u0434 \u0442\u043E\u043A\u0435\u043D\u0430";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [tokenInputView addSubview:titleLabel];
    
    UITextField *tokenField = [[UITextField alloc] initWithFrame:CGRectMake(30, 130, cx - 60, 40)];
    tokenField.placeholder = @"y0_AgAAAAA...";
    tokenField.textColor = [UIColor whiteColor];
    tokenField.backgroundColor = [UIColor colorWithWhite:0.13 alpha:1.0];
    tokenField.layer.cornerRadius = 8;
    tokenField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 40)];
    tokenField.leftViewMode = UITextFieldViewModeAlways;
    tokenField.font = [UIFont systemFontOfSize:13];
    tokenField.returnKeyType = UIReturnKeyDone;
    tokenField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tokenField.autocorrectionType = UITextAutocorrectionTypeNo;
    tokenField.tag = 999;
    [tokenInputView addSubview:tokenField];
    
    UIButton *submitBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    submitBtn.frame = CGRectMake(30, 185, cx - 60, 44);
    submitBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
    [submitBtn setTitle:@"\u0412\u043E\u0439\u0442\u0438" forState:UIControlStateNormal];
    [submitBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    submitBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    submitBtn.layer.cornerRadius = 10;
    submitBtn.clipsToBounds = YES;
    [submitBtn addTarget:self action:@selector(submitManualToken) forControlEvents:UIControlEventTouchUpInside];
    [tokenInputView addSubview:submitBtn];
    
    UILabel *helpLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 250, cx - 60, 80)];
    helpLabel.text = @"\u0412\u0441\u0442\u0430\u0432\u044C\u0442\u0435 OAuth \u0442\u043E\u043A\u0435\u043D \u043E\u0442 \u042F\u043D\u0434\u0435\u043A\u0441 \u041C\u0443\u0437\u044B\u043A\u0438\n\n\u041F\u043E\u043B\u0443\u0447\u0438\u0442\u044C \u0442\u043E\u043A\u0435\u043D \u043C\u043E\u0436\u043D\u043E \u0447\u0435\u0440\u0435\u0437 \u0432\u0445\u043E\u0434 \u0447\u0435\u0440\u0435\u0437 \u042F\u043D\u0434\u0435\u043A\u0441 ID";
    helpLabel.numberOfLines = 0;
    helpLabel.textAlignment = NSTextAlignmentCenter;
    helpLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    helpLabel.font = [UIFont systemFontOfSize:12];
    [tokenInputView addSubview:helpLabel];
    
    [self.view addSubview:tokenInputView];
}

- (void)submitManualToken {
    UITextField *tf = (UITextField *)[tokenInputView viewWithTag:999];
    NSString *token = [tf.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (token.length > 5) {
        [self tokenReceived:token];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"\u041E\u0448\u0438\u0431\u043A\u0430"
                                                       message:@"\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u043A\u043E\u0440\u0440\u0435\u043A\u0442\u043D\u044B\u0439 OAuth \u0442\u043E\u043A\u0435\u043D"
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - Guest Mode

- (void)enterGuestMode {
    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    del.accessToken = nil;
    del.isGuestMode = YES;
    [del showMainApp];
}

#pragma mark - WebView Login (Yandex ID) — Implicit OAuth Flow

- (void)showWebViewLogin {
    [loginView removeFromSuperview];
    [tokenInputView removeFromSuperview];
    _tokenCaptured = NO;
    
    webViewContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    webViewContainer.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];
    webViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    backBtn.frame = CGRectMake(10, 24, 70, 36);
    backBtn.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    [backBtn setTitle:@"< \u041D\u0430\u0437\u0430\u0434" forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    backBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    backBtn.layer.cornerRadius = 8;
    [backBtn addTarget:self action:@selector(backToLogin) forControlEvents:UIControlEventTouchUpInside];
    [webViewContainer addSubview:backBtn];
    
    statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 65, self.view.bounds.size.width, 20)];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    statusLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    statusLabel.font = [UIFont systemFontOfSize:12];
    statusLabel.text = @"\u0417\u0430\u0433\u0440\u0443\u0437\u043A\u0430 \u042F\u043D\u0434\u0435\u043A\u0441 ID...";
    statusLabel.tag = 60;
    [webViewContainer addSubview:statusLabel];
    
    errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 85, self.view.bounds.size.width - 40, 0)];
    errorLabel.textColor = [UIColor redColor];
    errorLabel.font = [UIFont systemFontOfSize:13];
    errorLabel.numberOfLines = 0;
    errorLabel.textAlignment = NSTextAlignmentCenter;
    errorLabel.hidden = YES;
    [webViewContainer addSubview:errorLabel];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.websiteDataStore = [WKWebsiteDataStore defaultDataStore];
    
    // Inject a script that runs at document start on EVERY page.
    // It polls for access_token in the URL and sends it via postMessage.
    // This is the MOST RELIABLE way on iOS 9 where redirects with fragments
    // happen too fast for decidePolicyForNavigationAction to catch.
    NSString *tokenSniffer =
        @"(function(){"
        @"var sent=false;"
        @"function check(){if(sent)return;"
        @"var h=window.location.href;"
        @"var m=h.match(/[#&?]access_token=([^&]+)/);"
        @"if(m&&m[1].length>10){sent=true;"
        @"try{window.webkit.messageHandlers.ymauth.postMessage(m[1]);}catch(e){}}"
        @"}"
        @"check();"
        @"setInterval(check,150);"
        @"var oldPushState=history.pushState;"
        @"history.pushState=function(){oldPushState.apply(this,arguments);check();};"
        @"window.addEventListener('hashchange',check);"
        @"window.addEventListener('popstate',check);"
        @"})();";
    
    WKUserScript *script = [[WKUserScript alloc]
        initWithSource:tokenSniffer
        injectionTime:WKUserScriptInjectionTimeAtDocumentStart
        forMainFrameOnly:YES];
    
    config.userContentController = [[WKUserContentController alloc] init];
    [config.userContentController addUserScript:script];
    [config.userContentController addScriptMessageHandler:self name:@"ymauth"];
    
    authWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) configuration:config];
    authWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    authWebView.navigationDelegate = self;
    authWebView.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];
    authWebView.opaque = NO;
    authWebView.scrollView.bounces = YES;
    [webViewContainer addSubview:authWebView];
    
    [self.view addSubview:webViewContainer];
    
    // Implicit OAuth flow
    NSString *authURL = [NSString stringWithFormat:
        @"https://oauth.yandex.ru/authorize?response_type=token&client_id=%@&redirect_uri=%@",
        kClientId, kRedirectURI
    ];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:authURL]
                                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                                     timeoutInterval:30];
    [authWebView loadRequest:req];
    
    // Safety: also poll from native side every 500ms
    [self startTokenPolling];
}

- (void)startTokenPolling {
    __block int attempts = 0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [self pollForToken:attempts];
    });
}

- (void)pollForToken:(int)attempt {
    if (_tokenCaptured || !authWebView) return;
    if (attempt > 120) return; // 60 seconds max
    
    [authWebView evaluateJavaScript:@"(function(){var h=window.location.href;var m=h.match(/[#&?]access_token=([^&]+)/);return m?m[1]:'';})();"
        completionHandler:^(id result, NSError *err) {
            if (!err && [result isKindOfClass:[NSString class]]) {
                NSString *token = (NSString *)result;
                if (token.length > 10) {
                    [self captureToken:token source:@"poll"];
                    return;
                }
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                [self pollForToken:attempt + 1];
            });
        }];
}

#pragma mark - WKScriptMessageHandler (for injected token sniffer)

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([[message name] isEqualToString:@"ymauth"]) {
        NSString *token = nil;
        if ([message.body isKindOfClass:[NSString class]]) {
            token = (NSString *)message.body;
        }
        if (token && token.length > 10) {
            [self captureToken:token source:@"inject"];
        }
    }
}

- (void)captureToken:(NSString *)token source:(NSString *)src {
    if (_tokenCaptured) return;
    _tokenCaptured = YES;
    NSLog(@"[YM OAuth] Token captured via %@! Length: %lu", src, (unsigned long)token.length);
    [self setStatusText:@"\u0422\u043E\u043A\u0435\u043D \u043F\u043E\u043B\u0443\u0447\u0435\u043D!"];
    [self tokenReceived:token];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (_tokenCaptured) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    NSURL *url = navigationAction.request.URL;
    if (!url) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    NSString *absString = [url absoluteString];
    
    // Intercept redirect to music.yandex.ru
    if ([absString containsString:@"music.yandex.ru"]) {
        NSString *fragment = [url fragment];
        NSString *query = [url query];
        
        // Check fragment first, then query
        NSString *tokenStr = fragment ?: query;
        if (tokenStr && [tokenStr containsString:@"access_token="]) {
            NSString *token = [self extractToken:tokenStr];
            if (token && token.length > 0) {
                decisionHandler(WKNavigationActionPolicyCancel);
                [self captureToken:token source:@"nav"];
                return;
            }
        }
        
        // Check for error
        if (tokenStr && ([tokenStr containsString:@"error="])) {
            NSString *errMsg = [self extractParam:@"error_description" fromQuery:tokenStr]
                           ?: [self extractParam:@"error" fromQuery:tokenStr]
                           ?: @"\u0410\u0432\u0442\u043E\u0440\u0438\u0437\u0430\u0446\u0438\u044F \u043E\u0442\u043C\u0435\u043D\u0435\u043D\u0430";
            decisionHandler(WKNavigationActionPolicyCancel);
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"\u041E\u0448\u0438\u0431\u043A\u0430"
                                                               message:errMsg
                                                              delegate:nil
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
                [alert show];
                [self backToLogin];
            });
            return;
        }
        
        // Let music.yandex.ru load — injected script will catch the token
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (_tokenCaptured) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (errorLabel) errorLabel.hidden = YES;
        if (statusLabel && authWebView) {
            NSString *urlStr = [authWebView.URL absoluteString];
            if (urlStr && ![urlStr containsString:@"oauth.yandex.ru/authorize"]) {
                statusLabel.text = @"";
            }
        }
    });
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (errorLabel) errorLabel.hidden = YES;
    });
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"[YM OAuth] didFailProvisionalNavigation: %@", error.localizedDescription);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showOAuthError: @[error.localizedDescription, @"\u041F\u0440\u043E\u0432\u0435\u0440\u044C\u0442\u0435 \u0438\u043D\u0442\u0435\u0440\u043D\u0435\u0442-\u0441\u043E\u0435\u0434\u0438\u043D\u0435\u043D\u0438\u0435"]];
    });
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"[YM OAuth] didFailNavigation: %@", error.localizedDescription);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showOAuthError: @[error.localizedDescription]];
    });
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (navigationAction.request.URL) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

#pragma mark - Helpers

- (void)setStatusText:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (statusLabel) {
            statusLabel.text = text;
            statusLabel.hidden = (text.length == 0);
        }
    });
}

- (void)showOAuthError:(NSArray *)messages {
    if (!errorLabel) return;
    errorLabel.hidden = NO;
    NSMutableString *text = [[NSMutableString alloc] init];
    for (int i = 0; i < messages.count; i++) {
        if (i > 0) [text appendString:@"\n"];
        [text appendString:messages[i]];
    }
    errorLabel.text = text;
    CGFloat h = [text sizeWithFont:errorLabel.font constrainedToSize:CGSizeMake(self.view.bounds.size.width - 40, 200)].height;
    errorLabel.frame = CGRectMake(20, 85, self.view.bounds.size.width - 40, h + 10);
}

- (NSString *)extractToken:(NSString *)fragment {
    NSArray *pairs = [fragment componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        if (kv.count >= 2 && [[kv[0] lowercaseString] isEqualToString:@"access_token"]) {
            return [kv[1] stringByRemovingPercentEncoding];
        }
    }
    return nil;
}

- (NSString *)extractParam:(NSString *)paramName fromQuery:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        if (kv.count >= 2 && [[kv[0] lowercaseString] isEqualToString:[paramName lowercaseString]]) {
            return [kv[1] stringByRemovingPercentEncoding];
        }
    }
    return nil;
}

#pragma mark - Back / Token Received

- (void)backToLogin {
    _tokenCaptured = YES; // stop polling
    [webViewContainer removeFromSuperview];
    webViewContainer = nil;
    authWebView = nil;
    errorLabel = nil;
    statusLabel = nil;
    [self buildLoginView];
}

- (void)backToLoginFromToken {
    [tokenInputView removeFromSuperview];
    tokenInputView = nil;
    [self buildLoginView];
}

- (void)tokenReceived:(NSString *)token {
    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    del.accessToken = token;
    del.isGuestMode = NO;
    [KeychainHelper saveToken:token];
    [del showMainApp];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

@end