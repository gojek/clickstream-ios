
<p align="center">
<img src="https://github.com/gojek/clickstream-ios/blob/main/Resources/clickstream-horizontal-black.svg#gh-light-mode-only" width="500"/>
</p>

<p align="center">
<img src="https://github.com/gojek/clickstream-ios/blob/main/Resources/clickstream-horizontal-white.svg#gh-dark-mode-only" width="500"/>
</p>

# Welcome to Clickstream!

Clickstream is an event agnostic, real-time data ingestion platform. Clickstream allows apps to maintain a long-running connection to send data in real-time.

The word “Clickstream” is a trail of digital breadcrumbs left by users as they click their way through a website or mobile app. It is loaded with valuable customer information for businesses and its analysis and usage has emerged as a powerful data source.

**To know more about Clickstream, you can read our [Medium post](https://www.gojek.io/blog/introducing-clickstream?utm_source=blog&utm_medium=medium%20blog&utm_campaign=blog_clickstream)**

**Clickstream provide end to end solution for ingestion platform purposes. For setup the infrastructure please check [raccoon](https://odpf.gitbook.io/raccoon/)**


## Architecture

![Clickstream Architecture](https://github.com/gojekfarm/clickstream-ios/blob/main/Resources/clickstream-architecture.png)

#### Mobile Library Architecture

![Clickstream HLD](https://github.com/gojekfarm/clickstream-ios/blob/main/Resources/clickstream-HLD.png)


## Key features

-   Simple and lightweight
    
-   Remotely Configurable
    
-   Support for real-time data
    
-   Multiple QoS support (QoS0 and QoS1)
    
-   Typesafe and reusable schemas
    
-   Efficient payloads
    
-   In-built data aggregation

## Installation

#### CocoaPods
[CocoaPods](https://cocoapods.org/) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate Clickstream into your Xcode project using CocoaPods, specify it in your Podfile:

    pod 'Clickstream'

## Usage

### Initialization

        class SampleClass {
        
    	    private var clickstream: ClickStream?
    	    
    	    func initialiseClickstream() {
			    let url = URL(string: "ws://mock.clickstream.com/events")!
			    let headers = ["Authorization": "Bearer dummy-token"]
			    let networkConfigs = NetworkConfigurations(baseURL: url, headers: headers)
			    let constraints = ClickstreamConstraints(maxConnectionRetries: 5)
			    let classification = ClickstreamEventClassification()
			    self.clickstream = try? Clickstream.initialise(networkConfiguration: networkConfigs,
			    constraints: constraints,
			    eventClassification: classification)
		    }
	    }
	    
#### ClickstreamConstraints

Holds the configurations for clickstream. These constraints allow for fine-grained control over the library behaviour like duration between retries, flush events when app goes in background, etc.

|  Description|  Variable|	Type|	Default value|
|--|--|--|--|
|  Maximum number of retries for connection| maxConnectionRetries |	Int|30|
|  Maximum retry interval between two successive retries (seconds)| maxConnectionRetries |	Int|30|
|  Maximum number of retries for connection| maxConnectionRetryInterval |	TimeInterval|30|
| Maximum retry interval post a premature network disconnection (seconds) | maxRetryIntervalPostPrematureDisconnection |TimeInterval|30|
| Maximum number of retries post a premature network disconnection | maxRetriesPostPrematureDisconnection |Int	|10|
| Max Pint Interval (seconds) | maxPingInterval |TimeInterval	|15|
|This array holds all priority configs| priorities |[Priority]	|[Priority()]|
|This is flag which determines whether the contained events be flushed when the app moves to background|	flushOnBackground|Boolean|false
|Wait time for the connection termination|connectionTerminationTimerWaitTime|	TimeInterval|8|
|  Max retry interval for timimg out a batch| maxRequestAckTimeout |TimeInterval	|6|
|  Max retires allowed batch|  maxRetriesPerBatch|Int	|20|
|  Max retry cache size on disk and memory (bytes)|  maxRetryCacheSize|	Bytes|5000000|
|  Connection retry duration|  connectionRetryDuration|	TimeInterval|3|
    
	
##### Priority
Holds the priorities defined in the ClickStreamConstraints

|  Description|  Variable|	Type|	Default value|
|--|--|--|--|
|  QoS| priority |	Int|0|
|  Identifier (Example: "realTime" / "standard")| identifier |	String|"realTime"|
|   Maximum batch size for this priority (in bytes)| maxBatchSize |	Bytes|50000|
|  Maximum time duration between two batches (in seconds)| maxTimeBetweenTwoBatches |	TimeInterval|10|
|  Maximum cache size for this priority (in bytes)| maxCacheSize |	Bytes|5000000|



#### ClickStreamEventClassification
Holds the Event classification for ClickStream.
|  Description|  Variable|	Type|	Default value|
|--|--|--|--|
|  Holds all the eventTypes| eventTypes |	EventClassifier|[EventClassifier(identifier: "realTime", eventNames: []), EventClassifier(identifier: "instant", eventNames: [])]|



### Push Event
Pushes event to Clickstream SDK

    private func trackClickstreamEvent(message: Message) {
	    self.clickStream?.trackEvent(with: message)
    }
    
### Destroy Instance
Destroy instance of Clickstream, for example can be called when user logs out of the app.

    ClickStream.destroy()

## Contribute


Development of Clickstream happens in the open on GitHub, and we are grateful to the community for contributing bug fixes and improvements. Read below to learn how you can take part in improving Clickstream.

Read our [CONTRIBUTING-GUIDE.md](https://github.com/gojekfarm/clickstream-ios/blob/main/CONTRIBUTING-GUIDE.md) to learn about our development process, how to propose bug fixes and improvements, and how to build and test your changes to Clickstream.

## Credits

This project exists thanks to all the contributors.

## License

    MIT License
    
    Copyright (c) 2022 GO-JEK Tech
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

