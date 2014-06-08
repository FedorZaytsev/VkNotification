//
//  VKAuthView.m
//  VkNotication
//
//  Created by Lobster on 05.06.14.
//  Copyright (c) 2014 Lobster. All rights reserved.
//

#import "VKAuthView.h"

@implementation VKAuthView

- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)webFrame {
    NSString *currentURL = [[[[webFrame dataSource] request] URL] absoluteString];
    NSLog(@"didFinishLoadForFrame: %@",currentURL);
}

- (BOOL)canDrawSubviewsIntoLayer{
    return NO;
}

@end
