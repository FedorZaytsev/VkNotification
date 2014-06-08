//
//  VKNAppDelegate.h
//  VkNotication
//
//  Created by Lobster on 05.06.14.
//  Copyright (c) 2014 Lobster. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <ServiceManagement/ServiceManagement.h>
#import "VKAuthView.h"


@interface VKNAppDelegate : NSObject <NSApplicationDelegate,NSUserNotificationCenterDelegate> {
    NSViewController* authView;
    NSString* token;
    NSString* ourClientID;
    NSMutableData* answer;
    NSTimer* timer;
    NSNumber* messageID;
    NSTimer* startRequest;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet WebView *authView;
@property (weak) IBOutlet NSView *view;
- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)webFrame;
- (void)checkMessanges;
- (void)tryToConnect;
- (void)processNewMessage:(NSString*)msg fromUser:(NSNumber*)userID fromChat:(NSNumber*)chatID;
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification;
- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification;

@end
