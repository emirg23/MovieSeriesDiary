//
//  LoginPageViewModel.swift
//  MovieSeriesDiary
//
//  Created by Emir Gökalp on 10.05.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

class LoginPageViewModel: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var password1 = ""
    @Published var password2 = ""
    @Published var logging = false
    @Published var registering = false
    @Published var navigate = false
    @Published var failed = false
    @Published var failText = " "
    @Published var loading = false
    var failTextTimer: Timer?

    var vM: BindingPageViewModel
    var isEmailValid: Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email)
    }

    var loginValid: Bool {
        isEmailValid && password1.count >= 6
    }

    var isUsernameValid: Bool {
        let regex = "^(?!\\d+$)[a-zA-Z0-9_]{3,20}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: username)
    }

    var registerValid: Bool {
        isEmailValid &&
        password1 == password2 &&
        password1.count >= 6 &&
        isUsernameValid
    }
    

    init(vM: BindingPageViewModel) {
        self.vM = vM
    }
    
    func fetchEverything(completion: @escaping ((series: [Series], movies: [Movie])) -> Void) {
        self.fetchSeries() { series in
            self.fetchMovies() { movies in
                completion((series: series, movies: movies))
            }
        }
    }
    
    func fetchUserData(email: String, completion: @escaping (User?) -> Void) {
        let db = Firestore.firestore().collection("users")
        
        db.whereField("email", isEqualTo: email.lowercased()).getDocuments { snapshot, error in
            guard let document = snapshot?.documents.first, error == nil else {
                completion(nil)
                return
            }
            
            let data = document.data()
            let username = document.documentID
            let alreadyWatcheds = data["alreadyWatcheds"] as? [String] ?? []
            let watchLaters = data["watchLaters"] as? [String] ?? []

            var ratings: [Rating] = []
            var comments: [Comment] = []

            let group = DispatchGroup()

            group.enter()
            document.reference.collection("ratings").getDocuments { snapshot, _ in
                if let docs = snapshot?.documents {
                    ratings = docs.compactMap { doc in
                        let data = doc.data()
                        let targetId = doc.documentID
                        guard let score = data["score"] as? Double,
                              let date = (data["createdDate"] as? Timestamp)?.dateValue() else {
                            return nil
                        }
                        return Rating(senderId: username, entityName: targetId, rating: score, date: date)
                    }
                }
                group.leave()
            }

            group.enter()
            document.reference.collection("comments").getDocuments { snapshot, _ in
                if let docs = snapshot?.documents {
                    comments = docs.compactMap { doc in
                        let data = doc.data()
                        let targetId = doc.documentID
                        guard let text = data["text"] as? String,
                              let date = (data["createdDate"] as? Timestamp)?.dateValue() else {
                            return nil
                        }
                        return Comment(senderId: username, entityName: targetId, text: text, date: date)
                    }
                }
                group.leave()
            }

            group.notify(queue: .main) {
                let user = User(id: username,
                                email: email,
                                watchLaters: watchLaters,
                                alreadyWatcheds: alreadyWatcheds,
                                ratings: ratings,
                                comments: comments)
                self.objectWillChange.send()
                completion(user)
            }
        }
    }
    
    func fetchSeries(completion: @escaping ([Series]) -> Void) {
        var series: [Series] = []
        let db = Firestore.firestore().collection("series")
        let group = DispatchGroup()

        db.getDocuments { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                return
            }

            for document in snapshot.documents {
                let data = document.data()
                let name = document.documentID

                let category = data["category"] as? String ?? ""
                let description = data["description"] as? String ?? ""
                let director = data["director"] as? String ?? ""
                let imdb = data["imdb"] as? Double ?? 0
                let lastReleaseYear = data["lastReleaseYear"] as? Int ?? 0
                let releaseYear = data["releaseYear"] as? Int ?? 0
                let seasons = data["season"] as? Int ?? 0
                let id = data["id"] as? String ?? ""
                let posterURL = data["posterURL"] as? String ?? ""
                let actors = data["actors"] as? String ?? ""
                let country = data["country"] as? String ?? ""
                let awards = data["awards"] as? String ?? ""
                let imdbCount = data["imdbCount"] as? String ?? ""

                var belongComments: [Comment] = []
                var belongRatings: [Rating] = []

                group.enter()
                document.reference.collection("comments").getDocuments { snapshot, _ in
                    if let docs = snapshot?.documents {
                        belongComments = docs.compactMap { doc in
                            let data = doc.data()
                            guard let text = data["text"] as? String,
                                  let date = (data["createdDate"] as? Timestamp)?.dateValue() else {
                                return nil
                            }
                            return Comment(senderId: doc.documentID, entityName: name, text: text, date: date)
                        }
                    }
                    group.leave()
                }

                group.enter()
                document.reference.collection("ratings").getDocuments { snapshot, _ in
                    if let docs = snapshot?.documents {
                        belongRatings = docs.compactMap { doc in
                            let data = doc.data()
                            guard let score = data["score"] as? Double,
                                  let date = (data["createdDate"] as? Timestamp)?.dateValue() else {
                                return nil
                            }
                            return Rating(senderId: doc.documentID, entityName: name, rating: score, date: date)
                        }
                    }
                    group.leave()
                }

                group.notify(queue: .main) {
                    let newSeries = Series(id: id,
                                           name: name,
                                           releaseYear: releaseYear,
                                           lastReleaseYear: lastReleaseYear,
                                           seasons: seasons,
                                           category: category,
                                           director: director,
                                           actors: actors,
                                           description: description,
                                           country: country,
                                           awards: awards,
                                           posterURL: posterURL,
                                           imdb: imdb,
                                           imdbCount: imdbCount,
                                           comments: belongComments,
                                           ratings: belongRatings)

                    series.append(newSeries)

                    if series.count == snapshot.documents.count {
                        completion(series)
                    }
                }
            }
        }
    }
    
    func fetchMovies(completion: @escaping ([Movie]) -> Void) {
        var movies: [Movie] = []
        let db = Firestore.firestore().collection("movies")
        let group = DispatchGroup()

        db.getDocuments { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                return
            }

            for document in snapshot.documents {
                let data = document.data()
                let name = document.documentID

                let category = data["category"] as? String ?? ""
                let description = data["description"] as? String ?? ""
                let director = data["director"] as? String ?? ""
                let imdb = data["imdb"] as? Double ?? 0
                let releaseYear = data["releaseYear"] as? Int ?? 0
                let id = data["id"] as? String ?? ""
                let posterURL = data["posterURL"] as? String ?? ""
                let runtime = data["runtime"] as? Int ?? 0
                let actors = data["actors"] as? String ?? ""
                let country = data["country"] as? String ?? ""
                let awards = data["awards"] as? String ?? ""
                let imdbCount = data["imdbCount"] as? String ?? ""

                var belongComments: [Comment] = []
                var belongRatings: [Rating] = []

                group.enter()
                document.reference.collection("comments").getDocuments { snapshot, _ in
                    if let docs = snapshot?.documents {
                        belongComments = docs.compactMap { doc in
                            let data = doc.data()
                            guard let text = data["text"] as? String,
                                  let date = (data["createdDate"] as? Timestamp)?.dateValue() else {
                                return nil
                            }
                            return Comment(senderId: doc.documentID, entityName: name, text: text, date: date)
                        }
                    }
                    group.leave()
                }

                group.enter()
                document.reference.collection("ratings").getDocuments { snapshot, _ in
                    if let docs = snapshot?.documents {
                        belongRatings = docs.compactMap { doc in
                            let data = doc.data()
                            guard let score = data["score"] as? Double,
                                  let date = (data["createdDate"] as? Timestamp)?.dateValue() else {
                                return nil
                            }
                            return Rating(senderId: doc.documentID, entityName: name, rating: score, date: date)
                        }
                    }
                    group.leave()
                }

                group.notify(queue: .main) {
                    let newMovie = Movie(id: id,
                                         name: name,
                                         releaseYear: releaseYear,
                                         runtime: runtime,
                                         category: category,
                                         director: director,
                                         actors: actors,
                                         description: description,
                                         country: country,
                                         awards: awards,
                                         posterURL: posterURL,
                                         imdb: imdb,
                                         imdbCount: imdbCount,
                                         comments: belongComments,
                                         ratings: belongRatings)

                    movies.append(newMovie)

                    if movies.count == snapshot.documents.count {
                        completion(movies)
                    }
                }
            }
        }
    }
    
    func login() {
        withAnimation(.easeInOut(duration: 0.25)) {
            loading = true
        }
        Auth.auth().signIn(withEmail: email, password: password1) { result, error in
            if let error = error {
                Firestore.firestore().collection("users").getDocuments() { snapshot, error in
                    guard let snapshot = snapshot, error == nil else {
                        return 
                    }
                    
                    var emails: [String] = []
                    
                    for document in snapshot.documents {
                        var data = document.data()
                        
                        emails.append(data["email"] as? String ?? "")
                    }
                    if emails.contains(self.email) {
                        self.failed(text: "Wrong password.")
                    } else {
                        self.failed(text: "This email is not registered.")
                    }
                    
                }
            } else {
                print("Login successful! UID: \(result?.user.uid ?? "unknown")")
                
                self.fetchUserData(email: self.email.lowercased()) { user in
                    self.vM.user = user
                    self.navigate = true
                }
            }
        }
    }
    
    func register() {
        withAnimation(.easeInOut(duration: 0.25)) {
            loading = true
        }
        Firestore.firestore().collection("users").getDocuments() { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                return
            }
            
            if snapshot.documents.map( {$0.documentID.lowercased()}).contains(self.username.lowercased()) {
                self.failed(text: "Username already taken.")
            } else {
                Auth.auth().createUser(withEmail: self.email, password: self.password1) { result, error in
                    if let error = error {
                        self.failed(text: error.localizedDescription)
                    } else {
                        var data: [String:Any] = [
                            "email": self.email.lowercased()
                        ]
                        Firestore.firestore().collection("users").document(self.username.lowercased()).setData(data)
                        
                        var user = User(id: self.username.lowercased(), email: self.email.lowercased(), watchLaters: [], alreadyWatcheds: [], ratings: [], comments: [])
                        
                        self.vM.user = user

                        DispatchQueue.main.async {
                            self.navigate = true
                        }
                    }
                }
            }
        }
    }
    
    func failed(text: String) {
        withAnimation(.easeInOut(duration: 0.25)) {
            self.failText = text
            self.failed = true
        }
        failTextTimer?.invalidate()

        failTextTimer = Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                self.failText = " "
            }
            self.failTextTimer = nil
        }
    }
}
