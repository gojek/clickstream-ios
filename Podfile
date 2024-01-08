# Uncomment the next line to define a global platform for your project

source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.0'
 use_modular_headers!

project 'ClickstreamLib.xcodeproj'
workspace 'ClickstreamLib.xcworkspace'

def clickstream_pods
  pod 'SwiftProtobuf', '~> 1.10'
  pod 'ReachabilitySwift', '~> 5.0'
  pod 'GRDB.swift', '~> 6.7'
end

target 'ClickstreamLib' do
   clickstream_pods
end

target 'ClickstreamTests' do
  clickstream_pods
end

target 'Example' do
  project 'Example/Example.xcodeproj'
  clickstream_pods
end
