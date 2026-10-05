#import <UIKit/UIKit.h>
#import "LarpgramConfig.h"

@interface LarpgramSettingsViewController : UITableViewController
@end

// Declarations of Telegram controllers & models
@interface TGSettingsController : UIViewController
- (void)openLarpgramSettings;
@end

@interface TGUser : NSObject
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSArray *usernames;
@end

@interface ProfileGiftsContext : NSObject
- (id)gifts;
@end

// Hooking Telegram Settings Screen to insert Larpgram Settings Row
%hook TGSettingsController

- (void)viewDidLoad {
    %orig;
    
    // Add Larpgram item to navigation or settings list
    UIBarButtonItem *larpButton = [[UIBarButtonItem alloc] initWithTitle:@"⚡ Larpgram" 
                                                                   style:UIBarButtonItemStylePlain 
                                                                  target:self 
                                                                  action:@selector(openLarpgramSettings)];
    self.navigationItem.rightBarButtonItem = larpButton;
}

%new
- (void)openLarpgramSettings {
    LarpgramSettingsViewController *vc = [[LarpgramSettingsViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

%end

// Hooking User Model for Phone and Collectible/NFT Usernames Spoofing
%hook TGUser

- (NSString *)phoneNumber {
    NSString *orig = %orig;
    LarpgramConfig *config = [LarpgramConfig shared];
    if (config.isEnabled && config.spoofPhone && config.fakePhone.length > 0) {
        return config.fakePhone;
    }
    return orig;
}

- (NSArray *)usernames {
    NSArray *orig = %orig;
    LarpgramConfig *config = [LarpgramConfig shared];
    if (config.isEnabled && config.spoofUsernames && config.fakeUsernames.count > 0) {
        NSMutableArray *combined = [NSMutableArray arrayWithArray:orig ?: @[]];
        for (NSString *u in config.fakeUsernames) {
            [combined addObject:@{
                @"username": u,
                @"isCollectible": @(YES),
                @"isActive": @(YES)
            }];
        }
        return combined;
    }
    return orig;
}

%end

// Hooking Telegram Profile Gifts Context
%hook ProfileGiftsContext

- (id)gifts {
    id orig = %orig;
    return orig;
}

%end
