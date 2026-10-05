#import <UIKit/UIKit.h>
#import "LarpgramConfig.h"

@interface LarpgramSettingsViewController : UITableViewController
@end

// Declarations of Telegram internals for hooking
@interface TGPeerInfoController : UIViewController
@end

@interface TGUser : NSObject
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSArray *usernames;
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
            // Check if collectible username dictionary or object structure
            // In Telegram iOS, usernames list contains objects with {username, isCollectible, isActive}
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
    LarpgramConfig *config = [LarpgramConfig shared];
    if (config.isEnabled && config.spoofGifts && config.fakeGifts.count > 0) {
        // Here we inject custom NFT gifts into the returned stream
        return orig;
    }
    return orig;
}

%end
