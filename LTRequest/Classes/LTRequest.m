//
//  LTRequest.m
//  YJBM
//
//  Created by yelon on 16/1/1.
//  Copyright © 2016年 yelon. All rights reserved.
//

#import "LTRequest.h"

//#define NSLog(fmt, ...) nil

@interface NSString (LTRequest)

//转换特殊字符
- (NSString *)lt_LTRequestEscapedValue;
@end

@implementation NSString (LTRequest)

//转换特殊字符
- (NSString *)lt_LTRequestEscapedValue{
    //    __bridge_transfer arc时候用(__bridge_transfer NSString *)
    return ( NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                  NULL,
                                                                                  (__bridge CFStringRef)self,
                                                                                  NULL,
                                                                                  CFSTR("!*'();:@&=+$,/?%#[]"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));;
}

@end

static NSOperationQueue *sharedQueue = nil;

@interface LTRequest ()<NSURLConnectionDelegate,NSURLConnectionDataDelegate,NSURLSessionDelegate>{

    BOOL isURLSession;
    double expectedContentLength;
    BOOL isForResponse;
    NSData *httpPostData;
}
@property(nonatomic,strong,readwrite)NSMutableURLRequest *request;
@property(nonatomic,strong) NSURLConnection *connection;
@property(nonatomic,strong) NSURLSessionTask *sessionTask;
@property(nonatomic,strong) NSMutableData *receiveData;
@property(nonatomic,strong) NSMutableArray *postData;
@property(nonatomic,strong) NSMutableDictionary *httpHeaderDic;

@end

@implementation LTRequest
#pragma mark NSOperation

-(instancetype)init{

    if (self = [super init]) {
        
        sharedQueue = [[NSOperationQueue alloc] init];
        [sharedQueue setMaxConcurrentOperationCount:5];
//        finish = NO;
    }
    return self;
}

-(NSMutableDictionary *)httpHeaderDic{

    if (!_httpHeaderDic) {
        _httpHeaderDic = [[NSMutableDictionary alloc]init];
    }
    return _httpHeaderDic;
}

-(void)lt_setValue:(NSString *)value forHTTPHeaderField:(NSString *)field{

    self.httpHeaderDic[field] = value;
}

- (void)lt_addPostValue:(id <NSObject>)value forKey:(NSString *)key{

    if (!self.postData) {
        
        self.postData = [[NSMutableArray alloc]init];
    }
    [[self postData] addObject:@{@"key":key,@"value":[value description]}];
}

- (void)lt_setHttpBody:(NSData *)postData{

    httpPostData = postData;
}

- (NSData *)postBodyData{

    NSData *postBodyData = nil;
    
    if (httpPostData) {
        
        postBodyData = httpPostData;
    }
    else{
    
        NSMutableArray *postArgs = [[NSMutableArray alloc]init];
        
        for (NSDictionary *dic in self.postData) {
            
            NSString *argString = [NSString stringWithFormat:@"%@=%@",[dic[@"key"] lt_LTRequestEscapedValue],[dic[@"value"] lt_LTRequestEscapedValue]];
            [postArgs addObject:argString];
        }
        NSLog(@"postArgs==%@",postArgs);
        NSString *postBodyString = [postArgs componentsJoinedByString:@"&"];
        NSLog(@"postBodyString==%@",postBodyString);
        postBodyData = [postBodyString dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    return postBodyData;
}

- (NSURLRequest  * _Nonnull)lt_postUrl:(NSString * _Nonnull)urlString
                              complete:(void (^_Nullable)(NSData *_Nullable responseData, NSString *_Nullable errorString))completeBlock{

    return [self lt_requestUrl:urlString
                    httpMethod:@"POST"
                      response:nil
                      progress:nil
                      complete:completeBlock];
}

- (NSURLRequest * _Nonnull)lt_requestUrl:(NSString * _Nonnull)urlString
                              httpMethod:(NSString * _Nonnull)httpMethod
                                response:(void (^_Nullable)(NSURLResponse *_Nullable response, NSString *_Nullable errorString))responseBlock
                                progress:(void (^_Nullable)(double currentLength, double totleLength, NSData *_Nonnull receiveData, NSData *_Nonnull appendData))progressBlock
                                complete:(void (^_Nullable)(NSData * _Nullable responseData, NSString * _Nullable errorString))completeBlock{
    
    if (!urlString||![urlString isKindOfClass:[NSString class]]) {
        
        return nil;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    if (!url) {
        
        return nil;
    }
    
    expectedContentLength = 0;
    
    [sharedQueue addOperation:self];
    
    self.CompleteBlock  = completeBlock;
    self.ProgressBlock  = progressBlock;
    self.ReponseBlock   = responseBlock;
    
    self.request = [[NSMutableURLRequest alloc]initWithURL:url];
    
    for (NSString *key in [self.httpHeaderDic allKeys]) {
        
        [self.request setValue:self.httpHeaderDic[key] forHTTPHeaderField:key];
    }
    
    self.request.HTTPMethod = httpMethod?httpMethod:@"GET";
    self.request.HTTPBody = [self postBodyData];
    
    Class urlSession = NSClassFromString(@"NSURLSession");
    if (urlSession) {
        isURLSession = YES;
        [self initURLSession];
    }
    else{
        
        isURLSession = NO;
        [self initURLConnection];
    }
    
    return self.request;
}

- (NSURLRequest * _Nonnull)lt_getResponseUrl:(NSString * _Nonnull)urlString
                                    response:(void (^_Nullable)(NSURLResponse *_Nullable response, NSString *_Nullable errorString))responseBlock{

    isForResponse = YES;
    return [self lt_requestUrl:urlString
                    httpMethod:@"GET"
                      response:responseBlock
                      progress:nil
                      complete:nil];
}

- (void)initURLSession{
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:sharedQueue];
    
    self.sessionTask = [session dataTaskWithRequest:self.request];
    [self.sessionTask resume];
}

- (void)initURLConnection{

    self.connection = [[NSURLConnection alloc]initWithRequest:_request
                                                     delegate:self
                                             startImmediately:NO];
    [self.connection start];
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"error==%@",error);
//    finish = YES;
    
    if (self.ReponseBlock) {
        
        self.ReponseBlock(nil,[error localizedDescription]);
    }
    if (self.CompleteBlock) {
        self.CompleteBlock(nil,[error localizedDescription]);
    }
    
}
//认证
- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection{
    
    return NO;
}
//- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
//    NSLog(@"challenge==%@",challenge);
//}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    
    NSLog(@"protectionSpace==%@",protectionSpace);
    if (self.supportSSL) {
        
        return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
    }
    else{
        
        return NO;
    }
}

//- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
//    NSLog(@"challenge==%@",challenge);
//}
- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"challenge==%@",challenge);
    
    if (self.supportSSL) {
        
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
            
            NSURLCredential *cre = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            
            [challenge.sender useCredential:cre forAuthenticationChallenge:challenge];
        }
    }
    else{
    
        
    }
}

#pragma mark NSURLConnectionDataDelegate

- (nullable NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(nullable NSURLResponse *)response{

    NSLog(@"request==%@",request);
    NSLog(@"response==%@",response);
    
    return request;
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"response==%@",response);
    NSLog(@"suggestedFilename==%@",response.suggestedFilename);
    NSLog(@"textEncodingName==%@",response.textEncodingName);
    NSLog(@"MIMEType==%@",response.MIMEType);
    NSLog(@"expectedContentLength==%@",@(response.expectedContentLength));
    if (isForResponse) {
        
        [self.connection cancel];
    }
    
    if (self.ReponseBlock) {
        self.ReponseBlock(response,nil);
    }
    expectedContentLength = [@(response.expectedContentLength) doubleValue];
    self.receiveData = [[NSMutableData alloc]init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    
    NSLog(@"[data length]==%@",@([data length]));
    [self.receiveData appendData:data];

    double receiveDataLength = [@([self.receiveData length]) doubleValue];
    NSLog(@"receiveDataLength==%@",@(receiveDataLength));
    
    if (self.ProgressBlock) {
        
        self.ProgressBlock(receiveDataLength,expectedContentLength,self.receiveData,data);
    }
}

//- (nullable NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request{
//    NSLog(@"request==%@",request);
//}
- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
    
    NSLog(@"bytesWritten==%@",@(bytesWritten));
    NSLog(@"totalBytesWritten==%@",@(totalBytesWritten));
    NSLog(@"totalBytesExpectedToWrite==%@",@(totalBytesExpectedToWrite));
}

- (nullable NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse{
    
    NSLog(@"cachedResponse==%@",cachedResponse);
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    NSLog(@"connectionDidFinishLoading");
    NSLog(@"[self.receiveData length]==%@",@([self.receiveData length]));
    
    if (self.CompleteBlock) {
        self.CompleteBlock(self.receiveData,nil);
    }
}

#pragma mark NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * __nullable))completionHandler{

    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    
    NSLog(@"response==%@",response);
    NSLog(@"suggestedFilename==%@",response.suggestedFilename);
    NSLog(@"textEncodingName==%@",response.textEncodingName);
    NSLog(@"MIMEType==%@",response.MIMEType);
    NSLog(@"expectedContentLength==%@",@(response.expectedContentLength));
    
    if (self.ReponseBlock) {
        self.ReponseBlock(response,nil);
    }
    
    expectedContentLength = [@(response.expectedContentLength) doubleValue];
    self.receiveData = [[NSMutableData alloc]init];
    
    if (isForResponse) {
        
        completionHandler(NSURLSessionResponseCancel);
    }
    else{
    
        completionHandler(NSURLSessionResponseAllow);
    }
}
/* Sent when data is available for the delegate to consume.  It is
 * assumed that the delegate will retain and not copy the data.  As
 * the data may be discontiguous, you should use
 * [NSData enumerateByteRangesUsingBlock:] to access it.
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    
    NSLog(@"[data length]==%@",@([data length]));
    [self.receiveData appendData:data];
    
    double receiveDataLength = [@([self.receiveData length]) doubleValue];
    NSLog(@"receiveDataLength==%@",@(receiveDataLength));
    
    if (self.ProgressBlock) {
        
        self.ProgressBlock(receiveDataLength,expectedContentLength,self.receiveData,data);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    
    NSLog(@"didCompleteWithError=%@",error);
    NSLog(@"[self.receiveData length]==%@",@([self.receiveData length]));
    
    if (self.CompleteBlock) {
        
        if (error) {
            
            self.CompleteBlock(nil,error.localizedDescription);
        }
        else{
        
            self.CompleteBlock(self.receiveData,nil);
        }
    }
}

/* The last message a session receives.  A session will only become
 * invalid because of a systemic error or when it has been
 * explicitly invalidated, in which case the error parameter will be nil.
 */
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error{

    
}

/* If implemented, when a connection level authentication challenge
 * has occurred, this delegate will be given the opportunity to
 * provide authentication credentials to the underlying
 * connection. Some types of authentication will apply to more than
 * one request on a given connection to a server (SSL Server Trust
 * challenges).  If this delegate message is not implemented, the
 * behavior will be to use the default handling, which may involve user
 * interaction.
 */
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    
    if (self.supportSSL) {
        
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
            
            NSURLCredential *cre = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            // 调用block
            completionHandler(NSURLSessionAuthChallengeUseCredential,cre);
        }
    }
    else{
    
         completionHandler(NSURLSessionAuthChallengePerformDefaultHandling,nil);
    }
}

@end
