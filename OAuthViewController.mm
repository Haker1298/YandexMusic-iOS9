#import "OAuthViewController.h"
#import "AppDelegate.h"
#import "KeychainHelper.h"

static NSString *const kClientId = @"b399db89f01e4bd4965cef1f7973ee05";

@implementation OAuthViewController {
    UIView *loginView;
    UIView *tokenInputView;
    WKWebView *authWebView;
    UIView *webViewContainer;
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
    
    // Logo
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"app_icon"]];
    if (logo.image) {
        CGFloat s = 90;
        logo.frame = CGRectMake((cx - s) / 2, cy * 0.18, s, s);
        logo.contentMode = UIViewContentModeScaleAspectFit;
        logo.layer.cornerRadius = 20;
        logo.layer.masksToBounds = YES;
        [loginView addSubview:logo];
    }
    
    // Title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, cy * 0.18 + 110, cx, 30)];
    titleLabel.text = @"\u042F\u043D\u0434\u0435\u043A\u0441 \u041C\u0443\u0437\u044B\u043A\u0430";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:22];
    [loginView addSubview:titleLabel];
    
    // Buttons at the bottom
    CGFloat bottomY = cy - 140;
    
    // Button 1: Vhod (login)
    UIButton *loginBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    loginBtn.frame = CGRectMake(30, bottomY, cx - 60, 48);
    loginBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
    [loginBtn setTitle:@"\u0412\u043E\u0439\u0442\u0438" forState:UIControlStateNormal];
    [loginBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    loginBtn.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    loginBtn.layer.cornerRadius = 10;
    loginBtn.clipsToBounds = YES;
    [loginBtn addTarget:self action:@selector(showTokenInput) forControlEvents:UIControlEventTouchUpInside];
    [loginView addSubview:loginBtn];
    
    // Button 2: Guest mode
    UIButton *guestBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    guestBtn.frame = CGRectMake(30, bottomY + 62, cx - 60, 48);
    guestBtn.backgroundColor = [UIColor colorWithWhite:0.18 alpha:1.0];
    [guestBtn setTitle:@"\u0413\u043E\u0441\u0442\u0435\u0432\u043E\u0439 \u0440\u0435\u0436\u0438\u043C" forState:UIControlStateNormal];
    [guestBtn setTitleColor:[UIColor colorWithWhite:0.7 alpha:1.0] forState:UIControlStateNormal];
    guestBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    guestBtn.layer.cornerRadius = 10;
    guestBtn.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:1.0].CGColor;
    guestBtn.layer.borderWidth = 1;
    guestBtn.clipsToBounds = YES;
    [guestBtn addTarget:self action:@selector(enterGuestMode) forControlEvents:UIControlEventTouchUpInside];
    [loginView addSubview:guestBtn];
    
    [self.view addSubview:loginView];
}

#pragma mark - Token Input Screen

- (void)showTokenInput {
    [loginView removeFromSuperview];
    
    tokenInputView = [[UIView alloc] initWithFrame:self.view.bounds];
    tokenInputView.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];
    tokenInputView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    CGFloat cx = self.view.bounds.size.width;
    
    // Back button
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    backBtn.frame = CGRectMake(10, 20, 70, 36);
    [backBtn setTitle:@"< \u041D\u0430\u0437\u0430\u0434" forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    backBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [backBtn addTarget:self action:@selector(backToLoginFromToken) forControlEvents:UIControlEventTouchUpInside];
    [tokenInputView addSubview:backBtn];
    
    // Title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, cx, 28)];
    titleLabel.text = @"\u0412\u0432\u043E\u0434 \u0442\u043E\u043A\u0435\u043D\u0430";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [tokenInputView addSubview:titleLabel];
    
    // Token text field
    UITextField *tokenField = [[UITextField alloc] initWithFrame:CGRectMake(30, 130, cx - 60, 40)];
    tokenField.placeholder = @"AQAAAAA...";
    tokenField.textColor = [UIColor whiteColor];
    tokenField.backgroundColor = [UIColor colorWithWhite:0.13 alpha:1.0];
    tokenField.layer.cornerRadius = 8;
    tokenField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 40)];
    tokenField.leftViewMode = UITextFieldViewModeAlways;
    tokenField.font = [UIFont systemFontOfSize:14];
    tokenField.returnKeyType = UIReturnKeyDone;
    tokenField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tokenField.autocorrectionType = UITextAutocorrectionTypeNo;
    tokenField.tag = 999;
    [tokenInputView addSubview:tokenField];
    
    // Submit button
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
    
    // Get token button - opens WebView
    UIButton *linkBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    linkBtn.frame = CGRectMake(30, 245, cx - 60, 36);
    linkBtn.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    linkBtn.layer.cornerRadius = 8;
    linkBtn.layer.borderColor = [UIColor colorWithWhite:0.25 alpha:1.0].CGColor;
    linkBtn.layer.borderWidth = 1;
    [linkBtn setTitle:@"\u041F\u043E\u043B\u0443\u0447\u0438\u0442\u044C \u0442\u043E\u043A\u0435\u043D" forState:UIControlStateNormal];
    [linkBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    linkBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [linkBtn addTarget:self action:@selector(showWebViewLogin) forControlEvents:UIControlEventTouchUpInside];
    [tokenInputView addSubview:linkBtn];
    
    // Help text
    UILabel *helpLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 300, cx - 60, 80)];
    helpLabel.text = @"\u041D\u0430\u0436\u043C\u0438\u0442\u0435 \u043A\u043D\u043E\u043F\u043A\u0443 \u0432\u044B\u0448\u0435, \u0432\u043E\u0439\u0434\u0438\u0442\u0435 \u0432 \u042F\u043D\u0434\u0435\u043A\u0441, \u0442\u043E\u043A\u0435\u043D \u0431\u0443\u0434\u0435\u0442 \u0441\u043A\u043E\u043F\u0438\u0440\u043E\u0432\u0430\u043D \u0430\u0432\u0442\u043E\u043C\u0430\u0442\u0438\u0447\u0435\u0441\u043A\u0438";
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

#pragma mark - WebView Login

- (void)showWebViewLogin {
    [tokenInputView removeFromSuperview];
    
    webViewContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    webViewContainer.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];
    webViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    backBtn.frame = CGRectMake(10, 20, 70, 36);
    [backBtn setTitle:@"< \u041D\u0430\u0437\u0430\u0434" forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    backBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [backBtn addTarget:self action:@selector(backToLogin) forControlEvents:UIControlEventTouchUpInside];
    [webViewContainer addSubview:backBtn];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinner.center = CGPointMake(self.view.bounds.size.width / 2, 70);
    spinner.tag = 42;
    [webViewContainer addSubview:spinner];
    [spinner startAnimating];
    
    CGFloat webY = 56;
    authWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, webY, self.view.bounds.size.width, self.view.bounds.size.height - webY)];
    authWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    authWebView.navigationDelegate = self;
    authWebView.backgroundColor = [UIColor whiteColor];
    [webViewContainer addSubview:authWebView];
    
    [self.view addSubview:webViewContainer];
    
    NSString *authURL = [NSString stringWithFormat:
        @"https://oauth.yandex.ru/authorize?response_type=token&client_id=%@&redirect_uri=https://oauth.yandex.ru/verification_code&display=mobile",
        kClientId
    ];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:authURL]];
    [authWebView loadRequest:req];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    NSString *absString = [url absoluteString];
    
    if ([absString containsString:@"access_token="]) {
        NSString *fragment = [url fragment];
        if (fragment) {
            NSString *token = [self extractToken:fragment];
            if (token) {
                [self tokenReceived:token];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
    }
    
    // If redirected to verification_code page, try to extract token from URL
    if ([absString containsString:@"oauth.yandex.ru/verification_code"]) {
        NSString *fragment = [url fragment];
        if (fragment && [fragment containsString:@"access_token="]) {
            NSString *token = [self extractToken:fragment];
            if (token) {
                [self tokenReceived:token];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
        // If we got to verification_code without token in fragment, show message
        if (!fragment || ![fragment containsString:@"access_token="]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"\u0422\u043E\u043A\u0435\u043D"
                                                               message:@"\u0421\u043A\u043E\u043F\u0438\u0440\u0443\u0439\u0442\u0435 access_token \u0438\u0437 \u0430\u0434\u0440\u0435\u0441\u0430 \u0441\u0442\u0440\u0430\u043D\u0438\u0446\u044B \u0438 \u0432\u0441\u0442\u0430\u0432\u044C\u0442\u0435 \u043D\u0430 \u043F\u0440\u0435\u0434\u044B\u0434\u0443\u0449\u0435\u043C \u044D\u043A\u0440\u0430\u043D\u0435"
                                                              delegate:nil
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
                [alert show];
                [self backToLogin];
            });
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[webViewContainer viewWithTag:42];
    if (spinner) [spinner stopAnimating];
    
    // Try to extract token from current URL
    NSString *url = [webView.URL absoluteString];
    if ([url containsString:@"access_token="]) {
        NSString *fragment = [webView.URL fragment];
        if (fragment) {
            NSString *token = [self extractToken:fragment];
            if (token) {
                [self tokenReceived:token];
            }
        }
    }
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

#pragma mark - Back / Token Received

- (void)backToLogin {
    [webViewContainer removeFromSuperview];
    webViewContainer = nil;
    authWebView = nil;
    [self showTokenInput];
}

- (void)backToLoginFromToken {
    [tokenInputView removeFromSuperview];
    tokenInputView = nil;
    [self.view addSubview:loginView];
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