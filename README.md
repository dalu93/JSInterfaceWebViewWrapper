# JSInterfaceWebViewWrapper
JSInterfaceWebViewWrapper allow you to publish some class methods on a Javascript object in the `JSInterfaceWebView`
Using `dataSource` you can provide some infos to the wrapper to configure it as well.
Conforming to `JSInterfaceWebViewDelegate` protocol, you will have access to all `UIWebViewDelegate` protocol's methods and to another one that it is `- (void)webView:(JSInterfaceWebView *)webView didReceiveCallToSelector:(NSString *)selectorName withParams:(NSDictionary *)params;`
This method will return the selector name (always without `:`, also if it accepts parameters, so, you have to check it out before call it) and a dictionary that it contains values for the key you passed before on `- (NSArray *)webView:(JSInterfaceWebView *)webView publicParametersForSelector:(NSString *)selectorName;`
# Simple usage

    JSInterfaceWebViewWrapper *webViewWrapper = [[JSInterfaceWebViewWrapper alloc] init];
    webViewWrapper.delegate = self;
    webViewWrapper.dataSource = self;
    JSInterfaceWebView *webView = [webViewWrapper viewForWebView];
    [self.view addSubview:webView];
    
    
    - (void)webView:(UIWebView *)webView didReceiveCallToSelector:(NSString *)selectorName withParams:(NSDictionary *)params
    {
      // In this example, if selectorName is "firstPublicMethod", dictionary will be
      // @{@"param1":VALUE,
      //   @"param2":VALUE};
      // If selectorName is "secondPublicMethod", dictionary is nil
      if (selectorName)
      {
        SEL selectorWithParams = NSSelectorFromString([NSString stringWithFormat:@"%@:", selectorName]);
        if ([self respondsToSelector:selectorWithParams])
        {
          [self performSelectorOnMainThread:selectorWithParams
                                 withObject:params
                              waitUntilDone:YES];
        }
        else
        {
        [self performSelectorOnMainThread:NSSelectorFromString(selectorName)
                               withObject:nil
                            waitUntilDone:YES];
        }
      }
    }

    #pragma mark - JSInterfaceWebViewDataSource
    - (NSArray *)publicSelectorsForJSInterfaceWebView:(UIWebView *)webView
    {
      return @[@"firstPublicMethod",@"secondPublicMethod"];
    }

    - (NSArray *)webView:(UIWebView *)webView publicParametersForSelector:(NSString *)selectorName
    {
      if ([selectorName isEqualToString:@"firstPublicMethod"])
        return @[@"param1",@"param2"];
      return nil;
    }

    - (NSString *)publicObjectNameForJSInterfaceWebView:(UIWebView *)webView
    {
        return @"ObjectName";
    }

    - (NSString *)publicSchemaForJSInterfaceWebView:(UIWebView *)webView
    {
        return @"my-schema";
    }

    
