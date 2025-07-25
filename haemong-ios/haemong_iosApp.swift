//
//  haemong_iosApp.swift
//  haemong-ios
//
//  Created by Kang Seongchan on 7/25/25.
//

import SwiftUI
import ComposableArchitecture

@main
struct haemong_iosApp: App {
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    } withDependencies: {
        $0.apiClient = .liveValue  // 실제 서버와 통신하도록 변경
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .preferredColorScheme(.light)
        }
    }
}
