import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userData: UserData
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            AIChatView()
                .tabItem {
                    Label("AI", systemImage: "brain.head.profile")
                }
                .tag(1)
            
            PetsView()
                .tabItem {
                    Label("Pets", systemImage: "pawprint.fill")
                }
                .tag(2)
            
            ShopView()
                .tabItem {
                    Label("Shop", systemImage: "cart.fill")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(AppColors.brandPrimary)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserData.shared)
        .environmentObject(WatchConnectivityService.shared)
}
