
# Clickstream Health Tracking!

This is an additional feature of Clickstream SDK, which let us monitor the SDK's health i.e.

 1. **Drop rate of events:-** Number of events send by client app vs number of events successfully sent by SDK to backend. For example if 1000 events send by client app and 999 events are sent by Clickstream SDK to backend, then the drop rate is 0.1%.
 2. **Socket & connection error:-** We also track various other errors happening in the SDK like socket not connected, unable to send events due to low battery or network unavailable or Parsing exceptions thrown by backend.


## Cocoapods

To integrate Clickstream health tracker into your project specify the following in Podfile

    pod 'Clickstream/Tracker'

## Usage

### Initialization
Once intialized the tracker will start moniotiring the socket connections and funnel events in Clickstream, no explicit action or trigger needs to be done from client side.

    let customerInfo = CSCustomerInfo(signedUpCountry: "India", email: "test@test.com", currentCountry: "91", identity: 105)
    let sessionInfo = CSSessionInfo(sessionId: "1001")
    let appInfo = CSAppInfo(version: "1.0")
    let commonProperties = CSCommonProperties(customer: customerInfo, session: sessionInfo, app: appInfo)
    let configs = ClickstreamHealthConfigurations(minimumTrackedVersion: "0.1", trackedVia: .internal)
            
    self.clickstream?.setTracker(configs: configs, commonProperties: commonProperties, dataSource: self)

### ClickstreamHealthConfigurations

Holds the configurations for health tracking, these onfigurations helps in having more control on the behaviour of Tracker.
|Variable|Description|Type|Default Value|
|--|--|-- |--|
| minimumTrackedVersion |Track CS SDK health from minimum app version |String|-|
| randomisingUserIdRemainders |Enable tracking for userId with following randomising remainder |[Int32]|[]|
| trackedVia |Enable tracking via internal, external or both |TrackedVia|-|
| verbosityLevel |Various verbosity levels |VerbosityLevel| VerbosityLevel.minimum|



### CSCommonProperties

Container for all the common properties like customer, session and app to be added to every health event being sent from Clickstream. This need not be set every time, set once and the SDK will attach it to every event being sent to `ClickStream` for tracking.
|Variable|Description| Type|
|--|--|--|
|customer| Holds the customer info (`CSCustomerInfo`)  for a given app session. Needs to be supplied by the client. |CSCustomerInfo|
|session| Holds the session info (`CSSessionInfo`)  for a given app session. Needs to be supplied by the client. |CSSessionInfo|
|device| Holds the device info (`CSDeviceInfo`)  for a given app session. Does not need to be supplied by the client. |CSDeviceInfo|
|app| Holds the app info (`CSAppInfo`)  for a given app session. Needs to be supplied by the client. |CSAppInfo|

### Events
| Name | Purpose | Flushed| Priority|Verbosity:Maximum | Verbosity:Minimum|
|--|--|--| --|--|--|
| **Clickstream Event Received For Drop Rate** | This event is track the drop rate comparison only and not the part of the funnel. Would be triggered for the event which is used to track the drops Eg. `CardEvent` |Aggregated|critical| `event_name`, `event_guid`|`event_name`, `event_guid`|
| **Clickstream Event Received** | Tracks the instances where the event is received by the Clickstream library |Aggregated|critical| `event_name`, `event_guid`|`event_name`, `event_guid`|
| **Clickstream Event Cached** | Tracks the instances when the clickstream event object is cached.|Aggregated|low| `event_name`, `event_guid`|`event_name`, `event_guid`|
| **Clickstream Event Batch Trigger Failed** | Tracks the instances when the batch fails to get triggered. |Instant|critical| `failure_reason`|`failure_reason`|
| **Clickstream Event Batch Created** | Tracks the instances when the clickstream event batch is created.|Aggregated|low| `event_name`, `[event_guid]`, `event_batch_guid`|`event_name`, `event_batch_guid`, `[event_guid].count`|
| **ClickStream Write to Socket Failed** | Tracks the instances when the clickstream event batch fails to get written on the socket. |Instant|critical| `event_name`, `failure_reason`, `event_batch_guid`|`event_name`, `failure_reason`|
| **ClickStream Batch Sent**| Tracks the instances when the clickstream batch gets successfully sent to raccoon. |Aggregated|critical| `event_name`, `event_guid`|`event_name`, `event_guid`|
|**Clickstream Event Batch Success Ack** | Tracks the instances when raccoon acks the event request|Aggregated|low| `event_name`, `event_batch_guid`|`event_name`, `event_batch_guid`|
| **Clickstream Event Batch Error response** | Tracks the instances when the clickstream request results in a error response|Instant|critical| `event_name`, `event_batch_guid`|`event_name`, `event_batch_guid`|
| **Clickstream Event Batch Timeout** | Tracks the instances when the clickstream event batch gets timed out|Instant|critical| `event_name`, `event_batch_guid`|`event_name`, `event_batch_guid`|
| **ClickStream Flush On Background** | Tracks the instances when the clickstream batches are flushed on background|Aggregated|critical| `event_name`, `[event_guid]`|`event_name`, `[event_guid].count`|
| **Clickstream Connection Success** | Tracks the connection attempt success instances|Instant|critical| `event_name`, `time_to_connection`|`event_name`, `time_to_connection`|
| **Clickstream Connection Failure** | Tracks the connection attempt failure instances|Instant|critical| `event_name`, `time_to_connection`, `failure_reason`|`event_name`, `failure_reason`|
| **Clickstream Connection Dropped**| Tracks the instances where the connection gets dropped|Instant|critical| `event_name`, `failure_reason`|`event_name`, `failure_reason`|


## Proto Structure
   
   **Health.proto**
	
	message HealthDetails {
      // Array of event guids.
      repeated string event_guids = 1;
      // Array of event batch guids.
      repeated string event_batch_guids = 2;
    }
    
    message ErrorDetails {
      string reason = 1;
    }
    
    message TraceDetails {
      string time_to_connection = 1;
      ErrorDetails error_details = 2;
    }
    
    message Health {
    
      // Name of the health event.
      string event_name = 1;
      // Health details, captured by the SDK when the mode is verbose.
      HealthDetails healthDetails = 2;
      // Number of events tracked.
      int64 number_of_events = 3;
      // Number of event batches tracked.
      int64 number_of_batches = 4;
      // Tracks the error details for the event
      ErrorDetails error_details = 5;
      // Tracks the traces
      TraceDetails trace_details = 6;
    
      // Note: Auto-filled by the ClickStream SDK, need not be set by the products for every event! If set, will be overridden.
      google.protobuf.Timestamp event_timestamp = 101;
      // Note: Auto-filled by the ClickStream SDK, need not be set by the products for every event! If set, will be overridden.
      // Deprecated, please use healthEventMeta.
      gojek.clickstream.common.EventMeta meta = 102 [deprecated = true];
      // Tracks Clickstream health meta. 
      gojek.clickstream.internal.HealthMeta healthMeta = 103;
      // Note: Auto-filled by the ClickStream SDK, need not be set by the products for every event! If set, will be overridden.
      google.protobuf.Timestamp device_timestamp = 104;
    }

**HealthMeta.proto**

    message HealthMeta {
    
      message App {
        string version = 1;
      }
    
      message Customer {
        string signed_up_country = 1;
        string current_country = 2;
        int32 identity = 3;
        string email = 4;
      }
    
      message Device {
        string operating_system = 1;
        string operating_system_version = 2;
        string device_make = 3;
        string device_model = 4;
      }
    
      message Location {
        double latitude = 1;
        double longitude = 2;
      }
    
      message Session {
        string session_id = 1;
      }
    
      enum NetworkType {
        NETWORK_TYPE_UNSPECIFIED = 0;
        NETWORK_TYPE_NO_CONNECTION = 1;
        NETWORK_TYPE_WIFI = 2;
        NETWORK_TYPE_WWAN2G = 3;
        NETWORK_TYPE_WWAN3G = 4;
        NETWORK_TYPE_WWAN4G = 5;
      }
    
      message Network {
        NetworkType type = 1;
      }
    
      string event_guid = 1;
    
      Location location = 4;
      Customer customer = 5;
      Device device = 6;
      Session session = 7;
      App app = 8;
      Network network = 9;
    }
