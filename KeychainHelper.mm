#import "KeychainHelper.h"
#import <Security/Security.h>

static NSString *const kKeychainService = @"com.haker1928.yandexmusic";
static NSString *const kKeychainTokenKey = @"oauth_token";

@implementation KeychainHelper

+ (void)saveToken:(NSString *)token {
    // First delete any existing item
    [self deleteToken];

    NSData *tokenData = [token dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: kKeychainTokenKey,
        (__bridge id)kSecValueData: tokenData,
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock
    };

    SecItemAdd((__bridge CFDictionaryRef)query, NULL);
}

+ (NSString *)loadToken {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: kKeychainTokenKey,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };

    CFDataRef dataRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&dataRef);

    if (status == errSecSuccess && dataRef) {
        NSData *data = (__bridge_transfer NSData *)dataRef;
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

+ (void)deleteToken {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: kKeychainTokenKey
    };
    SecItemDelete((__bridge CFDictionaryRef)query);
}

@end