//
//  AppDelegate.m
//  EaseMobUI
//
//  Created by 周玉震 on 15/6/30.
//  Copyright (c) 2015年 周玉震. All rights reserved.
//

#import "AppDelegate.h"

#import "MainController.h"
#import "ULoginController.h"
#import "UAccount.h"

#import "EaseMobUIClient.h"
#import "EM+Common.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

#import <EaseMobSDKFull/EaseMob.h>
#import <Toast/UIView+Toast.h>

#define EaseMob_AppKey (@"zhou-yuzhen#easemobchatui")

#ifdef DEBUG
#define EaseMob_APNSCertName (@"apns_dev")
#else
#define EaseMob_APNSCertName (@"apns_pro")
#endif

@interface AppDelegate ()<EMChatManagerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    UIViewController *rootController;
    
    BOOL isAutoLogin = [[EaseMob sharedInstance].chatManager isAutoLoginEnabled];
    if (isAutoLogin) {
        rootController = [[MainController alloc]init];
    }else{
        rootController = [[UINavigationController alloc]initWithRootViewController:[[ULoginController alloc]init]];
    }
    self.window.rootViewController = rootController;
    [self.window makeKeyAndVisible];
    
    [EaseMobUIClient sharedInstance];
    [[EaseMob sharedInstance] registerSDKWithAppKey:EaseMob_AppKey apnsCertName:EaseMob_APNSCertName];
    [[EaseMob sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        [application registerForRemoteNotifications];
        UIUserNotificationType notificationTypes = UIUserNotificationTypeBadge |
        UIUserNotificationTypeSound |
        UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
        [application registerUserNotificationSettings:settings];
    }else{
        UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeBadge |
        UIRemoteNotificationTypeSound |
        UIRemoteNotificationTypeAlert;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
    }

    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    [[EaseMob sharedInstance] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    [[EaseMob sharedInstance] application:application didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[EaseMobUIClient sharedInstance] applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[EaseMobUIClient sharedInstance] applicationWillEnterForeground:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[EaseMobUIClient sharedInstance] applicationWillTerminate:application];
}

- (void)changeRootControllerToMain{
    BACK(^{
        sleep(1);
        MAIN(^{
            if (![self.window.rootViewController isMemberOfClass:[MainController class]]) {
                self.window.rootViewController = [[MainController alloc]init];
            }
        });
    });
}

- (void)changeRootControllerToLogin{
    BACK(^{
        sleep(1);
        MAIN(^{
            if ([self.window.rootViewController isMemberOfClass:[MainController class]]) {
                self.window.rootViewController = [[UINavigationController alloc]initWithRootViewController:[[ULoginController alloc]init]];
            }
        });
    });
}

#pragma mark - EMChatManagerLoginDelegate
- (void)didLoginWithInfo:(NSDictionary *)loginInfo error:(EMError *)error{
    if (!error) {
        [[EaseMob sharedInstance].chatManager enableAutoLogin];
        [self.window makeToast:@"登录成功"];
        [self changeRootControllerToMain];
    }else{
        [self.window makeToast:error.description];
    }
}

- (void)willAutoLoginWithInfo:(NSDictionary *)loginInfo error:(EMError *)error{
    if (!error) {
        [self.window makeToast:@"自动登录中..."];
    }else{
        [self.window makeToast:error.description];
        [self changeRootControllerToLogin];
    }
}

- (void)didAutoLoginWithInfo:(NSDictionary *)loginInfo error:(EMError *)error{
    if (!error) {
        [self.window makeToast:@"自动登录完成"];
    }else{
        [self.window makeToast:error.description];
        [self changeRootControllerToLogin];
    }
}

- (void)didLogoffWithError:(EMError *)error{
    if (!error) {
        [self.window makeToast:@"已注销"];
        [self changeRootControllerToLogin];
    }
}

- (void)didLoginFromOtherDevice{
    [self.window makeToast:@"您的账号已在其他设备登录"];
    [self changeRootControllerToLogin];
}

- (void)didRemovedFromServer{
    
}

- (void)didRegisterNewAccount:(NSString *)username password:(NSString *)password error:(EMError *)error{
    if (!error) {
        [self.window makeToast:@"注册成功"];
        [self changeRootControllerToMain];
    }else{
        [self.window makeToast:error.description];
    }
}

- (void)willAutoReconnect{
    
}

- (void)didAutoReconnectFinishedWithError:(NSError *)error{
    
}

#pragma mark - EMChatManagerUtilDelegate
- (void)didConnectionStateChanged:(EMConnectionState)connectionState{
    
}

@end