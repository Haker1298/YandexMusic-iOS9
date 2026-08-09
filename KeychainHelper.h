#import <Foundation/Foundation.h>

@interface KeychainHelper : NSObject
+ (void)saveToken:(NSString *)token;
+ (NSString *)loadToken;
+ (void)deleteToken;
@end
