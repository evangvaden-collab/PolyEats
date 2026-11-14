import SwiftUI

struct ContentView: View {
    @Environment(DiningStore.self) private var store
    @State private var showingBag = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView() }
                .tabItem { Label("Explore", systemImage: "fork.knife") }.tag(0)
            NavigationStack { OrdersView() }
                .tabItem { Label("Orders", systemImage: "receipt") }.tag(1)
                .badge(store.activeOrders.count)
            NavigationStack { FavoritesView() }
                .tabItem { Label("Favorites", systemImage: "heart") }.tag(2)
            NavigationStack { AccountView() }
                .tabItem { Label("Account", systemImage: "person.crop.circle") }.tag(3)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if store.cartCount > 0 {
                Button { showingBag = true } label: {
                    HStack {
                        Label("View bag · \(store.cartCount) items", systemImage: "bag")
                        Spacer()
                        Text(store.cartTotal.dollars).bold()
                    }.font(.subheadline).padding(15)
                        .foregroundStyle(.white).background(Theme.green, in: RoundedRectangle(cornerRadius: 13))
                }.padding(.horizontal).padding(.bottom, 6).background(Theme.cream)
            }
        }
        .sheet(isPresented: $showingBag) { NavigationStack { CartView() } }
    }
}

#Preview {
    ContentView().environment(DiningStore(defaults: UserDefaults(suiteName: "PolyEats.preview")!))
}
