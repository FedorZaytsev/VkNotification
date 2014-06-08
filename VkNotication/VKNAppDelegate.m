//
//  VKNAppDelegate.m
//  VkNotication
//
//  Created by Lobster on 05.06.14.
//  Copyright (c) 2014 Lobster. All rights reserved.
//

#import "VKNAppDelegate.h"

@implementation VKNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.Lobster.VkNotificationOSX", YES);
    
    //Save last unread message
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    messageID = [NSNumber numberWithLong:[userDefaults integerForKey:@"messageID"]];
    
    //Set delegates
    [self.authView setFrameLoadDelegate:self];
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    //Trying to get access_token every 2 seconds until network will not be available
    startRequest = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(tryToConnect) userInfo:nil repeats:YES];
    
    //VK client ID
    ourClientID = @"";
    
}

-(void)tryToConnect {
    NSLog(@"tryToConnect");
    
    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://vk.com"]];
    NSURLResponse * response = nil;
    NSError * error = nil;
    
    //Send synchronous request to check internet connection. It's ok to send synchronous becouse we don't have GUI
    if ([NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error]) {
    
        NSString* request = [NSString  stringWithFormat:@"https://oauth.vk.com/authorize?client_id=%@&scope=messages,notifications&redirect_uri=http://vk.com/&display=page&v=5.21&response_type=token",ourClientID];
        
        //Send request via hidden webview
        [[self.authView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:request]]];
    }
}

-(void)checkMessanges {
    //That function send every 2 second synchronous request for server and checks if there is any new messages
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.vk.com/method/messages.getDialogs?v=5.21&access_token=%@&count=1&unread=1",token]];
    
    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest
                                          returningResponse:&response
                                                      error:&error];
    if (!data) return;
    id pureData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSDictionary* dataResponse = [pureData objectForKey:@"response"];
    
    NSLog(@"%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    
    if ([[dataResponse objectForKey:@"items"] isKindOfClass:[NSArray class]] && [[dataResponse objectForKey:@"items"] count]>0) {
        NSDictionary* messageData = [[dataResponse objectForKey:@"items"][0] objectForKey:@"message"];
        NSNumber* senderID = [messageData objectForKey:@"user_id"];
        NSNumber* chatID = [messageData objectForKey:@"chat_id"];
        NSString* message = [messageData objectForKey:@"body"];
        if ([messageData objectForKey:@"attachments"]) {
            message = @"Вложение";
        }
        NSNumber* newMessageID = [messageData objectForKey:@"id"];
    
        if (![messageID isEqualToNumber:newMessageID]) {
            NSLog(@"New message %@",message);
            messageID = newMessageID;
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setInteger:[messageID integerValue] forKey:@"messageID"];
            [self processNewMessage:message fromUser:senderID fromChat:chatID];
        }
    }
    
}

- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)webFrame {
    
    //Called when webview finished loading page
    NSString *currentURL = [[[[webFrame dataSource] request] URL] absoluteString];
    
    NSLog(@"curr %@",currentURL);
    
    //If we redirected to vk.com
    if ([currentURL hasPrefix:@"http://api.vk.com/blank.html#access_token="]) {
        NSArray* seperated = [currentURL componentsSeparatedByString:@"#"];
        if ([seperated count]>0) {
            NSArray* params = [seperated[1] componentsSeparatedByString:@"&"];
            if ([params count]>0 && [params[0] hasPrefix:@"access_token"] && [params[2] hasPrefix:@"user_id"]) {
                
                token = [params[0] componentsSeparatedByString:@"="][1];
                timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(checkMessanges) userInfo:nil repeats:YES];
                
                [startRequest invalidate];
                startRequest = nil;
                
            }
        }
        [[self window] close];
    } else {
        [[self window] setIsVisible:YES];
    }
}


- (void)processNewMessage:(NSString*)msg fromUser:(NSNumber*)userID fromChat:(NSNumber*)chatID {

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.vk.com/method/users.get?user_ids=%@&v=5.21&access_token=%@&count=1&unread=1",userID,token]];
    
    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest
                                          returningResponse:&response
                                                      error:&error];
    if (!data) return;
    id pure_data = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSArray* data_response = [pure_data objectForKey:@"response"];
    NSString* fname = [data_response[0] objectForKey:@"first_name"];
    NSString* lname = [data_response[0] objectForKey:@"last_name"];
        
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = [NSString stringWithFormat:@"%@ %@",fname,lname];
    notification.informativeText = msg;
    
    NSDictionary* additionData = nil;
    if (chatID==0) {
        additionData = @{@"url": [[NSString alloc] initWithFormat:@"https://vk.com/im?sel=%@",userID]};
    } else {
        additionData = @{@"url": [[NSString alloc] initWithFormat:@"https://vk.com/im?sel=c%@",chatID]};
    }
    notification.userInfo = additionData;

        
    NSLog(@"New user %@",fname);
        
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}


- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    NSURL *url = [NSURL URLWithString: [notification.userInfo objectForKey:@"url"] ];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}

@end
