//
//  SearchPage.swift
//  MovieSeriesDiary
//
//  Created by Emir Gökalp on 25.04.2025.
//

import SwiftUI

struct SearchPage: View {
    @ObservedObject var vM: BindingPageViewModel
    @State private var text = ""
    
    var filteredMovies: [Movie] {
        vM.moviesList.filter {
            $0.name.localizedCaseInsensitiveContains(text) ||
            $0.director.localizedCaseInsensitiveContains(text) ||
            $0.actors.localizedCaseInsensitiveContains(text)
        }
    }
    
    var filteredSeries: [Series] {
        vM.seriesList.filter {
            $0.name.localizedCaseInsensitiveContains(text) ||
            $0.director.localizedCaseInsensitiveContains(text) ||
            $0.actors.localizedCaseInsensitiveContains(text)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    if !text.isEmpty {
                        if !filteredMovies.isEmpty || !filteredSeries.isEmpty {
                            VStack(alignment: .leading, spacing: 20) {
                                if !filteredMovies.isEmpty { // MOVIES PART OF SEARCH
                                    Text("Movies")
                                        .font(.system(size: 35, weight: .bold))
                                        .padding(.horizontal)
                                        .padding(.top)
                                    
                                    LazyVStack {
                                        ForEach(filteredMovies, id: \.id) { movie in
                                            if let index = vM.moviesList.firstIndex(where: { $0.id == movie.id }) {
                                                NavigationLink(destination: EntityPage(vM: vM, movie: vM.moviesList[index], comments: $vM.moviesList[index].comments)) {
                                                    vM.entityRow(
                                                        name: movie.name,
                                                        releaseYear: movie.releaseYear,
                                                        runtime: movie.runtime,
                                                        category: movie.category,
                                                        imdb: movie.imdb,
                                                        posterURL: movie.posterURL
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                if !filteredSeries.isEmpty { // SERIES PART OF SEARCH
                                    Text("Series")
                                        .font(.system(size: 35, weight: .bold))
                                        .padding(.horizontal)
                                        .padding(.top)
                                    
                                    LazyVStack {
                                        ForEach(filteredSeries, id: \.id) { series in
                                            if let index = vM.seriesList.firstIndex(where: { $0.id == series.id }) {
                                                NavigationLink(destination: EntityPage(vM: vM, series: vM.seriesList[index], comments: $vM.seriesList[index].comments)) {
                                                    vM.entityRow(
                                                        name: series.name,
                                                        releaseYear: series.releaseYear,
                                                        lastReleaseYear: series.lastReleaseYear,
                                                        seasons: series.seasons,
                                                        category: series.category,
                                                        imdb: series.imdb,
                                                        posterURL: series.posterURL
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } else { // NO MATCHES FOUND
                            Color.clear
                                .frame(height: UIScreen.main.bounds.height * 0.3)
                            HStack {
                                Spacer()
                                VStack {
                                    Image("logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100)
                                    
                                    Text("No matches found.")
                                        .font(.system(size: 23, weight: .bold))
                                        .multilineTextAlignment(.center)
                                }
                                Spacer()
                            }
                        }
                    } else { // PLACEHOLDER LOGO
                        Color.clear
                            .frame(height: UIScreen.main.bounds.height * 0.2)
                        HStack {
                            Spacer()
                            VStack {
                                Image("logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100)
                                
                                Text("Search your favorite by\nname, director, actors")
                                    .font(.system(size: 20, weight: .semibold))
                                    .multilineTextAlignment(.center)
                            }
                            Spacer()
                        }
                    }
                }
                .searchable(text: $text)
                .background(Color.back)
         
                Color.primary.opacity(0.75)
                    .frame(height: 0.5)
            }
        }
    }
}

#Preview {
    SearchPage(vM: BindingPageViewModel())
}
