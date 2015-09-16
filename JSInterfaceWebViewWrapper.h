//
//  JSInterfaceWebViewWrapper.h
//
//  Created by Luca D'Alberti on 15/09/15.
//

#import <Foundation/Foundation.h>
@class JSInterfaceWebViewWrapper;

/**
 *  UIView wrapped for JSInterfaceWebViewWrapper class
 */
typedef UIView JSInterfaceWebView;

/**
 *  It extends UIWebViewDelegate protocol. You need to conform to JSInterfaceWebViewDelegate protocol
 *  and you need to implement all the UIWebViewDelegate protocol's methods and this protocol's also
 */
@protocol JSInterfaceWebViewDelegate <UIWebViewDelegate>

/**
 *  Called when the JSInterfaceWebView will be redirected to a custom schema URL.
 *
 *  @param webView      The UIWebView wrapped to JSInterfaceWebView instance
 *  @param selectorName The public selector it want to call
 *  @param params       The params. It can be nil
 */
- (void)webView:(JSInterfaceWebView *)webView didReceiveCallToSelector:(NSString *)selectorName withParams:(NSDictionary *)params;

@end

/**
 *  The JSInterfaceWebView data source. It will populate internal states to make JSInterface works.
 */
@protocol JSInterfaceWebViewDataSource <NSObject>
@required

/**
 *  It asks for a list selector string
 *
 *  @param webView The JSInterfaceWebView instance
 *
 *  @return Return a list of NSString of selector you want to make public
 *
 *  @warning It raises an exception if dataSource does not respond to selector or if the NSArray is nil
 */
- (NSArray *)publicSelectorsForJSInterfaceWebView:(JSInterfaceWebView *)webView;

/**
 *  It ask for a list of parameters string for a specific public selector
 *
 *  @param webView      The JSInterfaceWebView instance
 *  @param selectorName The selector name
 *
 *  @return Return a list of parameter for the specific selector
 *
 *  @warning It raises an exception if dataSource does not respond to selector. NSArray can be nil
 */
- (NSArray *)webView:(JSInterfaceWebView *)webView publicParametersForSelector:(NSString *)selectorName;

/**
 *  It asks for the public JS object name
 *
 *  @param webView The JSInterfaceWebView instance
 *
 *  @return Name of the public JS object
 *
 *  @warning It raises an exception if dataSource does not respond to selector or if the NSString is nil
 *           or empty
 */
- (NSString *)publicObjectNameForJSInterfaceWebView:(JSInterfaceWebView *)webView;

/**
 *  It asks for the custom schema
 *
 *  @param webView The JSInterfaceWebView instance
 *
 *  @return The custom schema
 *
 *  @warning It raises an exception if dataSource does not respond to selector or if the NSString is nil
 *           or empty
 */
- (NSString *)publicSchemaForJSInterfaceWebView:(JSInterfaceWebView *)webView;

@end

@interface JSInterfaceWebViewWrapper : NSObject <UIWebViewDelegate>

@property (nonatomic, assign) id<JSInterfaceWebViewDelegate> delegate;
@property (nonatomic, assign) id<JSInterfaceWebViewDataSource> dataSource;

/**
 *  After init, you should retrieve the JSInterfaceWebView using viewForWebView and add it to your 
 *  view.
 *
 *  @return JSInterfaceWebViewWrapper instance
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER;

#pragma mark - UIWebView wrapped methods
// The JSInterfaceWebViewWrapper owner hasn't got access directly to the UIWebView instance.
// You should use viewForWebView to retrieve a UIView wrapped to
- (void)loadRequest:(NSURLRequest *)request;
- (void)reload;

/**
 *  Ask the JSInterfaceWebView instance
 *
 *  @return JSInterfaceWebView instance
 */
- (JSInterfaceWebView *)viewForWebView;

@end