//
//  NetworkModel.swift
//  WhereNow
//
//  Created by Jonathan Lavallee Collins on 4/22/25.
//

import Network

class NetworkModel {
    
    static let shared = NetworkModel()
    
    private let monitor = NWPathMonitor()
    private var connected = true
    
    init() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.connected = true
            } else {
                self.connected = false
            }
        }
        
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
    
    /// Retrieves the current network state.
    ///
    /// - Returns: A boolean value indicating the network state (connected or not).
    func getNetworkState() -> Bool {
        return connected
    }
}
