//
//  ProfilePage.swift
//  MovieSeriesDiary
//
//  Created by Emir Gökalp on 25.04.2025.
//

import SwiftUI
import FirebaseAuth

struct ProfilePage: View {
    @ObservedObject var vM: BindingPageViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 0){
                VStack {
                    HStack {
                        Spacer()
                        vM.seriesOrMovies()
                        Spacer()
                    }
                    .padding(.bottom, 5)
                    
                    Color.reversePrimary.opacity(0.75)
                        .frame(height: 1)
                }
                .background(Color.back.opacity(0.65))

                TabView(selection: $vM.selectedType) {
                    
                    page(type: 0)
                        .tag(0)
                    
                    page(type: 1)
                        .tag(1)
                    
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(vM.user?.id ?? "")
                            .font(.system(size: 17, weight: .bold))
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            do {
                                try Auth.auth().signOut()
                                vM.user = nil
                            } catch {
                                print("Error signing out: \(error.localizedDescription)")
                            }
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                        }
                    }
                }
                Color.primary.opacity(0.75)
                    .frame(height: 0.5)
            }
        }
    }
    
    func page(type: Int) -> some View {
        ScrollView {
            if let user = vM.user {
                VStack(spacing: 20) {
                    sectionView(title: "Watch Later", items: user.watchLaters, type: type)
                    sectionView(title: "You Watched", items: user.alreadyWatcheds, type: type)
                    sectionView(title: "You Rated", items: user.ratings.map { $0.entityName }, type: type)
                    sectionView(title: "Your Commented", items: user.comments.map { $0.entityName }, type: type)
                }
                .padding()
            }
        }
        .background(Color.back)
    }
    

     
    @ViewBuilder
    func sectionView(title: String, items: [String], type: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 25, weight: .bold))
                Spacer()
            }
            .padding(.bottom, 5)
            
            if type == 0 { // series
                let filteredSeries = vM.seriesList.filter { series in
                    items.contains(series.id) || items.contains(series.name)
                }
                
                if filteredSeries.isEmpty {
                    Text("No items.")
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(filteredSeries, id: \.id) { series in
                                NavigationLink {
                                    if let index = vM.seriesList.firstIndex(where: { $0.id == series.id }) {
                                        EntityPage(vM: vM, series: series.clone(), comments: $vM.seriesList[index].comments)
                                    }
                                } label: {
                                    card(url: series.posterURL)
                                }
                            }
                        }
                    }
                }
            } else { // movies
                let filteredMovies = vM.moviesList.filter { movie in
                    items.contains(movie.id) || items.contains(movie.name)
                }
                
                if filteredMovies.isEmpty {
                    Text("No items.")
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(filteredMovies, id: \.id) { movie in
                                NavigationLink {
                                    if let index = vM.moviesList.firstIndex(where: { $0.id == movie.id }) {
                                        EntityPage(vM: vM, movie: movie.clone(), comments: $vM.moviesList[index].comments)
                                    }
                                } label: {
                                    card(url: movie.posterURL)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(10)
    }
    
    func card(url: String) -> some View {
        if let url = URL(string: url) {
            return AnyView(
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 130)
                            .clipped()
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)

                    case .failure(_), .empty:
                        fallbackImage
                    @unknown default:
                        fallbackImage
                    }
                }
            )
        } else {
            return AnyView(fallbackImage)
        }
    }

    private var fallbackImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 130)
            
            Image(systemName: "photo")
                .foregroundColor(.gray)
                .font(.system(size: 30))
        }
    }


}

#Preview {
    var user = User(id: "tester", email: "tester@tester.com", watchLaters: [], alreadyWatcheds: [], ratings: [], comments: [])
    ProfilePage(vM: BindingPageViewModel(user: user))
}
