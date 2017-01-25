//
//  Crypto.h
//  connectapi
//
//  Created by Mateo Marin on 12/8/16.
//  Copyright © 2016 Mateo Marin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Crypto <NSObject>

    - (void)sayHello;
    - (NSString *)getEpochTimeStamp;
    - (NSString *)secureRandomNumber;
    - (NSString*)generateHMACforpayload:(NSDictionary*)payload
                              timeStamp:(NSString*)timeStamp
                                  nonce:(NSString*)nonce
                                 apiKey:(NSString*)apiKey
                          merchantToken:(NSString*)merchantToken
                              apiSecret:(NSString*)apiSecret;
    - (void)submitAuthorizePurchaseTransactionWithPayload:(NSDictionary*)request
                                          completion:(void (^)(NSDictionary *dict, NSError* error))completion;
    - (void) postATransactionWithPayload:(NSDictionary*)payload
                         completion:(void(^)(NSDictionary *dict, NSError *error))completion;
    - (void) processPaymentOnInternet:(NSDictionary *)payload completion:(void (^)(NSDictionary *, NSError *))completion;

@end


@interface Crypto : NSObject<Crypto>

@end
