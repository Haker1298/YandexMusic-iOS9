#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface OAuthViewController : UIViewController <WKNavigationDelegate>
@property (strong, nonatomic) WKWebView *webView;
@end