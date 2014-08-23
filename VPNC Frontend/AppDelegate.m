//
//  AppDelegate.m
//  VPNC Frontend
//
//  Created by Elian on 8/17/14.
//  Copyright (c) 2014 Elian. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)awakeFromNib {
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _disconnectMenu = [[NSMenuItem alloc] initWithTitle:@"Disconnect" action:@selector(disconnect:) keyEquivalent:@""];
    _arrayMenues = [[NSMutableArray alloc] init];
    _vpnStatus = @"0";
    
    NSImage *menuIcon       = [NSImage imageNamed:@"Disconnected"];
    NSImage *highlightIcon  = [NSImage imageNamed:@"Disconnected"];
    [highlightIcon setTemplate:YES];
    
    NSURL *confPath = [NSURL URLWithString:@"file:///opt/local/etc/vpnc/"];
    
    NSError *error = nil;
    NSArray *properties = [NSArray arrayWithObjects: NSURLLocalizedNameKey,
                           NSURLCreationDateKey, NSURLLocalizedTypeDescriptionKey, nil];
    
    NSArray *array = [[NSFileManager defaultManager]
                      contentsOfDirectoryAtURL:confPath
                      includingPropertiesForKeys:properties
                      options:(NSDirectoryEnumerationSkipsHiddenFiles)
                      error:&error];
    if (array == nil) {
        // TODO: Handle error
    }
    
    for (NSURL *item in array) {
        NSString *file = [item absoluteString];
        if ([file hasSuffix:@".conf"]) {
            
            NSString *fileWithoutExt = [[file lastPathComponent] stringByDeletingPathExtension];
            NSMenuItem *newMenu = [[NSMenuItem alloc] initWithTitle:fileWithoutExt action:@selector(doIt:) keyEquivalent:@""];
            NSString* someObj = fileWithoutExt;
            
            [newMenu setRepresentedObject:someObj];
            [[self menu] addItem: newMenu];
            
            NSDictionary *menuItem = @{
                                       @"name": fileWithoutExt,
                                       @"item": newMenu
                                       };
            
            [[self arrayMenues] addObject:menuItem];
            
        }
        
    }
    
    [[self menu] addItem:[NSMenuItem separatorItem]];
    [[self menu] addItem: _disconnectMenu];
    [[self menu] addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *quitApp = [[NSMenuItem alloc] initWithTitle:@"Quit VPNC Frontend" action:@selector(quitApp:) keyEquivalent:@""];
    [[self menu] addItem: quitApp];
    
    [[self menu] setAutoenablesItems:(false)];
    
    [[self statusItem] setImage:menuIcon];
    [[self statusItem] setAlternateImage:highlightIcon];
    [[self statusItem] setMenu:[self menu]];
    [[self statusItem] setHighlightMode:YES];
    
    [self checkInterfaceStatus:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:2.0
                                     target:self
                                   selector:@selector(menuCheckStatus:)
                                   userInfo:nil
                                    repeats:YES];
    
}


- (IBAction)quitApp:(id)sender {
    [NSApp terminate: nil];
}


- (void) checkInterfaceStatus:(NSArray *)array {
    
    NSTask *task;
    NSArray *arguments;
    NSPipe *pipe;
    NSFileHandle *file;
    NSData *data;
    NSString *dataString;
    
    arguments = [NSArray arrayWithObjects: @"tun0", nil];
    pipe = [NSPipe pipe];
    file = [pipe fileHandleForReading];
    
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/sbin/ifconfig"];
    [task setArguments: arguments];
    [task setStandardOutput: pipe];
    [task launch];
    
    data = [file readDataToEndOfFile];
    dataString = [[NSString alloc] initWithData: data
                                   encoding: NSUTF8StringEncoding];
    
    /* We assume that if tun0 interface exists
        there is an active connection.
     
        TODO: find a better way to do it
     */
    if ([dataString length] > 0) {
        
        NSImage *menuIcon  = [NSImage imageNamed:@"Connected"];
        [[self statusItem] setImage:menuIcon];
        [[self statusItem] setAlternateImage:menuIcon];
        
        [[self disconnectMenu] setEnabled:(true)];
        
        /* Execute "ps aux | grep vpn | grep -v grep" to find the
            vpnc argument to know which vpn is connected
         
            TODO: find a better way to do it and handle errors
         */
        arguments = [NSArray arrayWithObjects: @"-c", @"ps aux | grep vpnc | grep -v grep", nil];
        pipe = [NSPipe pipe];
        task = [[NSTask alloc] init];
        file = [pipe fileHandleForReading];
        
        [task setLaunchPath: @"/bin/sh"];
        [task setArguments: arguments];
        [task setStandardOutput: pipe];
        [task launch];
        
        data = [file readDataToEndOfFile];
        dataString = [[NSString alloc] initWithData: data
                                       encoding: NSUTF8StringEncoding];
        
        /* Parse the output by spaces and check the last item
            which should be the operator
        */
        NSArray *array = [dataString
                          componentsSeparatedByString:@" "];
        
        // Save it and also remove the last character (\n)
        NSString* op = [array objectAtIndex:[array count]-1];
        op = [op substringToIndex:[op length]-1];
        
        /* Check if the running VPN matches with
            the one saved in the connection dictionary
         */
        for (NSDictionary *item in [self arrayMenues]) {
            NSDictionary *myself = item;
            NSString *currentVPN = myself[@"name"];
            
            if ( [currentVPN isEqualToString:op] ) {
                NSMenuItem *item = myself[@"item"];
                [item setState: NSOnState];
                _vpnStatus = myself[@"name"];
            } else {
                NSMenuItem *item = myself[@"item"];
                [item setState: NSOffState];
            }
            
        }
        
    } else {
        NSImage *menuIcon  = [NSImage imageNamed:@"Disconnected"];
        [[self statusItem] setImage:menuIcon];
        [[self statusItem] setAlternateImage:menuIcon];
        
        [[self disconnectMenu] setEnabled:(false)];
        
        for (NSDictionary *item in [self arrayMenues]) {
            
            NSDictionary *myself = item;
            
            NSMenuItem *item = myself[@"item"];
            [item setState: NSOffState];
            
        }
        
        if (![_vpnStatus isEqualToString:@"0"]) {
            
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            [notification setActionButtonTitle:@"Reconnect!"];
            [notification setHasActionButton: YES];
            notification.informativeText = @"VPNC disconnected";
            notification.title = @"VPNC Frontend";
            
            NSDictionary *notificationUserInfo = @{
                                       @"lastConnection": _vpnStatus
                                       };

            notification.userInfo = notificationUserInfo;
            notification.soundName = NSUserNotificationDefaultSoundName;

            NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
            [center setDelegate:self];
            [center scheduleNotification:notification];
            
            _vpnStatus = @"0";
            
        }
        
        
    }
    
}

- (IBAction)menuCheckStatus:(id)sender {
    
    [self checkInterfaceStatus:nil];
    
}


- (IBAction)disconnect:(id)sender {
    
    // Remove connected VPN from status variable
    _vpnStatus = @"0";
    
    char ffm_cmd[512];
    sprintf(ffm_cmd,"sudo /opt/local/sbin/vpnc-disconnect");
    system(ffm_cmd);
    
    // TODO: check vpnc-disconnect status and then display notification
    sprintf(ffm_cmd, "osascript -e 'display notification with title \"VPNC Disconnected\"'");
    system(ffm_cmd);
   
    
}

- (void) connectTo:(NSString *)param {
   
    char ffm_cmd[512];
    char *operator = (char*)[param UTF8String];
    
    // Disconnect before connect
    sprintf(ffm_cmd,"sudo /opt/local/sbin/vpnc-disconnect");
    system(ffm_cmd);
    
    // TODO: check vpnc-disconnect output and then connect
    usleep(100000);
    
    sprintf(ffm_cmd,"sudo /opt/local/sbin/vpnc %s", operator);
    system(ffm_cmd);
    
    // TODO: Check vpnc output and then display notification if it's connected
    sprintf(ffm_cmd, "osascript -e 'display notification with title \"VPNC: Connected to %s\"'", operator);
    system(ffm_cmd);
    
    // Save connected VPN
    // Used for reconnect purposes
    _vpnStatus = param;

}


- (IBAction)doIt:(id)sender; {
    
    // Connect to selected menu item
    [self connectTo:([sender representedObject])];
    
}

- (void) userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification{
    
    // Reconnect to the last active connection
    NSDictionary *params = notification.userInfo;
    [self connectTo:(params[@"lastConnection"])];
    
}

@end
