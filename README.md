# JSInterfaceWebViewWrapper
# Simple usage

    JSInterfaceWebViewWrapper *webViewWrapper = [[JSInterfaceWebViewWrapper alloc] init];
    webViewWrapper.delegate = self;
    webViewWrapper.dataSource = self;
    JSInterfaceWebView *webView = [webViewWrapper viewForWebView];
    [self.view addSubview:webView];
    
