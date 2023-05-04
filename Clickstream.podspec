#
#  Be sure to run `pod spec lint Clickstream.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name             = "Clickstream"
  s.version          = "1.1.0"
  s.summary          = "Real time Analytics SDK"
  s.description      = "Clickstream is an event agnostic, real-time data ingestion analytics SDK"

  s.homepage         = 'https://github.com/gojek/clickstream-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  
  s.author           = "Gojek"
  s.source           = { :git => 'https://github.com/gojek/clickstream-ios.git', :tag => "1.1.0" }

  s.platform         = :ios
  s.ios.deployment_target = '11.0'
  s.swift_version    = '5.0'

  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  
  
  s.default_subspec  = 'Core'

  s.subspec 'Core' do |core|
    core.source_files  = 'Sources/**/*.{h,m,swift}'
    core.exclude_files = "Example"
    core.frameworks    = "UIKit", "Foundation", "CoreTelephony"
    core.dependency    "SwiftProtobuf", "1.10.2"
    core.dependency    "ReachabilitySwift"
    core.dependency    "GRDB.swift", "6.7.0"
    core.dependency    "Starscream", "4.0.4"
  end

  s.subspec 'Tracker' do |tracker|
    tracker.source_files = 'Sources/**/*.{h,m,swift}'
    tracker.xcconfig =  { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) TRACKER_ENABLED' }
    tracker.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
    tracker.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
    tracker.dependency    "Clickstream/Core"
  end

  s.subspec 'EventVisualizer' do |eventVisualizer|
    eventVisualizer.source_files = 'Sources/**/*.{h,m,swift}'
    eventVisualizer.xcconfig =  { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) EVENT_VISUALIZER_ENABLED' }
    eventVisualizer.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
    eventVisualizer.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
    eventVisualizer.dependency    "Clickstream/Core"
  end

  s.subspec 'ETETestSuite' do |eteTestSuite|
    eteTestSuite.source_files = 'Sources/**/*.{h,m,swift}'
    eteTestSuite.xcconfig =  { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) ETE_TEST_SUITE_ENABLED' }
    eteTestSuite.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
    eteTestSuite.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
    eteTestSuite.dependency    "Clickstream/Core"
  end

end
