//
//  JSInterfaceWebViewWrapper.m
//
//  Created by Luca D'Alberti on 15/09/15.
//

#import "JSInterfaceWebViewWrapper.h"

#pragma mark - Error constants
static NSString * const kJSInterfaceWebViewWrapperErrorDomain = @"JSInterfaceWebViewWrapper";

// No Object Name
static NSInteger const kJSInterfaceWebViewWrapperNoObjectNameErrorCode = 1;
static NSString * const kJSInterfaceWebViewWrapperNoObjectNameErrorMessage = @"[ publicObjectNameForJSInterfaceWebView:] must return a value different from nil or from empty string";

// No dataSource or missing method implementation
static NSString * const kJSInterfaceWebViewWrapperDataSourceIsRequired = @"dataSource must implements all protocol's methods";
static NSInteger const kJSInterfaceWebViewWrapperDataSourceMissingErrorCode = 2;

// No custom schema
static NSInteger const kJSInterfaceWebViewWrapperNoSchemaErrorCode = 3;
static NSString * const kJSInterfaceWebViewWrapperNoSchemaErrorMessage = @"[ publicSchemaForJSInterfaceWebView:] must return a value different from nil or from empty string";

// Null selectors
static NSInteger const kJSInterfaceWebViewWrapperNullSelectorsErrorCode = 4;
static NSString * const kJSInterfaceWebViewWrapperNullSelectorsErrorMessage = @"[ publicSelectorsForJSInterfaceWebView:] must return a value different from nil";

@interface JSInterfaceWebViewWrapper ()
{
  UIWebView *_webView;
  
  NSString *receivedCustomSchema;
}

@end

@implementation JSInterfaceWebViewWrapper
@synthesize delegate, dataSource;

- (instancetype)init
{
  self = [super init];
  if (self)
  {
    _webView = [[UIWebView alloc] init];
    _webView.delegate = self;
  }
  return self;
}

#pragma mark - Public methods

- (void)loadRequest:(NSURLRequest *)request
{
  if (_webView)
    [_webView loadRequest:request];
}

- (void)reload
{
  if (_webView)
    [_webView reload];
}

- (JSInterfaceWebView *)viewForWebView
{
  return (JSInterfaceWebView *)_webView;
}

#pragma mark - Overwritten protocol methods to call the original delegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)])
  {
    [self.delegate webView:webView
      didFailLoadWithError:error];
  }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  [self __injectInterface];
  if (self.delegate && [self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)])
  {
    [self.delegate webViewDidFinishLoad:webView];
  }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(webViewDidStartLoad:)])
  {
    [self.delegate webViewDidStartLoad:webView];
  }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
  // Taking the custom schema from dataSource
  NSString *publicSchema = nil;
  if (self.dataSource && [self.dataSource respondsToSelector:@selector(publicSchemaForJSInterfaceWebView:)])
    publicSchema = [self.dataSource publicSchemaForJSInterfaceWebView:webView];
  
  if (publicSchema)
  {
    // Checking dataSource schema with request schema
    if ([publicSchema isEqualToString:[[request URL] scheme]])
    {
      // If YES, I will return NO and I will elaborate URL
      [self __elaborateReceivedInternalURL:[request URL]];
      return NO;
    }
  }
  // Otherwise I will call delegate
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)])
  {
    return [self.delegate webView:webView
shouldStartLoadWithRequest:request
            navigationType:navigationType];
  }
  return YES;
}

#pragma mark - Internal JS interface stuffs
- (void)__injectInterface
{
  // Generating JS Object string
  NSString *jsObjectStr = [self __generateJSObject];
  // Injecting object
  if (_webView)
    [_webView stringByEvaluatingJavaScriptFromString:jsObjectStr];
}

- (NSString *)__generateJSObject
{
  NSMutableString *completeJSString = [[NSMutableString new] autorelease];
  // Retrieve object name
  NSString *jsObjectName = [self __retrieveObjectName];
  if (! jsObjectName || [jsObjectName isEqualToString:@""])
  {
    // exception
    NSError *noObjNameError = [NSError errorWithDomain:kJSInterfaceWebViewWrapperErrorDomain
                                                  code:kJSInterfaceWebViewWrapperNoObjectNameErrorCode
                                              userInfo:@{NSLocalizedDescriptionKey : kJSInterfaceWebViewWrapperNoObjectNameErrorMessage}];
    [self __raiseException:noObjNameError];
  }
  
  // Retrieve custom schema
  NSString *customSchema = [self __retrieveCustomSchema];
  if (! customSchema || [customSchema isEqualToString:@""])
  {
    // exception
    NSError *noSchemaError = [NSError errorWithDomain:kJSInterfaceWebViewWrapperErrorDomain
                                                  code:kJSInterfaceWebViewWrapperNoSchemaErrorCode
                                              userInfo:@{NSLocalizedDescriptionKey : kJSInterfaceWebViewWrapperNoSchemaErrorMessage}];
    [self __raiseException:noSchemaError];
  }
  else
  {
    receivedCustomSchema = customSchema;
  }
  
  // Retrieve public selector list
  NSArray *publicSelectors = [self __retrieveSelectors];
  if (! publicSelectors)
  {
    // exception
    NSError *noSelectorsError = [NSError errorWithDomain:kJSInterfaceWebViewWrapperErrorDomain
                                                 code:kJSInterfaceWebViewWrapperNullSelectorsErrorCode
                                             userInfo:@{NSLocalizedDescriptionKey : kJSInterfaceWebViewWrapperNullSelectorsErrorMessage}];
    [self __raiseException:noSelectorsError];
  }
  
  // Retrieve the js string for each selector
  NSString *functionsBody = [self __convertoToJSSelectors:publicSelectors];
  
  // Returning the complete JS Object
  [completeJSString appendFormat:@"%@ = { %@ }", jsObjectName, functionsBody];
  debugLog(@"JS Object: %@", completeJSString);
  
  return completeJSString;
}

- (void)__elaborateReceivedInternalURL:(NSURL *)urlReceived
{
  // Checking if action required is public on dataSource
  NSString *action = [self __getActionFromURLAbsoluteString:[urlReceived absoluteString]];
  NSArray *selectors = [self __retrieveSelectors];
  if ([selectors containsObject:action])
  {
    // Ok, it is a public selector
    // Retrieving parameters
    NSArray *params = [self __retrieveParametersForSelector:action];
    //Retrieving value for params
    NSDictionary *paramsDictionary = [self __valuesForParams:params
                                                 inURLString:[urlReceived absoluteString]];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(webView:didReceiveCallToSelector:withParams:)])
    {
      [self.delegate webView:(JSInterfaceWebView *)_webView
    didReceiveCallToSelector:action
                  withParams:paramsDictionary];
    }
  }
}

#pragma mark - Internal utilities
- (NSError *)errorForMissingDataSourceOrIncompleteImplementation
{
  return [NSError errorWithDomain:kJSInterfaceWebViewWrapperErrorDomain
                             code:kJSInterfaceWebViewWrapperDataSourceMissingErrorCode
                         userInfo:@{NSLocalizedDescriptionKey : kJSInterfaceWebViewWrapperDataSourceIsRequired}];
}

- (void)__raiseException:(NSError *)error
{
  NSException *exception = [NSException exceptionWithName:[error domain]
                                                   reason:[error localizedDescription]
                                                 userInfo:nil];
  [exception raise];
}

- (NSString *)__retrieveObjectName
{
  if (self.dataSource && [self.dataSource respondsToSelector:@selector(publicObjectNameForJSInterfaceWebView:)])
    return [self.dataSource publicObjectNameForJSInterfaceWebView:_webView];
  else
    // exception
    [self __raiseException:[self errorForMissingDataSourceOrIncompleteImplementation]];
  return nil;
}

- (NSString *)__retrieveCustomSchema
{
  if (self.dataSource && [self.dataSource respondsToSelector:@selector(publicSchemaForJSInterfaceWebView:)])
    return [self.dataSource publicSchemaForJSInterfaceWebView:(JSInterfaceWebView *)_webView];
  else
    // exception
    [self __raiseException:[self errorForMissingDataSourceOrIncompleteImplementation]];
  return nil;
}

- (NSArray *)__retrieveSelectors
{
  if (self.dataSource && [self.dataSource respondsToSelector:@selector(publicSelectorsForJSInterfaceWebView:)])
    return [self.dataSource publicSelectorsForJSInterfaceWebView:(JSInterfaceWebView *)_webView];
  else
    // exception
    [self __raiseException:[self errorForMissingDataSourceOrIncompleteImplementation]];
  return nil;
}

- (NSArray *)__retrieveParametersForSelector:(NSString *)selectorStr
{
  if (! self.dataSource || ![self.dataSource respondsToSelector:@selector(webView:publicParametersForSelector:)])
  {
    [self __raiseException:[self errorForMissingDataSourceOrIncompleteImplementation]];
  }
  
  return [self.dataSource webView:(JSInterfaceWebView *)_webView
      publicParametersForSelector:selectorStr];
}

- (NSString *)__convertoToJSSelectors:(NSArray *)selectors
{
  // First of all, I will check if dataSource responds to protocol method
  if (! self.dataSource || ![self.dataSource respondsToSelector:@selector(webView:publicParametersForSelector:)])
  {
    [self __raiseException:[self errorForMissingDataSourceOrIncompleteImplementation]];
  }
  
  __block NSMutableString *functionsString = [NSMutableString new];
  // each object is NSString that represent the NSStringFromSelector
  [selectors enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
    NSArray *thisSelectorParams = [self.dataSource webView:(JSInterfaceWebView *)_webView
                               publicParametersForSelector:obj];
    if (thisSelectorParams.count > 0)
    {
      // Starting write the function
      [functionsString appendFormat:@"%@ : function(",obj];
      // Params can be only NSString
      // Creating the function interface
      [thisSelectorParams enumerateObjectsUsingBlock:^(NSString *param, NSUInteger idx, BOOL *stop) {
        [functionsString appendFormat:@"%@",param];
        if (idx == thisSelectorParams.count - 1)
          // It is the last one
          [functionsString appendString:@"){"];
        else
          [functionsString appendString:@","];
      }];
      
      // Creating the function implementation
      [thisSelectorParams enumerateObjectsUsingBlock:^(NSString *param, NSUInteger idx, BOOL *stop) {
        if (idx == 0)
          [functionsString appendFormat:@" document.location = \"%@://%@?", receivedCustomSchema, obj];
        
        if (idx > 0)
          // Separating params
          [functionsString appendString:@"&"];
        //Printing params
        [functionsString appendFormat:@"%@=\"+%@+\"",param,param];
        
        if (idx == thisSelectorParams.count - 1)
          // Closing function
          [functionsString appendString:@"\";}"];
      }];
      
      if (idx < selectors.count)
        // Preparing for another function
        [functionsString appendString:@","];
    }
    else
    {
      [functionsString appendFormat:@"%@ : function() { document.location = \"%@://%@\"; }",obj,receivedCustomSchema,obj];
      if (idx < selectors.count - 1)
        [functionsString appendString:@","];
    }
  }];
  
  return functionsString;
}

- (NSString *)__getActionFromURLAbsoluteString:(NSString *)absoluteStr
{
  // Splitting the string
  NSString *hierarchicalUrlPart = [absoluteStr componentsSeparatedByString:@"://"].lastObject;
  if (hierarchicalUrlPart)
  {
    return [hierarchicalUrlPart componentsSeparatedByString:@"?"].firstObject;
  }
  return nil;
}

- (NSDictionary *)__valuesForParams:(NSArray *)params inURLString:(NSString *)urlStr
{
  // Splitting the string
  NSString *hierarchicalUrlPart = [urlStr componentsSeparatedByString:@"://"].lastObject;
  if (hierarchicalUrlPart)
  {
    return [self __handleQueryString:[hierarchicalUrlPart componentsSeparatedByString:@"?"].lastObject];
  }
  return nil;
}

- (NSDictionary *)__handleQueryString:(NSString *)queryStr
{
  // queryStr = @"var1=val1&var2=val2";
  if (queryStr && [queryStr length] > 0)
  {
    NSMutableDictionary *queryDict = [NSMutableDictionary new];
    NSArray *singleQuery = [queryStr componentsSeparatedByString:@"&"];
    // singleQuery = @[@"var1=val1", @"var2=val2"];
    for (NSString *keyValue in singleQuery)
    {
      NSArray *thisQuery = [keyValue componentsSeparatedByString:@"="];
      // thisQuery = @[@"var1", @"val1"];
      NSString *key = thisQuery.firstObject;  // @"var1"
      NSString *value = thisQuery.lastObject; // @"val1"
      value = [value stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
      if (key)
      {
        [queryDict setObject:(value) ? value : @""
                      forKey:key];
        // queryDict = @{@"var1": @"val1", @"var2": @"val2"};
      }
    }
    return queryDict;
  }
  return nil;
}



@end
