#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "LarpgramConfig.h"
#import "LarpgramSettingsViewController.h"

// MARK: - Floating Overlay Button
@interface LarpgramFloatingButton : UIButton
+ (instancetype)sharedButton;
- (void)attachToWindow:(UIWindow *)window;
- (void)openSettings;
@end

@implementation LarpgramFloatingButton {
    UIPanGestureRecognizer *_panGesture;
}

+ (instancetype)sharedButton {
    static LarpgramFloatingButton *btn = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        btn = [[LarpgramFloatingButton alloc] initWithFrame:CGRectZero];
    });
    return btn;
}

- (instancetype)initWithFrame:(CGRect)frame {
    CGRect screen = [UIScreen mainScreen].bounds;
    CGRect initialFrame = CGRectMake(screen.size.width - 58, screen.size.height - 180, 46, 46);
    self = [super initWithFrame:initialFrame];
    if (self) {
        [self setTitle:@"⚡" forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:22];
        self.backgroundColor = [UIColor colorWithRed:0.12 green:0.53 blue:0.90 alpha:0.88];
        self.layer.cornerRadius = 23.0;
        self.layer.masksToBounds = NO;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 3);
        self.layer.shadowOpacity = 0.35;
        self.layer.shadowRadius = 4.0;
        self.layer.borderWidth = 1.5;
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.35].CGColor;

        [self addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];

        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:_panGesture];
    }
    return self;
}

- (void)openSettings {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *w in scene.windows) {
                    if (w.isKeyWindow) { keyWindow = w; break; }
                }
            }
        }
    }
    if (!keyWindow) {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }

    UIViewController *topVC = keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }

    if ([topVC isKindOfClass:[UINavigationController class]]) {
        UIViewController *visible = [(UINavigationController *)topVC visibleViewController];
        if ([visible isKindOfClass:[LarpgramSettingsViewController class]]) {
            return;
        }
    }

    LarpgramSettingsViewController *settingsVC = [[LarpgramSettingsViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    [topVC presentViewController:nav animated:YES completion:nil];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);

    CGRect screen = [UIScreen mainScreen].bounds;
    CGFloat halfW = self.bounds.size.width / 2.0;
    CGFloat halfH = self.bounds.size.height / 2.0;
    newCenter.x = MAX(halfW + 8, MIN(screen.size.width - halfW - 8, newCenter.x));
    newCenter.y = MAX(halfH + 35, MIN(screen.size.height - halfH - 35, newCenter.y));

    self.center = newCenter;
    [pan setTranslation:CGPointZero inView:self.superview];
}

- (void)attachToWindow:(UIWindow *)window {
    if (!window) return;
    if (![LarpgramConfig shared].showFloatingButton) {
        [self removeFromSuperview];
        return;
    }
    if (self.superview != window) {
        [self removeFromSuperview];
        [window addSubview:self];
    }
    [window bringSubviewToFront:self];
}
@end

// MARK: - Swizzling Helper
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

// MARK: - UIWindow Hooks (Floating Button & Shake)
static void (*orig_UIWindow_makeKeyAndVisible)(id, SEL) = NULL;
static void swizzled_UIWindow_makeKeyAndVisible(UIWindow *self, SEL _cmd) {
    if (orig_UIWindow_makeKeyAndVisible) {
        orig_UIWindow_makeKeyAndVisible(self, _cmd);
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[LarpgramFloatingButton sharedButton] attachToWindow:self];
    });
}

static void (*orig_UIWindow_motionEnded)(id, SEL, UIEventSubtype, UIEvent *) = NULL;
static void swizzled_UIWindow_motionEnded(UIWindow *self, SEL _cmd, UIEventSubtype motion, UIEvent *event) {
    if (orig_UIWindow_motionEnded) {
        orig_UIWindow_motionEnded(self, _cmd, motion, event);
    }
    if (motion == UIEventSubtypeMotionShake && [LarpgramConfig shared].isEnabled) {
        [[LarpgramFloatingButton sharedButton] openSettings];
    }
}

// MARK: - UILabel Visual Spoofing Hooks
static BOOL LooksLikePhoneNumber(NSString *str) {
    if (!str || str.length < 8) return NO;
    NSString *trimmed = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![trimmed hasPrefix:@"+"]) return NO;
    NSCharacterSet *phoneChars = [NSCharacterSet characterSetWithCharactersInString:@"+0123456789 ()-"];
    NSCharacterSet *inverted = [phoneChars invertedSet];
    return [trimmed rangeOfCharacterFromSet:inverted].location == NSNotFound;
}

static void (*orig_UILabel_setText)(id, SEL, NSString *) = NULL;
static void swizzled_UILabel_setText(UILabel *self, SEL _cmd, NSString *text) {
    LarpgramConfig *config = [LarpgramConfig shared];
    if (config.isEnabled && config.spoofPhone && LooksLikePhoneNumber(text) && config.fakePhone.length > 0) {
        text = config.fakePhone;
    }
    if (orig_UILabel_setText) {
        orig_UILabel_setText(self, _cmd, text);
    }
}

static void (*orig_UILabel_setAttributedText)(id, SEL, NSAttributedString *) = NULL;
static void swizzled_UILabel_setAttributedText(UILabel *self, SEL _cmd, NSAttributedString *attrText) {
    LarpgramConfig *config = [LarpgramConfig shared];
    if (config.isEnabled && config.spoofPhone && attrText && LooksLikePhoneNumber(attrText.string) && config.fakePhone.length > 0) {
        NSMutableAttributedString *mut = [attrText mutableCopy];
        [mut.mutableString setString:config.fakePhone];
        attrText = mut;
    }
    if (orig_UILabel_setAttributedText) {
        orig_UILabel_setAttributedText(self, _cmd, attrText);
    }
}

// MARK: - UIViewController Settings Entry Hook
static void (*orig_UIViewController_viewDidAppear)(id, SEL, BOOL) = NULL;
static void swizzled_UIViewController_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated) {
    if (orig_UIViewController_viewDidAppear) {
        orig_UIViewController_viewDidAppear(self, _cmd, animated);
    }
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"SettingsController"] || [self.title isEqualToString:@"Settings"] || [self.title isEqualToString:@"Настройки"]) {
        if (!self.navigationItem.rightBarButtonItem || ![self.navigationItem.rightBarButtonItem.title isEqualToString:@"⚡ Larpgram"]) {
            UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"⚡ Larpgram"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:[LarpgramFloatingButton sharedButton]
                                                                    action:@selector(openSettings)];
            self.navigationItem.rightBarButtonItem = item;
        }
    }
}

// MARK: - Constructor
__attribute__((constructor))
static void LarpgramInit(void) {
    @autoreleasepool {
        // Initialize config
        [LarpgramConfig shared];

        // Hook UIWindow
        Class windowCls = [UIWindow class];
        SwizzleMethod(windowCls, @selector(makeKeyAndVisible), (IMP)swizzled_UIWindow_makeKeyAndVisible, (IMP *)&orig_UIWindow_makeKeyAndVisible);
        SwizzleMethod(windowCls, @selector(motionEnded:withEvent:), (IMP)swizzled_UIWindow_motionEnded, (IMP *)&orig_UIWindow_motionEnded);

        // Hook UILabel for Phone Spoofing
        Class labelCls = [UILabel class];
        SwizzleMethod(labelCls, @selector(setText:), (IMP)swizzled_UILabel_setText, (IMP *)&orig_UILabel_setText);
        SwizzleMethod(labelCls, @selector(setAttributedText:), (IMP)swizzled_UILabel_setAttributedText, (IMP *)&orig_UILabel_setAttributedText);

        // Hook UIViewController for Settings
        Class vcCls = [UIViewController class];
        SwizzleMethod(vcCls, @selector(viewDidAppear:), (IMP)swizzled_UIViewController_viewDidAppear, (IMP *)&orig_UIViewController_viewDidAppear);
    }
}
