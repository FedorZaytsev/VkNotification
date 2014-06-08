//
//  VKAuthView.h
//  VkNotication
//
//  Created by Lobster on 05.06.14.
//  Copyright (c) 2014 Lobster. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface VKAuthView : WebView {
}
- (BOOL)canDrawSubviewsIntoLayer;
- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)webFrame;

@end
