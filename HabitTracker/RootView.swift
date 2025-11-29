//
//  RootView.swift
//  HabitTracker
//
//  Created by Vineeth  Reddy on 03/12/25.
//


import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            // Existing habit screen
            ContentView()
                .tabItem {
                    Label("Habits", systemImage: "checklist")
                }

            // New calorie counter tab
            CalorieCounterView()
                .tabItem {
                    Label("Calories", systemImage: "flame")
                }
        }
    }
}
