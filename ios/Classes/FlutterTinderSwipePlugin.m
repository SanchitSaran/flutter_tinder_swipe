#import "FlutterTinderSwipePlugin.h"
#if __has_include(<flutter_tinder_swipe/flutter_tinder_swipe-Swift.h>)
#import <flutter_tinder_swipe/flutter_tinder_swipe-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_tinder_swipe-Swift.h"
#endif

@implementation FlutterTinderSwipePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterTinderSwipePlugin registerWithRegistrar:registrar];
}
@end
