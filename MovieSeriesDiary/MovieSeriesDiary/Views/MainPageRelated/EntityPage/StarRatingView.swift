//
//  StarRatingView.swift
//  MovieSeriesDiary
//
//  Created by Emir Gökalp on 9.05.2025.
//

import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Double

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: self.starImageName(for: index))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(.yellow)
                }
            }
            .frame(width: geometry.size.width, height: 36)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let sectionWidth = geometry.size.width / 5
                        let x = min(max(0, value.location.x), geometry.size.width)
                        let index = Int(x / sectionWidth)
                        let offsetInSection = x - CGFloat(index) * sectionWidth

                        if offsetInSection < sectionWidth / 2 {
                            rating = Double(index) + 0.5
                        } else {
                            rating = Double(index + 1)
                        }

                        rating = max(0.5, min(5.0, rating))
                    }
            )
        }
        .frame(height: 36)
    }

    private func starImageName(for index: Int) -> String {
        if rating >= Double(index + 1) {
            return "star.fill"
        } else if rating >= Double(index) + 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}


#Preview {
    
    StarRatingView(rating: .constant(1))
}
