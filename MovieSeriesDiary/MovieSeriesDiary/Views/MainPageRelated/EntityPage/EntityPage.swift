//
//  EntityPage.swift
//  MovieSeriesDiary
//
//  Created by Emir Gökalp on 24.04.2025.
//

import SwiftUI
import UIKit
import CoreGraphics
import FirebaseFirestore

struct EntityPage: View {
    @ObservedObject var vM: BindingPageViewModel
    @State var dominantColor = Color.back
    
    // COMMON ATTRIBUTES
    var id: String
    var name: String
    var releaseYear: Int
    var director: String
    var category: String
    var country: String
    var posterURL: String
    var description: String
    var actors: String
    var imdbCount: String
    var imdb: Double
    var awards: String
    @Binding var comments: [Comment]

    // SPECIAL ATTRIBUTES
    var lastReleaseYear: Int?
    var runtime: Int?
    var seasons: Int?

    init(vM: BindingPageViewModel, movie: Movie? = nil, series: Series? = nil, comments: Binding<[Comment]>) {
        self.vM = vM
        self._comments = comments
        
        // COMMON ATTRIBUTES
        self.id = movie?.id ?? series!.id
        self.name = movie?.name ?? series!.name
        self.releaseYear = movie?.releaseYear ?? series!.releaseYear
        self.director = movie?.director ?? series!.director
        self.category = movie?.category ?? series!.category
        self.country = movie?.country ?? series!.country
        self.posterURL = movie?.posterURL ?? series!.posterURL
        self.description = movie?.description ?? series!.description
        self.actors = movie?.actors ?? series!.actors
        self.imdbCount = movie?.imdbCount ?? series!.imdbCount
        self.imdb = movie?.imdb ?? series!.imdb
        self.awards = movie?.awards ?? series!.awards
        
        // SPECIAL ATTRIBUTES
        self.lastReleaseYear = series?.lastReleaseYear
        self.runtime = movie?.runtime
        self.seasons = series?.seasons
    }
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        
                        ZStack(alignment: .top) {
                            
                            VStack(spacing: 0) {
                                dominantColor.opacity(0.7)
                                    .ignoresSafeArea()
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.back, dominantColor.opacity(0.7)]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                                .frame(height: 200)
                                .ignoresSafeArea()
                            }
                            .frame(height: 500)
                            .position(x: UIScreen.main.bounds.width / 2, y: 0)
                            
                            VStack {
                                HStack(alignment: .top){
                                    
                                    postersLeftPart(proxy: proxy)
                                        .padding(.leading)
                                    
                                    Spacer()
                                    
                                    if let url = URL(string: posterURL) {
                                        AsyncImage(url: url) { image in
                                            ZStack {
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 130, height: 190)
                                                    .clipped()
                                                    .cornerRadius(20)
                                                    .onAppear {
                                                        vM.getDominantColor(from: url) { dominantColor in
                                                            if let color = dominantColor {
                                                                withAnimation(.easeInOut(duration: 0.75)) {
                                                                    self.dominantColor = Color(color)
                                                                }
                                                            }
                                                        }
                                                    }
                                                
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.gray, lineWidth: 1)
                                                    .frame(width: 130, height: 190)
                                            }
                                            .padding(.trailing, 15)
                                        } placeholder: {
                                            ProgressView()
                                                .frame(width: 50, height: 75)
                                        }
                                    } else {
                                        Text("!")
                                    }
                                }
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal)
                                .padding(.top)
                                
                                Text(description)
                                    .font(.system(size: 15))
                                    .padding(.top, 15)
                                    .padding(.horizontal)
                                    .minimumScaleFactor(0.75)
                                
                                HStack {
                                    Text("ACTORS")
                                        .font(.system(size: 14, weight: .thin))
                                    Spacer()
                                    Color.gray
                                        .frame(height: 1)
                                }
                                .padding(.horizontal)
                                .padding(.top)
                                
                                VStack{
                                    ForEach(actors.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }, id: \.self) { actor in
                                        HStack {
                                            Text(actor)
                                                .font(.system(size: 15, weight: .semibold))
                                            
                                            Spacer()
                                        }
                                        .padding(.leading)
                                        .padding(.vertical, 4)
                                    }
                                }
                                
                                HStack {
                                    Text("RATINGS")
                                        .font(.system(size: 14, weight: .thin))
                                    Spacer()
                                    Color.gray
                                        .frame(height: 1)
                                }
                                .padding(.horizontal)
                                .padding(.top)
                                
                                HStack{
                                    Image("imdb")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 65)
                                    
                                    Text("\(imdbCount) Votes")
                                        .font(.system(size: 17, weight: .thin))
                                        .padding(.leading, 10)
                                    
                                    Spacer()
                                    
                                    Text(String(imdb))
                                        .padding(5)
                                        .foregroundStyle(Color("textColor"))
                                        .font(.system(size: 17, weight: .bold))
                                        .background(.yellow.opacity(0.6))
                                        .cornerRadius(5)
                                        .padding(.trailing)
                                }
                                .padding(10)
                                .background(.black.opacity(0.4))
                                .cornerRadius(5)
                                .padding(.horizontal)
                                .padding(.top, 4)
                                
                                HStack { // our apps' rate part
                                    Image("logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50)
                                        .padding(.trailing, 15)
                                    
                                    if let avgRating = vM.seriesList.first(where: { $0.id == id })?.avgRating ?? vM.moviesList.first(where: { $0.id == id })?.avgRating, avgRating != 0 {
                                        ForEach(0..<5, id: \.self) { index in
                                            let fullStarRating = Double(index + 1)
                                            if fullStarRating <= avgRating {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.yellow)
                                                
                                            } else if fullStarRating - 0.5 <= avgRating {
                                                Image(systemName: "star.leadinghalf.filled")
                                                    .foregroundColor(.yellow)
                                            } else {
                                                Image(systemName: "star")
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Text(String(format: "%.1f", avgRating))
                                            .padding(5)
                                            .foregroundStyle(Color("textColor"))
                                            .font(.system(size: 17, weight: .bold))
                                            .background(.yellow.opacity(0.6))
                                            .cornerRadius(5)
                                            .padding(.trailing)
                                    } else {
                                        Text("Not rated yet!")
                                            .font(.system(size: 17, weight: .thin))
                                            .padding(.leading)
                                        Spacer()
                                        
                                        if vM.user != nil { // can give rate part
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    vM.giveRating = true
                                                }
                                            } label: {
                                                VStack {
                                                    Image(systemName: "star")
                                                        .font(.system(size: 20))
                                                    Text("Rate")
                                                        .font(.system(size: 10))
                                                }
                                                .padding(.trailing)
                                            }
                                            .foregroundStyle(.yellow.opacity(0.5))
                                        }
                                    }
                                }
                                .padding(10)
                                .background(.black.opacity(0.4))
                                .cornerRadius(5)
                                .padding(.horizontal)
                                .padding(.top, 4)
                                
                                if awards != "N/A" {
                                    HStack {
                                        Text("AWARDS")
                                            .font(.system(size: 14, weight: .thin))
                                        Spacer()
                                        Color.gray
                                            .frame(height: 1)
                                    }
                                    .padding(.horizontal)
                                    .padding(.top)
                                    
                                    HStack {
                                        Text(awards)
                                            .font(.headline)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 4)
                                }
                                
                                HStack {
                                    Text("COMMENTS")
                                        .font(.system(size: 14, weight: .thin))
                                    Spacer()
                                    Color.gray
                                        .frame(height: 1)
                                }
                                .padding(.horizontal)
                                .padding(.top)
                                
                                if comments.isEmpty {
                                    HStack {
                                        Spacer()
                                        Text("No comments yet!")
                                        Spacer()
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.black.opacity(0.5))
                                            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                                    )
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                } else {
                                    ForEach(comments, id: \.self) { comment in
                                        commentItem(comment: comment)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(name)
                            .font(.system(size: 17, weight: .bold))
                            .minimumScaleFactor(0.75)
                            .lineLimit(1)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if vM.user != nil {
                            if vM.user!.ratings.map( {$0.entityName} ).contains(name) {
                                Button {
                                    vM.unrate(id: id)
                                } label: {
                                    Image(systemName: "star.fill")
                                }
                                .foregroundStyle(.yellow)
                            } else {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        vM.giveRating = true
                                    }
                                } label: {
                                    Image(systemName: "star")
                                }
                                .foregroundStyle(.yellow)
                            }
                        }
                    }
                }
                .background(Color.back)
            }
            
            if vM.giveRating {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        vM.giveRating = false
                    }
                
                vM.givingRating(id: id, userRating: $vM.userRating)
            }
            
            if vM.writeComment {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        vM.writeComment = false
                    }
                
                vM.writeCommentArea(name: name, commentText: $vM.commentText)
            }
        }
    }
    
    func postersLeftPart(proxy: ScrollViewProxy) -> some View{
        VStack(alignment: .center){
            Group {
                if let lastYear = lastReleaseYear, lastYear != releaseYear {
                    Text("\(String(releaseYear)) - \(String(lastYear)) • Directed by")
                } else {
                    Text("\(String(releaseYear)) • Directed by")
                }
            }
            .font(.system(size: 14, weight: .light))
            .padding(.top, 20)
            
            Text(director)
            Group {
                if let seasons = seasons {
                    Text("\(category) • \(seasons) Seasons")
                } else {
                    Text("\(category) • \(runtime!) Minutes")
                }
            }
            .font(.system(size: 16, weight: .light))
            .padding(.top, 5)
            .minimumScaleFactor(0.75)
            
            Text(country.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
                .font(.system(size: 14, weight: .light))
                .padding(.top, 3)
            
            if vM.user != nil {
                HStack {
                    if vM.user!.alreadyWatcheds.contains(name) {
                        Button {
                            vM.removeAlreadyWatched(name: name)
                        } label: {
                            VStack {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                
                                Text("Watched")
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 10)
                    } else {
                        Button {
                            vM.addAlreadyWatched(name: name)
                        } label: {
                            VStack {
                                Image(systemName: "eye")
                                    .font(.system(size: 20))
                                
                                Text("Watched")
                                    .font(.system(size: 10))
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    
                    if vM.user!.watchLaters.contains(name) {
                        Button {
                            vM.removeWatchLater(name: name)
                        } label: {
                            VStack {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                
                                Text("Later")
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 10)
                    } else {
                        Button {
                            vM.addWatchLater(name: name)
                        } label: {
                            VStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 20))
                                
                                Text("Later")
                                    .font(.system(size: 10))
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    
                    if comments.map( {$0.senderId} ).contains(vM.user!.id) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(vM.user!.id, anchor: .center)
                            }
                        } label: {
                            VStack {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                
                                Text("Comment")
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(.green)
                        }
                    } else {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                vM.writeComment = true
                            }
                        } label: {
                            VStack {
                                Image(systemName: "text.bubble")
                                    .font(.system(size: 20))
                                
                                Text("Comment")
                                    .font(.system(size: 10))
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                }
                .foregroundStyle(Color("textColor"))
                .padding(.top, 15)
            }
        }
    }
    
    func commentItem(comment: Comment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text(comment.senderId)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.white)
                }
                
                Spacer()
                
                Text(vM.formatDate(comment.date))
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color.white.opacity(0.8))
            }
            
            Text(comment.text)
                .font(.system(size: 15))
                .foregroundColor(Color.white)
                .padding(.vertical, 4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .id(comment.senderId)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.5))
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
        )
        .contextMenu {
            if vM.user != nil && comment.senderId == vM.user!.id {
                Button {
                    vM.removeComment(name: name)
                } label: {
                    HStack {
                        Text("Remove")
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

}

#Preview {
    var series = Series(
        id: "tt2560140",
        name: "Attack on Titan",
        releaseYear: 2013,
        lastReleaseYear: 2023,
        seasons: 5,
        category: "Animation",
        director: "Emirhan Gökalp",
        actors: "emir gökalp, tester, testerenemy",
        description: "After his hometown is destroyed, young Eren Jaeger vows to cleanse the earth of the giant humanoid Titans that have brought humanity to the brink of extinction.",
        country: "Turkey",
        awards: "40 wins & 88 nominations total",
        posterURL: "https://m.media-amazon.com/images/M/MV5BNjY4MDQxZTItM2JjMi00NjM5LTk0MWYtOTBlNTY2YjBiNmFjXkEyXkFqcGc@._V1_SX300.jpg",
        imdb: 9.1,
        imdbCount: "578,814",
        comments: [Comment(senderId: "tester", entityName: "Attack On Titan", text: "I love testing this app.", date: Date()), Comment(senderId: "testerenemy", entityName: "Attack On Titan", text: "I don't like this tester and a here is a long text about him: SADASDASDSADDAASDASDASADASDFASDFSAFASDFSADFDSAFSADFDASFASDFASDFSFSADFASFSFSFASFASDFSADFSDAFADSFASDFSADFASDFSAFDASFASDFASDFASDFASDFASDFDASFASDFASFASFD", date: Date())],
        ratings: []
    )

    EntityPage(vM: BindingPageViewModel(), series: series, comments: .constant(series.comments))
}
 
