//
//  BindingPageViewModel.swift
//  MovieSeriesDiary
//
//  Created by Emir Gökalp on 25.04.2025.
//

import Foundation
import FirebaseFirestore
import SwiftUI

class BindingPageViewModel: ObservableObject {
    @Published var seriesList: [Series] = []
    @Published var moviesList: [Movie] = []
    @Published var selectedType = 0
    @Published var user: User? = nil
    @Published var giveRating = false
    @Published var userRating: Double = 0.0
    @Published var writeComment = false
    @Published var commentText = ""
    
    init(seriesList: [Series] = [], moviesList: [Movie] = [], user: User? = nil) {
        self.seriesList = seriesList
        self.moviesList = moviesList
        self.user = user
    }
    
    func seriesOrMovies() -> some View {
        ZStack(alignment: selectedType == 0 ? .leading : .trailing) {
            Color(.systemGray5)
                .frame(height: 30)
                .cornerRadius(20)
            
            Color.white.opacity(0.25)
                .frame(width: 70, height: 30)
                .cornerRadius(20)
                .animation(.bouncy(duration: 0.4), value: selectedType)
            
            HStack(spacing: 0) {
                Button {
                    withAnimation(.bouncy(duration: 0.4)) {
                        self.selectedType = 0
                    }
                } label: {
                    Text("Series")
                        .frame(width: 60, height: 30)
                        .foregroundColor(selectedType == 0 ? .text : .gray.opacity(0.75))
                }
                .padding(.leading, 5)
                
                Spacer()
                    .frame(width: 10)
                
                Button {
                    withAnimation(.bouncy(duration: 0.4)) {
                        self.selectedType = 1
                    }
                } label: {
                    Text("Movies")
                        .frame(width: 60, height: 30)
                        .foregroundColor(selectedType == 1 ? .text : .gray.opacity(0.75))
                }
                .padding(.trailing, 5)
            }
        }
        .frame(width: 140, height: 30)
    }
    
    func sendComment(name: String) {
        var comment = Comment(senderId: user!.id, entityName: name, text: commentText, date: Date())
        var type = "series"
        withAnimation(.easeInOut(duration: 0.3)) {
            user!.comments.append(comment)
            
            
            if let seriesIndex = seriesList.firstIndex(where: {$0.name == name} ) {
                seriesList[seriesIndex].comments.append(comment)
            }
            
            if let movieIndex = moviesList.firstIndex(where: {$0.name == name} ) {
                moviesList[movieIndex].comments.append(comment)
                type = "movies"
            }
        }
        
        Firestore.firestore().collection(type).document(comment.entityName).collection("comments").document(comment.senderId).setData([
            "text": commentText,
            "createdDate": comment.date,
        ])
        
        Firestore.firestore().collection("users").document(comment.senderId).collection("comments").document(comment.entityName).setData([
            "text": commentText,
            "createdDate": comment.date,
        ])
        
        writeComment = false
        commentText = ""
    }
    
    func removeComment(name: String) {
        self.objectWillChange.send()
        guard let user = user else { return }
        guard let userCommentIndex = user.comments.firstIndex(where: { $0.entityName == name }) else { return }
        
        let comment = user.comments[userCommentIndex]
        var type = "series"
        
        withAnimation(.easeInOut(duration: 0.3)) {
            self.user!.comments.remove(at: userCommentIndex)
            
            if let seriesIndex = seriesList.firstIndex(where: { $0.name == name }) {
                if let commentIndex = seriesList[seriesIndex].comments.firstIndex(where: { $0.senderId == user.id }) {
                    seriesList[seriesIndex].comments.remove(at: commentIndex)
                }
            }
            
            if let movieIndex = moviesList.firstIndex(where: { $0.name == name }) {
                if let commentIndex = moviesList[movieIndex].comments.firstIndex(where: { $0.senderId == user.id }) {
                    moviesList[movieIndex].comments.remove(at: commentIndex)
                    type = "movies"
                }
            }
        }
        
        Firestore.firestore().collection(type).document(comment.entityName).collection("comments").document(comment.senderId).delete()
        
        Firestore.firestore().collection("users").document(comment.senderId).collection("comments").document(comment.entityName).delete()
    }
    
    func addWatchLater(name: String) {
        withAnimation(.easeInOut(duration: 0.25)) {
            user!.watchLaters.append(name)
            removeAlreadyWatched(name: name)
        }
        
        Firestore.firestore().collection("users").document(user!.id).setData([
            "watchLaters": user!.watchLaters
        ], merge: true)
    }
    
    func removeWatchLater(name: String) {
        withAnimation(.easeInOut(duration: 0.25)) {
            user!.watchLaters.removeAll(where: { $0 == name})
            objectWillChange.send()
        }
        
        Firestore.firestore().collection("users").document(user!.id).setData([
            "watchLaters": user!.watchLaters
        ], merge: true)
    }
    
    func addAlreadyWatched(name: String) {
        withAnimation(.easeInOut(duration: 0.25)) {
            user!.alreadyWatcheds.append(name)
            removeWatchLater(name: name)
        }
        
        Firestore.firestore().collection("users").document(user!.id).setData([
            "alreadyWatcheds": user!.alreadyWatcheds
        ], merge: true)
    }
    
    func removeAlreadyWatched(name: String) {
        withAnimation(.easeInOut(duration: 0.25)) {
            user!.alreadyWatcheds.removeAll(where: { $0 == name})
            objectWillChange.send()
        }
        
        Firestore.firestore().collection("users").document(user!.id).setData([
            "alreadyWatcheds": user!.alreadyWatcheds
        ], merge: true)
    }
    
    func unrate(id: String) {
        guard let user = user else { return }
        self.objectWillChange.send()
        
        var entityName: String?
        var type = "series"
        
        if let seriesIndex = seriesList.firstIndex(where: { $0.id == id }) {
            entityName = seriesList[seriesIndex].name
            
            if let ratingIndex = seriesList[seriesIndex].ratings.firstIndex(where: { $0.senderId == user.id }) {
                seriesList[seriesIndex].ratings.remove(at: ratingIndex)
            }
        }
        
        if let movieIndex = moviesList.firstIndex(where: { $0.id == id }) {
            entityName = moviesList[movieIndex].name
            type = "movies"
            
            if let ratingIndex = moviesList[movieIndex].ratings.firstIndex(where: { $0.senderId == user.id }) {
                moviesList[movieIndex].ratings.remove(at: ratingIndex)
            }
        }
        
        guard let name = entityName,
              let userRatingIndex = user.ratings.firstIndex(where: { $0.entityName == name }) else {
            return
        }
        
        let rating = user.ratings[userRatingIndex]
        self.user!.ratings.remove(at: userRatingIndex)
        
        Firestore.firestore().collection(type).document(name).collection("ratings").document(user.id).delete()
        Firestore.firestore().collection("users").document(user.id).collection("ratings").document(name).delete()
    }
    
    func rate(id: String) {
        var type = "series"
        
        var rating = Rating(senderId: "", entityName: "", rating: 0, date: Date())
        
        if let seriesIndex = seriesList.firstIndex(where: {$0.id == id} ) {
            rating = Rating(senderId: self.user!.id, entityName: seriesList[seriesIndex].name, rating: userRating, date: Date())
            
            seriesList[seriesIndex].ratings.append(rating)
            
            self.user!.ratings.append(rating)
            
            
        }
        
        if let movieIndex = moviesList.firstIndex(where: {$0.id == id} ) {
            rating = Rating(senderId: self.user!.id, entityName: moviesList[movieIndex].name, rating: userRating, date: Date())
            
            moviesList[movieIndex].ratings.append(rating)
            
            self.user!.ratings.append(rating)
            
            type = "movies"
        }
        
        Firestore.firestore().collection(type).document(rating.entityName).collection("ratings").document(rating.senderId).setData([
            "createdDate": rating.date,
            "score": rating.rating
        ])
        
        Firestore.firestore().collection("users").document(rating.senderId).collection("ratings").document(rating.entityName).setData([
            "createdDate": rating.date,
            "score": rating.rating
        ])
    }
    
    func getDominantColor(from url: URL, completion: @escaping (UIColor?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil,
                  let image = UIImage(data: data),
                  let cgImage = image.cgImage else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let width = 64
            let height = 64
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            guard let context = CGContext(data: nil,
                                          width: width,
                                          height: height,
                                          bitsPerComponent: 8,
                                          bytesPerRow: width * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: bitmapInfo) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            guard let pixelBuffer = context.data else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let pixelData = pixelBuffer.bindMemory(to: UInt8.self, capacity: width * height * 4)
            
            var colorBins = [String: (count: Int, color: UIColor)]()
            let binSize = 16
            
            for x in 0..<width {
                for y in 0..<height {
                    let offset = 4 * (y * width + x)
                    let r = pixelData[offset]
                    let g = pixelData[offset + 1]
                    let b = pixelData[offset + 2]
                    let a = pixelData[offset + 3]
                    
                    guard a > 127 else { continue }
                    
                    let brightness = (CGFloat(r) + CGFloat(g) + CGFloat(b)) / (3 * 255)
                    if brightness < 0.1 || brightness > 0.9 {
                        continue
                    }
                    
                    let rBin = Int(r) / binSize
                    let gBin = Int(g) / binSize
                    let bBin = Int(b) / binSize
                    
                    let colorKey = "\(rBin),\(gBin),\(bBin)"
                    
                    if let existing = colorBins[colorKey] {
                        colorBins[colorKey] = (existing.count + 1, existing.color)
                    } else {
                        let actualColor = UIColor(red: CGFloat(r)/255.0,
                                                  green: CGFloat(g)/255.0,
                                                  blue: CGFloat(b)/255.0,
                                                  alpha: 1.0)
                        colorBins[colorKey] = (1, actualColor)
                    }
                }
            }
            
            let dominantColorInfo = colorBins.max(by: { $0.value.count < $1.value.count })?.value
            
            DispatchQueue.main.async {
                completion(dominantColorInfo?.color)
            }
        }.resume()
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    func entityRow(name: String, releaseYear: Int, lastReleaseYear: Int? = nil, runtime: Int? = nil, seasons: Int? = nil, category: String, imdb: Double, posterURL: String) -> some View {
        HStack {
            if let url = URL(string: posterURL) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 75)
                } placeholder: {
                    ProgressView()
                        .frame(width: 50, height: 75)
                }
            } else {
                Text("problem")
            }
            
            VStack(alignment: .leading, spacing: 10){
                HStack {
                    VStack {
                        Text(name)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.75)
                            .padding(.top, 7)
                            .lineLimit(2)
                        Spacer()
                    }
                    
                    VStack {
                        HStack {
                            if let lastReleaseYear = lastReleaseYear, lastReleaseYear != releaseYear {
                                Text("\(String(releaseYear))-\(String(lastReleaseYear))")
                                    .foregroundStyle(.gray)
                                    .padding(.top, 7)
                                    .padding(.trailing, 20)
                            } else {
                                Text(String(releaseYear))
                                    .foregroundStyle(.gray)
                                    .padding(.top, 7)
                                    .padding(.trailing, 20)
                            }
                        }
                        Spacer()
                    }
                }
                if let runtime = runtime{
                    Text("\(runtime) mins")
                        .foregroundStyle(.gray)
                } else {
                    if let seasons = seasons {
                        Text("\(seasons) seasons")
                    }
                }
            }
            .padding(.vertical, 5)
            
            Spacer()
            Text(String(imdb))
                .padding(5)
                .foregroundStyle(Color("textColor"))
                .font(.system(size: 17, weight: .bold))
                .background(.yellow.opacity(0.6))
                .cornerRadius(5)
                .padding(.leading)
        }
        .foregroundStyle(Color("textColor"))
        .padding(.horizontal)
        .background(Color(.systemGray6))
    }
    
    func givingRating(id: String, userRating: Binding<Double>) -> some View {
        VStack(spacing: 16) {
            Text("Give a Rating")
                .font(.headline)
                .foregroundColor(.white)
            
            StarRatingView(rating: userRating)
            
            Text("Selected: \(String(format: "%.1f", self.userRating))")
                .foregroundColor(.white)
                .font(.subheadline)
                .padding(.top, 8)
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    withAnimation {
                        self.giveRating = false
                    }
                }
                .foregroundColor(.white)
                
                Button("Confirm") {
                    self.rate(id: id)
                    withAnimation {
                        self.giveRating = false
                    }
                }
                .foregroundColor(.white)
                .fontWeight(.bold)
                .padding(5)
                .background(Color("accentColor"))
                .cornerRadius(5)
                .disabled(self.userRating == 0.0)
            }
            .padding(.top, 16)
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding()
        .padding(.horizontal, 20)
        .onDisappear() {
            self.userRating = 0.0
        }
    }
    
    func writeCommentArea(name: String, commentText: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Write a comment")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Type something...", text: commentText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .font(.body)
                    .submitLabel(.send)
                    .onSubmit {
                        self.sendComment(name: name)
                    }

                Button {
                    self.sendComment(name: name)
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(commentText.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .clipShape(Circle())
                }
                .disabled(commentText.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
        )
        .padding(.horizontal)
        .onDisappear {
            commentText.wrappedValue = ""
        }
    }

}
