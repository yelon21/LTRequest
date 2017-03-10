//
//  LTRequest.h
//  YJBM
//
//  Created by yelon on 16/1/1.
//  Copyright © 2016年 yelon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LTRequest : NSOperation

@property(nonatomic,strong,readonly,nullable) NSMutableURLRequest *request;

@property(nonatomic,assign) BOOL supportSSL;

@property(nonatomic,strong) void (^_Nullable CompleteBlock)(NSData *_Nullable, NSString *_Nullable);
@property(nonatomic,strong) void (^_Nullable ProgressBlock)(double, double,NSData *_Nullable,NSData *_Nullable);
@property(nonatomic,strong) void (^_Nullable ReponseBlock)(NSURLResponse *_Nullable, NSString *_Nullable);

- (void)lt_setValue:(NSString * _Nonnull)value forHTTPHeaderField:(NSString * _Nonnull)field;
- (void)lt_addPostValue:(_Nonnull id <NSObject>)value forKey:( NSString * _Nonnull)key;
- (void)lt_setHttpBody:(NSData * _Nonnull)postData;

- (NSURLRequest  * _Nonnull)lt_postUrl:(NSString * _Nonnull)urlString
                              complete:(void (^_Nullable)(NSData *_Nullable responseData, NSString *_Nullable errorString))completeBlock;

- (NSURLRequest * _Nonnull)lt_requestUrl:(NSString * _Nonnull)urlString
                              httpMethod:(NSString * _Nonnull)httpMethod
                                response:(void (^_Nullable)(NSURLResponse *_Nullable response, NSString *_Nullable errorString))responseBlock
                                progress:(void (^_Nullable)(double currentLength, double totleLength, NSData *_Nonnull receiveData, NSData *_Nonnull appendData))progressBlock
                                complete:(void (^_Nullable)(NSData * _Nullable responseData, NSString * _Nullable errorString))completeBlock;

- (NSURLRequest * _Nonnull)lt_getResponseUrl:(NSString * _Nonnull)urlString
                           response:(void (^_Nullable)(NSURLResponse *_Nullable response, NSString *_Nullable errorString))responseBlock;
@end
