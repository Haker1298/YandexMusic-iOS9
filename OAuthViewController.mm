#import "OAuthViewController.h"
#import "AppDelegate.h"
#import "KeychainHelper.h"

static NSString *const kClientId = @"23cabbbdc6cd44269f782aa40abda634";
static NSString *const kRedirectURI = @"yandexmusic://auth/callback";

@implementation OAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];

    // Logo
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"app_icon"]];
    if (logo.image) {
        CGFloat s = 100;
        logo.frame = CGRectMake((self.view.bounds.size.width - s) / 2, 80, s, s);
        logo.contentMode = UIViewContentModeScaleAspectFit;
        logo.layer.cornerRadius = 22;
        logo.layer.masksToBounds = YES;
        [self.view addSubview:logo];
    }

    // Title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, self.view.bounds.size.width, 30)];
    titleLabel.text = @"\u042F\u043D\u0434\u0435\u043A\u0441 \u041C\u0443\u0437\u044B\u043A\u0430";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:22];
    [self.view addSubview:titleLabel];

    // Subtitle
    UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 240, self.view.bounds.size.width - 40, 20)];
    subLabel.text = @"\u0412\u043E\u0439\u0434\u0438\u0442\u0435 \u0441 \u043F\u043E\u043C\u043E\u0449\u044C\u044E Yandex ID";
    subLabel.textAlignment = NSTextAlignmentCenter;
    subLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    subLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:subLabel];

    // Login button
    UIButton *loginBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    loginBtn.frame = CGRectMake((self.view.bounds.size.width - 260) / 2, 300, 260, 44);
    loginBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
    [loginBtn setTitle:@"\u0412\u043E\u0439\u0442\u0438 \u0447\u0435\u0440\u0435\u0437 Yandex ID" forState:UIControlStateNormal];
    [loginBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    loginBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    loginBtn.layer.cornerRadius = 10;
    loginBtn.clipsToBounds = YES;
    [loginBtn addTarget:self action:@selector(startOAuth) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:loginBtn];

    // Manual token input
    UILabel *manualLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 380, self.view.bounds.size.width, 20)];
    manualLabel.text = @"\u0438\u043B\u0438 \u0432\u0432\u0435\u0434\u0438\u0442\u0435 \u0442\u043E\u043A\u0435\u043D \u0432\u0440\u0443\u0447\u043D\u0443\u044E:";
    manualLabel.textAlignment = NSTextAlignmentCenter;
    manualLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    manualLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:manualLabel];

    UITextField *tokenField = [[UITextField alloc] initWithFrame:CGRectMake(40, 410, self.view.bounds.size.width - 80, 36)];
    tokenField.placeholder = @"OAuth \u0442\u043E\u043A\u0435\u043D";
    tokenField.textColor = [UIColor whiteColor];
    tokenField.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    tokenField.layer.cornerRadius = 8;
    tokenField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 36)];
    tokenField.leftViewMode = UITextFieldViewModeAlways;
    tokenField.font = [UIFont systemFontOfSize:14];
    tokenField.returnKeyType = UIReturnKeyDone;
    tokenField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tokenField.autocorrectionType = UITextAutocorrectionTypeNo;
    tokenField.tag = 999;
    [self.view addSubview:tokenField];

    UIButton *manualBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    manualBtn.frame = CGRectMake((self.view.bounds.size.width - 200) / 2, 460, 200, 36);
    manualBtn.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    [manualBtn setTitle:@"\u0412\u043E\u0439\u0442\u0438" forState:UIControlStateNormal];
    [manualBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    manualBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    manualBtn.layer.cornerRadius = 8;
    manualBtn.clipsToBounds = YES;
    [manualBtn addTarget:self action:@selector(manualTokenLogin) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:manualBtn];

    // Info text
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 520, self.view.bounds.size.width - 60, 80)];
    infoLabel.text = @"\u0414\u043B\u044F \u043F\u043E\u043B\u0443\u0447\u0435\u043D\u0438\u044F \u0442\u043E\u043A\u0435\u043D\u0430 \u043E\u0442\u043A\u0440\u043E\u0439\u0442\u0435 \u0432 \u0431\u0440\u0430\u0443\u0437\u0435\u0440\u0435:\noauth.yandex.ru/authorize?response_type=token&client_id=23cabbbdc6cd44269f782aa40abda634";
    infoLabel.numberOfLines = 0;
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    infoLabel.font = [UIFont systemFontOfSize:11];
    [self.view addSubview:infoLabel];
}

- (void)startOAuth {
    // Build OAuth URL - use implicit grant flow with redirect to our custom scheme
    NSString *authURL = [NSString stringWithFormat:
        @"https://oauth.yandex.ru/authorize?response_type=token&client_id=%@&redirect_uri=%@",
        kClientId,
        [kRedirectURI stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]
    ];

    // Open in system browser (Safari) since iOS 9 WKWebView may have issues with Yandex OAuth
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:authURL]];
}

- (void)manualTokenLogin {
    UITextField *tf = (UITextField *)[self.view viewWithTag:999];
    NSString *token = tf.text;
    if (token.length > 5) {
        // Remove any whitespace
        token = [token stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        del.accessToken = token;
        [KeychainHelper saveToken:token];
        [del showMainApp];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"\u041E\u0448\u0438\u0431\u043A\u0430"
                                                       message:@"\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u043A\u043E\u0440\u0440\u0435\u043A\u0442\u043D\u044B\u0439 OAuth \u0442\u043E\u043A\u0435\u043D"
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
        [alert show];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

@end