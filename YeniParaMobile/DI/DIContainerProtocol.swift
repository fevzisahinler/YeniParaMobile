import Foundation

// MARK: - DI Container Protocol
protocol DIContainerProtocol {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T?
}

// MARK: - Simple DI Container Implementation
final class DIContainer: DIContainerProtocol {
    static let shared = DIContainer()
    
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    
    private init() {}
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        // Check if we have a cached instance
        if let service = services[key] as? T {
            return service
        }
        
        // Check if we have a factory
        if let factory = factories[key], let service = factory() as? T {
            services[key] = service
            return service
        }
        
        return nil
    }
    
    func clearCache() {
        services.removeAll()
    }
}
