# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'
# use_modular_headers!

source 'https://cdn.cocoapods.org/'

project 'Clickstream.xcodeproj'
workspace 'Clickstream.xcworkspace'

def clickstream_pods
  pod 'Starscream', '~> 4.0.4'
  pod 'SwiftProtobuf', '~> 1.10.2'
  pod 'ReachabilitySwift'
  pod 'GRDB.swift', '5.12.0'
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
