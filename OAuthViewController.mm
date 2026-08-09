#import "OAuthViewController.h"
#import "AppDelegate.h"
#import "KeychainHelper.h"

static NSString *const kClientId = @"23cabbbdc6cd44269f782aa40abda634";

@implementation OAuthViewController {
    UIView *loginView;
    UIView *webViewContainer;
    UIView *tokenInputView;
    WKWebView *authWebView;
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
        logo.frame = CGRectMake((cx - s) / 2, cy * 0.22, s, s);
        logo.contentMode = UIViewContentModeScaleAspectFit;
        logo.layer.cornerRadius = 20;
        logo.layer.masksToBounds = YES;
        [loginView addSubview:logo];
    }
    
    // Title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, cy * 0.22 + 110, cx, 30)];
    titleLabel.text = @"\u042F\u043D\u0434\u0435\u043A\u0441 \u041C\u0443\u0437\u044B\u043A\u0430";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:22];
    [loginView addSubview:titleLabel];
    
    // Subtitle
    UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, cy * 0.22 + 148, cx - 40, 20)];
    subLabel.text = @"\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u0442\u043E\u043A\u0435\u043D \u0434\u043B\u044F \u0432\u0445\u043E\u0434\u0430";
    subLabel.textAlignment = NSTextAlignmentCenter;
    subLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    subLabel.font = [UIFont systemFontOfSize:13];
    [loginView addSubview:subLabel];
    
    // Token text field
    UITextField *tokenField = [[UITextField alloc] initWithFrame:CGRectMake(30, cy * 0.48, cx - 60, 40)];
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
    [loginView addSubview:tokenField];
    
    // Submit button
    UIButton *submitBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    submitBtn.frame = CGRectMake(30, cy * 0.48 + 52, cx - 60, 44);
    submitBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
    [submitBtn setTitle:@"\u0412\u043E\u0439\u0442\u0438" forState:UIControlStateNormal];
    [submitBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    submitBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    submitBtn.layer.cornerRadius = 10;
    submitBtn.clipsToBounds = YES;
    [submitBtn addTarget:self action:@selector(submitTokenFromMain) forControlEvents:UIControlEventTouchUpInside];
    [loginView addSubview:submitBtn];
    
    // Help link
    UIButton *helpBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    helpBtn.frame = CGRectMake(30, cy * 0.48 + 112, cx - 60, 36);
    helpBtn.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    helpBtn.layer.cornerRadius = 8;
    helpBtn.layer.borderColor = [UIColor colorWithWhite:0.25 alpha:1.0].CGColor;
    helpBtn.layer.borderWidth = 1;
    [helpBtn setTitle:@"\u041F\u043E\u043B\u0443\u0447\u0438\u0442\u044C \u0442\u043E\u043A\u0435\u043D" forState:UIControlStateNormal];
    [helpBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    helpBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [helpBtn addTarget:self action:@selector(openTokenPage) forControlEvents:UIControlEventTouchUpInside];
    [loginView addSubview:helpBtn];
    
    [self.view addSubview:loginView];
}

#pragma mark - WebView Login

- (void)showWebViewLogin {
    // Remove login view
    [loginView removeFromSuperview];
    
    webViewContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    webViewContainer.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];
    webViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Back button
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    backBtn.frame = CGRectMake(10, 20, 70, 36);
    [backBtn setTitle:@"< \u041D\u0430\u0437\u0430\u0434" forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    backBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [backBtn addTarget:self action:@selector(backToLogin) forControlEvents:UIControlEventTouchUpInside];
    [webViewContainer addSubview:backBtn];
    
    // Activity indicator
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinner.center = CGPointMake(self.view.bounds.size.width / 2, 70);
    spinner.tag = 42;
    [webViewContainer addSubview:spinner];
    [spinner startAnimating];
    
    // WebView
    CGFloat webY = 56;
    CGFloat webH = self.view.bounds.size.height - webY;
    authWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, webY, self.view.bounds.size.width, webH)];
    authWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    authWebView.navigationDelegate = self;
    authWebView.backgroundColor = [UIColor whiteColor];
    [webViewContainer addSubview:authWebView];
    
    [self.view addSubview:webViewContainer];
    
    // Load OAuth page — redirect to verification_code page so token appears in URL
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
    
    // Intercept verification_code page with token in URL fragment
    if ([absString containsString:@"oauth.yandex.ru/verification_code#"]) {
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
    
    // Also catch any URL with access_token in fragment
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
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webViewDidFinishLoad:(WKWebView *)webView {
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[webViewContainer viewWithTag:42];
    if (spinner) [spinner stopAnimating];
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

#pragma mark - Token Input Screen

- (void)showTokenInput {
    // Remove login view
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
    
    // Description
    UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 118, cx - 60, 50)];
    descLabel.text = @"\u0412\u0441\u0442\u0430\u0432\u044C\u0442\u0435 OAuth \u0442\u043E\u043A\u0435\u043D \u043E\u0442 \u042F\u043D\u0434\u0435\u043A\u0441\u0430. \u0415\u0441\u043B\u0438 \u0443 \u0432\u0430\u0441 \u0435\u0433\u043E \u043D\u0435\u0442 \u2014 \u043D\u0430\u0436\u043C\u0438\u0442\u0435 \u00AB\u0412\u043E\u0439\u0442\u0438 \u0447\u0435\u0440\u0435\u0437 Yandex ID\u00BB";
    descLabel.numberOfLines = 0;
    descLabel.textAlignment = NSTextAlignmentCenter;
    descLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    descLabel.font = [UIFont systemFontOfSize:13];
    [tokenInputView addSubview:descLabel];
    
    // Token text field
    UITextField *tokenField = [[UITextField alloc] initWithFrame:CGRectMake(30, 185, cx - 60, 40)];
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
    submitBtn.frame = CGRectMake(30, 240, cx - 60, 44);
    submitBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
    [submitBtn setTitle:@"\u0412\u043E\u0439\u0442\u0438" forState:UIControlStateNormal];
    [submitBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    submitBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    submitBtn.layer.cornerRadius = 10;
    submitBtn.clipsToBounds = YES;
    [submitBtn addTarget:self action:@selector(submitManualToken) forControlEvents:UIControlEventTouchUpInside];
    [tokenInputView addSubview:submitBtn];
    
    // Help text
    UILabel *helpLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 310, cx - 60, 100)];
    helpLabel.text = @"\u041A\u0430\u043A \u043F\u043E\u043B\u0443\u0447\u0438\u0442\u044C \u0442\u043E\u043A\u0435\u043D:\n\u041E\u0442\u043A\u0440\u043E\u0439\u0442\u0435 \u0441\u0441\u044B\u043B\u043A\u0443 \u043D\u0438\u0436\u0435 \u0432 \u043B\u044E\u0431\u043E\u043C \u0431\u0440\u0430\u0443\u0437\u0435\u0440\u0435, \u0432\u043E\u0439\u0434\u0438\u0442\u0435 \u0432 \u042F\u043D\u0434\u0435\u043A\u0441, \u0438 \u0441\u043A\u043E\u043F\u0438\u0440\u0443\u0439\u0442\u0435 access_token \u0438\u0437 \u0430\u0434\u0440\u0435\u0441\u0430";
    helpLabel.numberOfLines = 0;
    helpLabel.textAlignment = NSTextAlignmentCenter;
    helpLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    helpLabel.font = [UIFont systemFontOfSize:12];
    [tokenInputView addSubview:helpLabel];
    
    // Link button to get token
    UIButton *linkBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    linkBtn.frame = CGRectMake(30, 415, cx - 60, 36);
    linkBtn.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    linkBtn.layer.cornerRadius = 8;
    linkBtn.layer.borderColor = [UIColor colorWithWhite:0.25 alpha:1.0].CGColor;
    linkBtn.layer.borderWidth = 1;
    [linkBtn setTitle:@"\u041E\u0442\u043A\u0440\u044B\u0442\u044C \u0441\u0442\u0440\u0430\u043D\u0438\u0446\u0443 \u043F\u043E\u043B\u0443\u0447\u0435\u043D\u0438\u044F \u0442\u043E\u043A\u0435\u043D\u0430" forState:UIControlStateNormal];
    [linkBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    linkBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [linkBtn addTarget:self action:@selector(openTokenPage) forControlEvents:UIControlEventTouchUpInside];
    [tokenInputView addSubview:linkBtn];
    
    [self.view addSubview:tokenInputView];
}

- (void)submitTokenFromMain {
    UITextField *tf = (UITextField *)[loginView viewWithTag:999];
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

- (void)openTokenPage {
    NSString *url = @"https://oauth.yandex.ru/authorize?response_type=token&client_id=23cabbbdc6cd44269f782aa40abda634";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

#pragma mark - Back / Token Received

- (void)backToLogin {
    [webViewContainer removeFromSuperview];
    webViewContainer = nil;
    authWebView = nil;
    [self.view addSubview:loginView];
}

- (void)backToLoginFromToken {
    [tokenInputView removeFromSuperview];
    tokenInputView = nil;
    [self.view addSubview:loginView];
}

- (void)tokenReceived:(NSString *)token {
    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    del.accessToken = token;
    [KeychainHelper saveToken:token];
    [del showMainApp];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

@end