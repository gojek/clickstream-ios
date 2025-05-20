#
#  Be sure to run `pod spec lint Clickstream.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name             = "Clickstream"
  s.version          = "2.0.37"
  s.summary          = "Real time Analytics SDK"
  s.description      = "Clickstream is an event agnostic, real-time data ingestion analytics SDK"

  s.homepage         = 'https://github.com/gojek/clickstream-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  
  s.author           = "Gojek"
  s.source           = { :git => 'https://github.com/gojek/clickstream-ios.git', :tag => s.version }

  s.platform         = :ios
  s.ios.deployment_target = '12.0'
  s.swift_version    = '5.0'

  s.source_files  = 'Sources/**/*.swift'
  s.exclude_files = "Example"
  s.exclude_files = "Sources/ETETestSuite/**/*.swift"
  s.frameworks    = "UIKit", "Foundation", "CoreTelephony"
  s.dependency    "SwiftProtobuf", "~> 1.29.0"
  s.dependency    "ReachabilitySwift", '>= 5.0.0'
  s.dependency    "GRDB.swift", "~> 6.7.0"
  s.dependency    "Starscream", "4.0.5"
  
  s.default_subspec  = 'Core'

  s.subspec 'Core' do |core|
  end

  s.subspec 'Tracker' do |tracker|
    tracker.xcconfig =  { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) TRACKER_ENABLED' }
  end

  s.subspec 'EventVisualizer' do |eventVisualizer|
    eventVisualizer.xcconfig =  { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) EVENT_VISUALIZER_ENABLED' }
  end

  s.subspec 'ETETestSuite' do |eteTestSuite|
    eteTestSuite.xcconfig =  { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) ETE_TEST_SUITE_ENABLED' }
  end

end
