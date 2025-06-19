import Foundation
import Combine

// MARK: - Base Repository Protocol
protocol RepositoryProtocol {
    associatedtype Entity
    
    func getAll() async throws -> [Entity]
    func get(id: String) async throws -> Entity?
    func create(_ entity: Entity) async throws -> Entity
    func update(_ entity: Entity) async throws -> Entity
    func delete(id: String) async throws
    func search(query: String) async throws -> [Entity]
}

// MARK: - Local Repository Protocol
protocol LocalRepositoryProtocol: RepositoryProtocol {
    func save(_ entity: Entity, key: String) async
    func load(key: String) async -> Entity?
    func remove(key: String) async
    func clearAll() async
}

// MARK: - Remote Repository Protocol
protocol RemoteRepositoryProtocol: RepositoryProtocol {
    var apiClient: APIClient { get }
    func sync() async throws
}

// MARK: - Cacheable Repository Protocol
protocol CacheableRepositoryProtocol {
    associatedtype Entity
    
    var cacheManager: CacheManager { get }
    var cacheExpiry: TimeInterval { get }
    
    func getCached(key: String) async -> Entity?
    func setCached(_ entity: Entity, key: String) async
    func invalidateCache(key: String) async
}

// MARK: - Observable Repository Protocol
protocol ObservableRepositoryProtocol {
    associatedtype Entity
    
    var publisher: AnyPublisher<[Entity], Never> { get }
    var errorPublisher: AnyPublisher<Error?, Never> { get }
}

// MARK: - Base Repository Implementation
class BaseRepository<T: Codable>: ObservableRepositoryProtocol {
    typealias Entity = T
    
    // Publishers
    let itemsSubject = CurrentValueSubject<[T], Never>([])
    let errorSubject = CurrentValueSubject<Error?, Never>(nil)
    
    var publisher: AnyPublisher<[T], Never> {
        itemsSubject.eraseToAnyPublisher()
    }
    
    var errorPublisher: AnyPublisher<Error?, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // Protected methods for subclasses
    func notifyUpdate(_ items: [T]) {
        itemsSubject.send(items)
    }
    
    func notifyError(_ error: Error) {
        errorSubject.send(error)
    }
    
    func clearError() {
        errorSubject.send(nil)
    }
}

// MARK: - Repository Error
enum RepositoryError: LocalizedError {
    case notFound
    case createFailed
    case updateFailed
    case deleteFailed
    case syncFailed
    case invalidData
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Veri bulunamadı"
        case .createFailed:
            return "Oluşturma başarısız"
        case .updateFailed:
            return "Güncelleme başarısız"
        case .deleteFailed:
            return "Silme başarısız"
        case .syncFailed:
            return "Senkronizasyon başarısız"
        case .invalidData:
            return "Geçersiz veri"
        case .unauthorized:
            return "Yetkilendirme hatası"
        }
    }
}
