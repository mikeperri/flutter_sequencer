#import "./CallbackManager/CallbackManager.h"
#import "./CocoaScheduler/CocoaScheduler.h"
#import "./Scheduler/BaseScheduler.h"
#import "./Scheduler/SchedulerEvent.h"
#import "./AudioUnit/Sfizz/SfizzDSPKernelAdapter.h"

#import "FlutterSequencerPlugin.h"
#if __has_include(<flutter_sequencer/flutter_sequencer-Swift.h>)
#import <flutter_sequencer/flutter_sequencer-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_sequencer-Swift.h"
#endif

@implementation FlutterSequencerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterSequencerPlugin registerWithRegistrar:registrar];
}
@end
