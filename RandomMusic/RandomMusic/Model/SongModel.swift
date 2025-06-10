//
//  SongModel.swift
//  RandomMusic
//
//  Created by drfranken on 6/9/25.
//

import Foundation


// 앱 내부 사용 모델
// thumbnail의 실제 이미지 데이터가 있음
struct SongModel {
    let title: String
    let album: String
    let artist: String
    let genre: String
    let id: Int
    let streamUrl: String
    let thumbnailData: Data?

    // SongResponse에서 변환
    init(from response: SongResponse, thumbnailData: Data? = nil) {
        self.title = response.title
        self.album = response.album
        self.artist = response.artist
        self.genre = response.genre
        self.id = response.id
        self.streamUrl = response.streamUrl
        self.thumbnailData = thumbnailData
    }

    init(title: String, album: String, artist: String, genre: String, id: Int, streamUrl: String, thumbnailData: Data? = nil) {
        self.title = title
        self.album = album
        self.artist = artist
        self.genre = genre
        self.id = id
        self.streamUrl = streamUrl
        self.thumbnailData = thumbnailData
    }
}
