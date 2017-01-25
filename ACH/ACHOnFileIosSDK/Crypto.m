//
//  Crypto.m
//  connectapi
//
//  Created by Mateo Marin on 12/8/16.
//  Copyright © 2016 Mateo Marin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Crypto.h"

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>
#import <Security/SecRandom.h>
#import "SBJson4Writer.h"
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <SystemConfiguration/SystemConfiguration.h>

#define STATUS_KEY_NAME @"validation_status"
#define SERVER_ERROR_MSG @"Internal Server Error. Please try later"

//common crypto implementation
@implementation Crypto : NSObject {
}

-(void)sayHello
    {
        NSLog(@"Hello World from Crypto");
    }

-(NSString *)getEpochTimeStamp
{
    NSString *timeStamp = [NSString stringWithFormat:@"%.0f",round([[NSDate date]timeIntervalSince1970]*1000)];
    return timeStamp;
}

-(NSString *)secureRandomNumber
{
    unsigned int randomNumber;
    
    NSMutableData *data = [NSMutableData dataWithLength:kCCKeySizeAES256];
    
    SecRandomCopyBytes(kSecRandomDefault, [data length], data.mutableBytes);
    
    NSString* dataString = [self convertByteArrayToHexString:data];// data to hex
    
    NSScanner* scanner = [NSScanner scannerWithString:dataString];
    
    [scanner scanHexInt:&randomNumber];
    
    return [NSString stringWithFormat:@"%u",randomNumber];
}

- (NSString*)generateHMACforpayload:(NSDictionary*)payload
                          timeStamp:(NSString*)timeStamp
                              nonce:(NSString*)nonce
                             apiKey:(NSString*)apiKey
                      merchantToken:(NSString*)merchantToken
                          apiSecret:(NSString*)apiSecret
{
    unsigned char outputHMAC[CC_SHA1_DIGEST_LENGTH];
    
    SBJson4Writer * parseString = [[SBJson4Writer alloc] init];
    
    NSString *payloadString = [parseString stringWithObject:payload];
    
    NSString *hmacData = [NSString stringWithFormat:@"%@%@%@%@%@",apiKey,nonce,timeStamp,merchantToken,payloadString];
    
    const char *keyChar = [apiSecret cStringUsingEncoding:NSASCIIStringEncoding];
    
    const char *dataChar = [hmacData cStringUsingEncoding:NSUTF8StringEncoding];
    
    CCHmac(kCCHmacAlgSHA1, keyChar, strlen(keyChar), dataChar, strlen(dataChar), outputHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:outputHMAC length:sizeof(outputHMAC)];
    
    //    TODO: better way to convert ByteArray to hex.
    
    NSString*hmacString = [self convertByteArrayToHexString:HMAC];
    
    //    Return Base64 of (HMAC hash in hex)
    return [[hmacString dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    
}

-(NSString*)convertByteArrayToHexString:(NSData*)dataToBeConverted{
    
    
    /*  Since Hex will take two characters for each byte - hex string length is twice the bytes.
     *  Resource: http://stackoverflow.com/questions/3183841/base64-vs-hex-for-sending-binary-content-over-the-internet-in-xml-doc
     *  Simplest way %02x produces hex result for a byte
     *  x - lowercase
     *  X - uppercase
     */
    
    NSMutableString *hexString = [NSMutableString stringWithCapacity:[dataToBeConverted length]*2];
    const unsigned char *dataBytes = [dataToBeConverted bytes];
    for (NSInteger idB = 0; idB < [dataToBeConverted length]; ++idB) {
        [hexString appendFormat:@"%02x", dataBytes[idB]];
    }
    return hexString;
}

-(void)submitAuthorizePurchaseTransactionWithPayload:(NSDictionary*)request
                                                    completion:(void (^)(NSDictionary *dict, NSError* error))completion
{
    [self postATransactionWithPayload:request  completion:^(NSDictionary *dict, NSError *error){
        
        if (error) {
            completion(nil, error);
            return;
        }
        
        if([dict valueForKey:STATUS_KEY_NAME]){ // valid response
            
            completion(dict,nil);
        }else{
            completion(dict,[NSError errorWithDomain:SERVER_ERROR_MSG code:101 userInfo:nil]);
        }
    }];
}

-(void) postATransactionWithPayload:(NSDictionary*)payload
                         completion:(void(^)(NSDictionary *dict, NSError *error))completion
{
    BOOL networkStatus = [self isInternetReachable];
    if (!networkStatus) {
        completion(nil,[NSError errorWithDomain:@"No Internet Connection Found. Please connect to wifi or cellular data" code:100 userInfo:nil]);
    }else{
        [self processPaymentOnInternet:payload completion:completion];
    }
}

- (void)processPaymentOnInternet:(NSDictionary *)payload completion:(void (^)(NSDictionary *, NSError *))completion
{
    NSError* errDataConversion;
    
    NSString*timeStamp = [self getEpochTimeStamp];
    
    NSString *nonce = [self secureRandomNumber];
    
    NSString *apiKey = @"GCHJa9HZ8YNeRdYAvcAANVduoTLA8ytC";
    NSString *apiSecret = @"861d1d01e529f90fe7ccdc31784ea60431a6b032e77076a78e3d8b00e620fb09";
    NSString *token = @"fdoa-76345db6732a624375f7fbae433d102376345db6732a6243";
    
    NSString *url = @"https://api-cert.payeezy.com/v1/ach/consumer/enrollment";
    
    NSString *hmacSignature = [self generateHMACforpayload:payload timeStamp:timeStamp nonce:nonce apiKey:apiKey merchantToken:token apiSecret:apiSecret];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    // Specify that it will be a POST request
    request.HTTPMethod = @"POST";
    
    // This is how we set header fields
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:hmacSignature forHTTPHeaderField:@"Authorization"];
    [request setValue:timeStamp forHTTPHeaderField:@"timestamp"];
    [request setValue:nonce forHTTPHeaderField:@"nonce"];
    [request setValue:apiKey forHTTPHeaderField:@"apikey"];
    [request setValue:token forHTTPHeaderField:@"token"];
    // new parameter added for 5/28 release
    //[request setValue:self.merchantIdentifier forHTTPHeaderField:@"x-merchant-identifier"];
    //[request setValue:self.trToken forHTTPHeaderField:@"trtoken"];
    
    // Convert your data and set your request's HTTPBody property
    SBJson4Writer * parseString = [[SBJson4Writer alloc] init];
    
    NSString* payloadString = [parseString stringWithObject:payload];
    request.HTTPBody = [payloadString dataUsingEncoding:NSUTF8StringEncoding];
    
    //enable logging in debug mode
#ifdef DEBUG
    
    NSLog(@"URL: %@",url);
    NSLog(@"Request: %@",payloadString);
    NSLog(@"URL: %@",hmacSignature);
#endif
    if (!errDataConversion) {
        // Create url connection and fire request
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *urlResponse, NSData *data, NSError *connectionError) {
            
            NSError* errJSONConverison;
            if (completion) {
                
                if (!connectionError) {
                    
                    if ([urlResponse respondsToSelector:@selector(statusCode)]) {
                        
                        if ([(NSHTTPURLResponse *) urlResponse statusCode] < 300) {
                            
                            NSDictionary* responseObject = [NSJSONSerialization
                                                            JSONObjectWithData:data
                                                            options:NSJSONReadingAllowFragments
                                                            error:&errJSONConverison];
                            completion(responseObject, nil);
                        }else{
                            
                            
                            NSDictionary* errorObject = [NSJSONSerialization
                                                         JSONObjectWithData:data
                                                         options:NSJSONReadingAllowFragments
                                                         error:&errJSONConverison];
                            
                            completion(nil, [NSError errorWithDomain:@"Payeezy Error Info" code:[(NSHTTPURLResponse *) urlResponse statusCode] userInfo:errorObject]);
                        }
                    }
                }else{
                    
                    completion(nil,connectionError);
                }
            }
            
        }];
    }else{
        
        completion(nil,errDataConversion);
    }
    
    
}

- (BOOL)isInternetReachable
{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    
    if(reachability == NULL)
        return false;
    
    if (!(SCNetworkReachabilityGetFlags(reachability, &flags)))
        return false;
    
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
        // if target host is not reachable
        return false;
    
    
    BOOL isReachable = false;
    
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
    {
        // if target host is reachable and no connection is required
        //  then we'll assume (for now) that your on Wi-Fi
        isReachable = true;
    }
    
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
    {
        // ... and the connection is on-demand (or on-traffic) if the
        //     calling application is using the CFSocketStream or higher APIs
        
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
        {
            // ... and no [user] intervention is needed
            isReachable = true;
        }
    }
    
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
    {
        // ... but WWAN connections are OK if the calling application
        //     is using the CFNetwork (CFSocketStream?) APIs.
        isReachable = true;
    }
    
    
    return isReachable;
}


@end
