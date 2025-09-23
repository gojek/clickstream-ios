import Foundation

struct WebsocketNetworkConfiguration: NetworkConfigurable {
    let request: URLRequest
    
    init(request: URLRequest) {
        self.request = request
    }
}

