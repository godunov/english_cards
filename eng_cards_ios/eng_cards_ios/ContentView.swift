//
//  ContentView.swift
//  eng_cards_ios
//
//  Created by Александр Годунов on 27/01/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WordListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Слова")
                }
                .tag(0)
            
            CategoryListView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Изучение")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
}
