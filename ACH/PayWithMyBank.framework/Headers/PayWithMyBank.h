#import "UIKit/UIKit.h"

//! Project version number for PayWithMyBank.
FOUNDATION_EXPORT double PayWithMyBankVersionNumber;

//! Project version string for PayWithMyBank.
FOUNDATION_EXPORT const unsigned char PayWithMyBankVersionString[];

typedef void (^PayWithMyBankCallback)(UIView *payWithMyBankView, NSDictionary *returnParameters);
typedef void (^ExternalUrlCallback)(NSURLRequest * request);

@protocol PayWithMyBank <NSObject>

- (UIView *)establish:(NSDictionary *)estabilishData
             onReturn:(PayWithMyBankCallback)onReturn
             onCancel:(PayWithMyBankCallback)onCancel;

- (UIView *)verify:(NSDictionary *)verifyData
          onReturn:(PayWithMyBankCallback)onReturn
          onCancel:(PayWithMyBankCallback)onCancel;

- (void) onExternalUrl:(PayWithMyBankCallback)onExternalUrl;

@end

@interface PayWithMyBankPanel : UIView <PayWithMyBank>

@property (nonatomic, strong) UIColor *navBarColor;
@property (nonatomic, strong) UIColor *navBarButtonColor;
@property (nonatomic, strong) UIColor *navBarTitleColor;
@property (nonatomic, strong) UIColor *navBarSubtitleColor;

- (instancetype)init;

@end
