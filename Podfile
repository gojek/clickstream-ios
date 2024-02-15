# Uncomment the next line to define a global platform for your project

source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.0'
 use_modular_headers!

project 'Clickstream.xcodeproj'
workspace 'Clickstream.xcworkspace'

def clickstream_pods
  pod 'SwiftProtobuf', '~> 1.10'
  pod 'ReachabilitySwift', '~> 5.0'
  pod 'GRDB.swift', '~> 6.7'
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

target 'Example-ObjC' do
  project 'Example-ObjC/Example-ObjC.xcodeproj'
  pod 'Clickstream', :git => 'https://github.com/gojek/clickstream-ios.git', :branch => 'main'
  pod 'Protobuf', :git => 'https://github.com/protocolbuffers/protobuf.git'
end
