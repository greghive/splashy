
import Combine
import Foundation

final class SearchModel: ObservableObject {
    @Published var searchTerm = ""
    @Published var searchState = SearchState.idle
    @Published var selectedPhoto: Photo?
    @Published var favs: PhotoStore
    
    enum SearchState {
        case idle
        case success([Photo])
        case failure(String)
    }
    
    init(favs: PhotoStore) {
        self.favs = favs
        
        $searchTerm
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.global())
            .map(searchPhotos)
            .switchToLatest()
            .catch(handleError)
            .assign(to: &$searchState)
    }
    
    private func searchPhotos(string: String) -> AnyPublisher<SearchState, Error> {
        unsplash.call(.searchPhotos(query: string, perPage: 21))
            .map(\SearchResponse.results)
            .map { .success($0) }
            .eraseToAnyPublisher()
    }
    
    private func handleError(error: Error) -> AnyPublisher<SearchState, Never> {
        Just(.failure(error.message))
            .eraseToAnyPublisher()
    }
}

extension SearchModel.SearchState: Equatable {
    public static func == (lhs: SearchModel.SearchState, rhs: SearchModel.SearchState) ->Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case let (.success(a), .success(b)):
            return a == b
        case let (.failure(a), .failure(b)):
            return a == b
        default:
            return false
        }
    }
}
