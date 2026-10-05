#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "LarpgramConfig.h"
#import "LarpgramSettingsViewController.h"

// Forward declaration
@interface TGSettingsController : UIViewController
- (void)openLarpgramSettings;
@end

static void TGSettingsController_openLarpgramSettings(UIViewController *self, SEL _cmd) {
    LarpgramSettingsViewController *vc = [[LarpgramSettingsViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

static void (*orig_TGSettingsController_viewDidLoad)(id, SEL) = NULL;
static void swizzled_TGSettingsController_viewDidLoad(UIViewController *self, SEL _cmd) {
    if (orig_TGSettingsController_viewDidLoad) {
        orig_TGSettingsController_viewDidLoad(self, _cmd);
    }
    
    UIBarButtonItem *larpButton = [[UIBarButtonItem alloc] initWithTitle:@"⚡ Larpgram"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(openLarpgramSettings)];
    self.navigationItem.rightBarButtonItem = larpButton;
}

static NSString *(*orig_TGUser_phoneNumber)(id, SEL) = NULL;
static NSString *swizzled_TGUser_phoneNumber(id self, SEL _cmd) {
    NSString *orig = orig_TGUser_phoneNumber ? orig_TGUser_phoneNumber(self, _cmd) : nil;
    LarpgramConfig *config = [LarpgramConfig shared];
    if (config.isEnabled && config.spoofPhone && config.fakePhone.length > 0) {
        return config.fakePhone;
    }
    return orig;
}

static NSArray *(*orig_TGUser_usernames)(id, SEL) = NULL;
static NSArray *swizzled_TGUser_usernames(id self, SEL _cmd) {
    NSArray *orig = orig_TGUser_usernames ? orig_TGUser_usernames(self, _cmd) : nil;
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

static void SwizzleMethod(Class cls, SEL sel, IMP newImp, IMP *origImpOut) {
    if (!cls) return;
    Method method = class_getInstanceMethod(cls, sel);
    if (!method) return;
    IMP orig = method_getImplementation(method);
    if (origImpOut) {
        *origImpOut = orig;
    }
    if (!class_addMethod(cls, sel, newImp, method_getTypeEncoding(method))) {
        method_setImplementation(method, newImp);
    }
}

__attribute__((constructor))
static void LarpgramInit(void) {
    @autoreleasepool {
        Class tgSettingsCls = objc_getClass("TGSettingsController");
        if (tgSettingsCls) {
            class_addMethod(tgSettingsCls, @selector(openLarpgramSettings), (IMP)TGSettingsController_openLarpgramSettings, "v@:");
            SwizzleMethod(tgSettingsCls, @selector(viewDidLoad), (IMP)swizzled_TGSettingsController_viewDidLoad, (IMP *)&orig_TGSettingsController_viewDidLoad);
        }
        
        Class tgUserCls = objc_getClass("TGUser");
        if (tgUserCls) {
            SwizzleMethod(tgUserCls, @selector(phoneNumber), (IMP)swizzled_TGUser_phoneNumber, (IMP *)&orig_TGUser_phoneNumber);
            SwizzleMethod(tgUserCls, @selector(usernames), (IMP)swizzled_TGUser_usernames, (IMP *)&orig_TGUser_usernames);
        }
    }
}
