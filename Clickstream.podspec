#
#  Be sure to run `pod spec lint Clickstream.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name             = "Clickstream"
  s.version          = "1.0.0"
  s.summary          = "Real time Analytics SDK"
  s.description      = "Clickstream is an event agnostic, real-time data ingestion analytics SDK"

  s.homepage         = 'https://github.com/gojek/clickstream-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  
  s.author           = "Gojek"
  s.source           = { :git => 'https://github.com/gojek/clickstream-ios.git', :tag => s.version.to_s }

  s.platform         = :ios
  s.ios.deployment_target = '11.0'
  s.swift_version    = '5.0'

  s.source_files  = 'Clickstream/**/*.swift'
  s.exclude_files = "Example"
  s.frameworks    = "UIKit", "Foundation", "CoreTelephony"
  
  s.dependency    "SwiftProtobuf", "1.10.2"
  s.dependency    "ReachabilitySwift"
  s.dependency    "GRDB.swift", "5.12.0"
  s.dependency    "Starscream", "4.0.4"

end
