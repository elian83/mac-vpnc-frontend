//
//  AppDelegate.h
//  VPNC Frontend
//
//  Created by Elian on 8/17/14.
//  Copyright (c) 2014 Elian. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window; 

@property (readwrite, retain) IBOutlet NSMenu *menu;
@property (readwrite, retain) IBOutlet NSMutableArray *arrayMenues;
@property (readwrite, retain) IBOutlet NSMenuItem *disconnectMenu;
@property (readwrite, retain) IBOutlet NSStatusItem *statusItem;
@property (readwrite, retain) IBOutlet NSString *vpnStatus;

- (IBAction)doIt:(id)sender;
- (IBAction)disconnect:(id)sender;
- (IBAction)menuCheckStatus:(id)sender;
- (IBAction)quitApp:(id)sender;
- (void) checkInterfaceStatus:(NSArray *)array;
- (void) connectTo:(NSString *)param;
- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification;

@end
