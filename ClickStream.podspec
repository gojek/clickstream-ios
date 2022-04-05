Pod::Spec.new do |s|

  s.name          = "ClickStream"
  s.version       = "1.1.44"
  s.summary       = "ClickStream Internal Library"
  s.description   = "Go-jek's Inhouse Analytics SDK"

  s.homepage      = "https://source.golabs.io/mobile/clickstream-ios-sdk"
  s.license       = "Internal to Go-jek, not allowed outside Go-jek"

  s.author        = "Go-jek"

  s.platform      = :ios
  s.platform      = :ios, "11.0"

  s.source        = { :http => "http://artifactory-gojek.golabs.io/artifactory/gojek-ios-pods/ClickStream/ClickStream_#{s.version}.tar.gz"}

  s.swift_version = '5.0'
  s.source_files  = "ClickStream/ClickStream/**/*.swift"
  s.exclude_files = "ClickStream/ClickStreamHost"
  s.frameworks    = "UIKit", "Foundation", "CoreTelephony"

  s.library       = 'resolv'
  s.dependency    "SwiftProtobuf", "1.10.2"
  s.dependency    "ReachabilitySwift"
  s.dependency    "GRDB.swift", "5.12.0"
end
