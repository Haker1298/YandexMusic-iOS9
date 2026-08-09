#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface WebViewController : UIViewController <WKScriptMessageHandler>
@property (strong, nonatomic) WKWebView *webView;
@property (copy, nonatomic) NSString *pageName;
- (id)initWithPage:(NSString *)page title:(NSString *)title;
- (void)injectToken;
- (void)updatePlayerState:(NSDictionary *)state;
@end