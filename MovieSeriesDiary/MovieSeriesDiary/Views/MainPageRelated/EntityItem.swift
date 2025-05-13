//
//  EntityItem.swift
//  MovieSeriesDiary
//
//  Created by Emir Gökalp on 6.05.2025.
//

import SwiftUI

struct EntityItem: View {
    @ObservedObject var vM: BindingPageViewModel
    let series: Series?
    let movie: Movie?
    let width: CGFloat = UIScreen.main.bounds.width * 0.45
    var height: CGFloat {
        width * 1.5
    }

    init(vM: BindingPageViewModel, series: Series? = nil, movie: Movie? = nil) {
        self.vM = vM
        self.series = series
        self.movie = movie
    }
    
    var body: some View {
        ZStack {
            if let posterURL = series?.posterURL ?? movie?.posterURL,
               let url = URL(string: posterURL) {
                AsyncImage(url: url) { image in
                    ZStack {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: height)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(spacing: 0) {
                            Color.black.opacity(0.6)
                                .frame(height: 30)
                            
                            LinearGradient(
                                gradient: Gradient(colors: [.black.opacity(0.6), .clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 30)
                            
                            Spacer()
                        }
                        
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                            .frame(width: width, height: height)
                            .shadow(color: .white.opacity(0.75), radius: 3)
                        
                        if let imdb = series?.imdb ?? movie?.imdb {
                            HStack(alignment: .top) {
                                Group {
                                    if let seasons = series?.seasons {
                                        Text("\(seasons) season\(seasons == 1 ? "" : "s")")
                                    } else if let runtime = movie?.runtime {
                                        Text("\(runtime) mins")
                                    }
                                }
                                .shadow(radius: 1)
                                .foregroundStyle(.white)
                                .font(.system(size: 17, weight: .light))
                                .padding(8)
                                
                                Spacer()
                                
                                Text(String(imdb))
                                    .padding(4)
                                    .foregroundStyle(Color("textColor"))
                                    .font(.system(size: 17, weight: .bold))
                                    .background(.yellow.opacity(0.6))
                                    .cornerRadius(5)
                                    .padding(8)
                            }
                            .frame(width: width, height: height, alignment: .top)
                        }
                    }
                    .frame(width: width)
                } placeholder: {
                    ProgressView()
                        .frame(width: width, height: height)
                }
            }
        }
    }
}

#Preview {
    EntityItem(vM: BindingPageViewModel(), series: Series(id: "tt2560140", name: "Attack On Titan", releaseYear: 2013, lastReleaseYear: 2023, seasons: 4, category: "Animation", director: "Tetsurô Araki", actors: "Jessie James Grelle, Bryce Papenbrook, Trina Nishimura", description: "After his hometown is destroyed, young Eren Jaeger vows to cleanse the earth of the giant humanoid Titans that have brought humanity to the brink of extinction.", country: "Japan", awards: "40 wins & 88 nominations total", posterURL: "https://m.media-amazon.com/images/M/MV5BNjY4MDQxZTItM2JjMi00NjM5LTk0MWYtOTBlNTY2YjBiNmFjXkEyXkFqcGc@._V1_SX300.jpg", imdb: 9.1, imdbCount: "578,814", comments: [], ratings: []))
}

