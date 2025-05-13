//
//  ContentView.swift
//  MovieSeriesDiary
//
//  Created by Emir Gökalp on 12.04.2025.
//

import SwiftUI
import SwiftSoup
import FirebaseFirestore

struct MainPage: View {
    @ObservedObject var vM: BindingPageViewModel
    
    @State var sortTableOpened = false
    @State var filterTableOpened = false
    
    @State var filterCategory = "Any"
    
    @State var filteredSeries: [Series]
    @State var filteredMovies: [Movie]
    
    init(vM: BindingPageViewModel) {
        self.vM = vM
        self.filteredSeries = vM.seriesList
        self.filteredMovies = vM.moviesList
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    VStack {
                        ZStack {
                            vM.seriesOrMovies()
                            
                            HStack {
                                filterButton()
                                Spacer()
                                sortByButton()
                            }
                        }
                        .padding(.bottom, 5)
                        
                        Color("reversePrimary").opacity(0.75)
                            .frame(height: 1)
                    }
                    .background(Color.back.opacity(0.65))
                    
                    TabView(selection: $vM.selectedType) {
                        ZStack(alignment: .top) {
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                                    ForEach(filteredSeries, id: \.self) { series in
                                        if let index = filteredSeries.firstIndex(where: { $0.id == series.id }) {
                                            NavigationLink(destination: EntityPage(vM: vM, series: filteredSeries[index], comments: $filteredSeries[index].comments)) {
                                                EntityItem(vM: vM, series: series)
                                                    .padding(.vertical, 5)
                                            }
                                        }
                                    }
                                }
                                .padding(.top)
                            }
                        }
                        .tag(0)
                        
                        ZStack(alignment: .top) {
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                                    ForEach(filteredMovies, id:\.self) { movie in
                                        if let index = filteredMovies.firstIndex(where: { $0.id == movie.id }) {
                                            NavigationLink(destination: EntityPage(vM: vM, movie: filteredMovies[index], comments: $filteredMovies[index].comments)) {
                                                EntityItem(vM: vM, movie: movie)
                                                    .padding(.vertical, 5)
                                            }
                                        }
                                    }
                                }
                                .padding(.top)
                            }
                        }
                        .tag(1)
                    }
                    .background(Color.back)
                    .onDisappear() {
                        filterTableOpened = false
                        sortTableOpened = false
                    }

                    Color.primary.opacity(0.75)
                        .frame(height: 0.5)
                }
                .navigationBarTitleDisplayMode(.inline)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                VStack {
                    HStack {
                        if filterTableOpened {
                            filterTable()
                                .padding(.leading)
                                .offset(y: 35)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                        
                        Spacer()
                        
                        if sortTableOpened {
                            sortTable()
                                .padding(.trailing)
                                .offset(y: 35)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    Spacer()
                }
            }
            .onChange(of: vM.selectedType) {
                filterCategory = "Any"
                filteredSeries = vM.seriesList
                filteredMovies = vM.moviesList
                withAnimation(.bouncy) {
                    sortTableOpened = false
                    filterTableOpened = false
                }
            }
        }
    }
    
    func sortTable() -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    if (vM.selectedType == 0 && option != .runtimeLow && option != .runtimeHigh) ||
                        (vM.selectedType != 0 && option != .lastReleaseOld && option != .lastReleaseNew && option != .seasonLow && option != .seasonHigh) {
                        
                        changeButton(text: option.rawValue, action: {
                            switch option {
                            case .imdbLow:
                                if vM.selectedType == 0 {
                                    filteredSeries.sort { $0.imdb < $1.imdb }
                                } else {
                                    filteredMovies.sort { $0.imdb < $1.imdb }
                                }
                            case .imdbHigh:
                                if vM.selectedType == 0 {
                                    filteredSeries.sort { $0.imdb > $1.imdb }
                                } else {
                                    filteredMovies.sort { $0.imdb > $1.imdb }
                                }
                            case .releaseOld:
                                if vM.selectedType == 0 {
                                    filteredSeries.sort { $0.releaseYear < $1.releaseYear }
                                } else {
                                    filteredMovies.sort { $0.releaseYear < $1.releaseYear }
                                }
                            case .releaseNew:
                                if vM.selectedType == 0 {
                                    filteredSeries.sort { $0.releaseYear > $1.releaseYear }
                                } else {
                                    filteredMovies.sort { $0.releaseYear > $1.releaseYear }
                                }
                            case .lastReleaseOld:
                                filteredSeries.sort { $0.lastReleaseYear < $1.lastReleaseYear }
                            case .lastReleaseNew:
                                filteredSeries.sort { $0.lastReleaseYear > $1.lastReleaseYear }
                            case .seasonLow:
                                filteredSeries.sort { $0.seasons < $1.seasons }
                            case .seasonHigh:
                                filteredSeries.sort { $0.seasons > $1.seasons }
                            case .runtimeLow:
                                filteredMovies.sort { $0.runtime < $1.runtime }
                            case .runtimeHigh:
                                filteredMovies.sort { $0.runtime > $1.runtime }
                            }
                        })
                    }
                }
            }
        }
        .background(Color(.systemGray5).opacity(0.75))
        .cornerRadius(5)
        .frame(maxHeight: 190)
        .padding(.top, 8)
    }
    
    func filterTable() -> some View {
        let categories: [String] = ["Any"] + (vM.selectedType == 0
                                              ? Array(Set(vM.seriesList.map { $0.category })).sorted()
                                              : Array(Set(vM.moviesList.map { $0.category })).sorted()
        )

        return ScrollView {
            VStack(spacing: 0) {
                ForEach(categories, id: \.self) { category in
                    changeButton(text: category, action: {
                        filterCategory = category
                        if vM.selectedType == 0 {
                            if category == "Any" {
                                filteredSeries = vM.seriesList
                            } else {
                                filteredSeries = vM.seriesList.filter({$0.category == category})
                            }
                        } else {
                            if category == "Any" {
                                filteredMovies = vM.moviesList
                            } else {
                                filteredMovies = vM.moviesList.filter({$0.category == category})
                            }
                        }
                    })
                }
            }
        }
        .background(Color(.systemGray5).opacity(0.75))
        .cornerRadius(5)
        .frame(maxHeight: 190)
        .padding(.top, 8)
    }

    
    func changeButton(text: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.bouncy) {
                sortTableOpened = false
                filterTableOpened = false
            }
            withAnimation(.easeInOut(duration: 0.25)) {
                action()
            }
        } label: {
            HStack {
                Text(text)
                    .font(.system(size: 18, weight: filterCategory == text ? .light : .semibold))
                    .padding(.leading, 10)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                
                if filterCategory == text {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.trailing)
                }
            }
            .foregroundStyle(filterCategory == text ? .text.opacity(0.5) : .text)
            .frame(width: 185)
            .padding(.vertical, 13)
            .background(Color(.systemGray3))
            .cornerRadius(5)
            .padding(.vertical, 3)
        }
    }
    
    func sortByButton() -> some View {
        Button {
            withAnimation(.bouncy) {
                sortTableOpened.toggle()
                filterTableOpened = false
            }
        } label: {
            HStack(spacing: 5) {
                Text("Sort By")
                Image(systemName: "chevron.down")
                    .rotationEffect(sortTableOpened ? Angle(degrees: -90) : Angle(degrees: 0))
            }
        }
        .frame(height: 35)
        .padding(.horizontal, UIScreen.main.bounds.width * 0.02)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .foregroundStyle(.gray)
        .padding(.trailing)
    }
    
    func filterButton() -> some View {
        Button {
            withAnimation(.bouncy) {
                filterTableOpened.toggle()
                sortTableOpened = false
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "chevron.down")
                    .rotationEffect(filterTableOpened ? Angle(degrees: 90) : Angle(degrees: 0))
                Text(filterCategory == "Any" ? "Category" : filterCategory)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.23, maxHeight: 35)
        .padding(.horizontal, UIScreen.main.bounds.width * 0.015)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .foregroundStyle(.gray)
        .padding(.leading)
    }
}


#Preview {
    MainPage(vM: BindingPageViewModel(seriesList: [Series(id: "", name: "r3", releaseYear: 0, lastReleaseYear: 0, seasons: 0, category: "", director: "", actors: "", description: "", country: "", awards: "", posterURL: "", imdb: 0, imdbCount: "", comments: [], ratings: [])]))
}


enum SortOption: String, CaseIterable {
    case imdbLow = "IMDb: Lowest"
    case imdbHigh = "IMDb: Highest"
    case releaseOld = "Release: Oldest"
    case releaseNew = "Release: Newest"
    case lastReleaseOld = "Last Release: Oldest"
    case lastReleaseNew = "Last Release: Newest"
    case seasonLow = "Seasons: Fewest"
    case seasonHigh = "Seasons: Most"
    case runtimeLow = "Runtime: Shortest"
    case runtimeHigh = "Runtime: Longest"
}
