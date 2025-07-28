//
//  haemong_iosApp.swift
//  haemong-ios
//
//  Created by Kang Seongchan on 7/25/25.
//

import SwiftUI
import ComposableArchitecture
import Kingfisher

@main
struct haemong_iosApp: App {
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    } withDependencies: {
        $0.apiClient = .liveValue  // 실제 서버와 통신하도록 변경
    }
    
    init() {
        // Kingfisher 캐시 설정
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024 // 100MB
        cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024 // 200MB
        
        // 다운로더 설정
        let downloader = ImageDownloader.default
        downloader.downloadTimeout = 30.0
        downloader.sessionConfiguration.timeoutIntervalForRequest = 30.0
        downloader.sessionConfiguration.timeoutIntervalForResource = 60.0
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .preferredColorScheme(.light)
        }
    }
}
