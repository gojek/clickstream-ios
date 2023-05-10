# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'
 use_modular_headers!

source 'https://cdn.cocoapods.org/'

project 'Clickstream.xcodeproj'
workspace 'Clickstream.xcworkspace'

def clickstream_pods
  pod 'SwiftProtobuf', '~> 1.10'
  pod 'ReachabilitySwift', '~> 5.0'
  pod 'GRDB.swift', '~> 5.12'
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
