import Foundation
import Network
import Combine

/// Monitors network connectivity and provides real-time updates
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected: Bool = false
    @Published var connectionType: ConnectionType = .none
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case none
    }
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(from: path) ?? .none
            }
        }
        monitor.start(queue: queue)
        
        // Set initial state
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let currentPath = self.monitor.currentPath
            self.isConnected = currentPath.status == .satisfied
            self.connectionType = self.getConnectionType(from: currentPath)
        }
    }
    
    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .none
        }
    }
    
    deinit {
        monitor.cancel()
    }
}

