//
//  ContentView.swift
//  previewableStatesAppExample
//
//  Created by amolonus on 06/08/2024.
//

import SwiftUI

struct Article: Identifiable {
    let id: UUID = UUID()
    let title: String
}

extension Article {
    static let testArticles: [Article] = [
        Article(title: "Apple Unveils New MacBook Pro with M3 Chip"),
        Article(title: "iOS 17 Release Date Announced by Apple"),
        Article(title: "Apple's Q3 2024 Earnings Exceed Expectations"),
        Article(title: "Apple Watch Series 9 Features Leaked"),
        Article(title: "Apple Expands Services with New Fitness+ Updates")
    ]
}

final class MainViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var articles: [Article] = []
    
    @MainActor
    func loadNews() async {
        isLoading = true
        try! await Task.sleep(for: .seconds(1.0))
        isLoading = false
        //Simulating return of the results
        articles = Article.testArticles
    }
}

struct MainView: View {
    @StateObject var viewModel: MainViewModel = .init()
    
    var body: some View {
        if viewModel.isLoading {
            ProgressView()
                .task {
                    await viewModel.loadNews()
                }
        } else {
            Text("News List")
        }
    }
}


#Preview {
    MainView()
        .previewDisplayName("OneStatePreview")
}

//Declaring all states for our view
enum NewsListState: CaseIterable {
    case data
    case loading
    case empty
    case error
    
    var title: String {
        switch self {
        case .data:
            "Data state"
        case .loading:
            "Loading progress state"
        case .empty:
            "No data available state."
        case .error:
            "Error fetching state"
        }
    }
}

protocol MainViewModelProtocol: ObservableObject {
    var newsState: NewsListState { get }
    var articles: [Article] { get }
    
    func loadNews() async
}

final class UIMainViewModel: MainViewModelProtocol {
    @Published private (set) var newsState: NewsListState = .empty
    @Published private (set) var articles: [Article] = []
    
    @MainActor
    func loadNews() async {
        //setting newslist state to loading data
        newsState = .loading
        do {
            //performing our async fetch request
            try await Task.sleep(for: .seconds(3.0))
            
            //if request was successfull, checking if our array of articles is not empty
            //and assigning state accordingly
            articles = Article.testArticles
            newsState = articles.isEmpty ? .empty : .data
        } catch {
            //in case of error during the fetch request, setting error state.
            newsState = .error
        }
    }
}

final class TestMainViewModel: MainViewModelProtocol {
    @Published private (set) var newsState: NewsListState
    @Published private (set) var articles: [Article] = []
    
    @MainActor
    func loadNews() async {
    }
    
    init(newsState: NewsListState) {
        self.newsState = newsState
        observeState()
    }
    
    //We observe our passed in preview state and assign our test data accordingly.
    private func observeState() {
        switch newsState {
        case .data:
            articles = Article.testArticles
        case .loading:
            articles = []
        case .empty:
            articles = []
        case .error:
            articles = []
        }
    }
}

struct NewsList<ViewModel: MainViewModelProtocol>: View {
    @StateObject var viewModel: ViewModel
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.newsState {
                case .data:
                    newsList
                case .loading:
                    ProgressView("Loading newsfeed")
                case .empty:
                    Text("No data available state")
                case .error:
                    Text("Error fetching data.")
                }
            }
            .navigationTitle("News Feed")
        }
        .task {
            await viewModel.loadNews()
        }
    }
    
    private var newsList: some View {
        List {
            ForEach(viewModel.articles) { article in
                Text(article.title)
            }
        }
    }
}

struct SecondNewsView: View {
    var body: some View {
        newsListView
    }
    
    @ViewBuilder
    private var newsListView: some View {
        let viewModel: UIMainViewModel = .init()
        NewsList(viewModel: viewModel)
    }
}



struct SecondNewsViewPreview: PreviewProvider {
    static var previews: some View {
        ForEach(NewsListState.allCases, id:\.self) { state in
            let viewModel: TestMainViewModel = .init(newsState: state)
                NewsList(viewModel: viewModel)
                .previewDisplayName(state.title)
        }
    }
}

