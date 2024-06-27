# Uncomment the next line to define a global platform for your project

source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '12.0'
 use_modular_headers!

project 'Clickstream.xcodeproj'
workspace 'Clickstream.xcworkspace'

def clickstream_pods
  pod 'SwiftProtobuf', '~> 1.21.0'
  pod 'ReachabilitySwift', '5.2.3'
  pod 'GRDB.swift', '~> 6.7.0'
  pod 'Starscream', '4.0.5'
end

target 'Clickstream' do
   clickstream_pods
end

target 'ClickstreamTests' do
  clickstream_pods
end

target 'Example' do
  project 'Example/Example.xcodeproj'
  clickstream_pods
end
