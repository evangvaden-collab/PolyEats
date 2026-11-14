import SwiftUI

enum MealFilter: String, CaseIterable, Identifiable {
    case all = "All cravings", protein = "High protein", budget = "Under $10", vegetarian = "Vegetarian", light = "Under 600 cal"
    var id: String { rawValue }
    func includes(_ meal: Meal) -> Bool {
        switch self {
        case .all: true
        case .protein: meal.protein >= 30
        case .budget: meal.priceCents < 1000
        case .vegetarian: meal.vegetarian
        case .light: meal.calories < 600
        }
    }
}

struct HomeView: View {
    @Environment(DiningStore.self) private var store
    @State private var search = ""
    @State private var filter: MealFilter = .all
    @State private var error: String?

    private var results: [Meal] {
        SampleMenu.meals.filter { meal in
            filter.includes(meal) && (search.isEmpty || "\(meal.name) \(meal.description) \(SampleMenu.restaurant(meal.restaurantID)?.name ?? "")".localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    Brand()
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("SIMULATED BALANCE").font(.system(size: 8, weight: .semibold)).tracking(1)
                        Label(store.data.balanceCents.dollars, systemImage: "wallet.pass").font(.subheadline.bold())
                    }.foregroundStyle(Theme.green).accessibilityElement(children: .combine)
                }
                Label("Cal Poly, San Luis Obispo", systemImage: "mappin.and.ellipse")
                    .font(.caption).foregroundStyle(.secondary)
                hero
                if let order = store.activeOrders.first {
                    NavigationLink { OrderDetailView(orderID: order.id) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "takeoutbag.and.cup.and.straw.fill").font(.title2)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Order #\(order.number)").font(.subheadline.bold())
                                Text(order.status.rawValue).font(.caption)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                        }.padding().foregroundStyle(Theme.green).background(Theme.soft, in: RoundedRectangle(cornerRadius: 13))
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("What sounds good, Jordan?").font(.title2.bold()).tracking(-0.5)
                    Text("Your campus favorites, all in one place.").font(.subheadline).foregroundStyle(.secondary)
                }
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search meals or restaurants", text: $search).autocorrectionDisabled()
                    if !search.isEmpty { Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel("Clear search") }
                }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 12))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MealFilter.allCases) { value in
                            Button { filter = value } label: {
                                Text(value.rawValue).font(.caption.weight(.medium)).padding(.horizontal, 15).padding(.vertical, 10)
                                    .foregroundStyle(filter == value ? .white : Theme.green)
                                    .background(filter == value ? Theme.green : .white, in: Capsule())
                            }.accessibilityAddTraits(filter == value ? .isSelected : [])
                        }
                    }
                }
                if search.isEmpty && filter == .all {
                    HStack {
                        Text("Good food, close by").font(.title2.bold()).tracking(-0.5)
                        Spacer()
                        Text("5 spots").font(.caption).foregroundStyle(.secondary)
                    }
                    ForEach(SampleMenu.restaurants) { restaurant in
                        RestaurantCard(restaurant: restaurant)
                    }
                } else {
                    Text("\(results.count) meals for your cravings").font(.headline)
                    ForEach(results) { MealRow(meal: $0) }
                    if results.isEmpty {
                        ContentUnavailableView.search(text: search)
                    }
                }
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "leaf.circle.fill").font(.largeTitle).foregroundStyle(Theme.sage)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Know what fuels you.").font(.headline)
                        Text("Calories and protein on every menu. Your food, your call.").font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(Theme.soft, in: RoundedRectangle(cornerRadius: 14))
                DemoDisclaimer()
            }.padding(20).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }.background(Theme.cream).toolbar(.hidden, for: .navigationBar)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MADE FOR MUSTANGS").font(.system(size: 9, weight: .bold)).tracking(2).foregroundStyle(Theme.sage)
            (Text("Your campus.\n").foregroundColor(Theme.green) + Text("Your cravings.").foregroundColor(Theme.sage))
                .font(.system(size: 42, weight: .semibold, design: .rounded)).tracking(-1.8)
                .minimumScaleFactor(0.8).accessibilityAddTraits(.isHeader)
            Text("Skip the line. Find your favorites.\nA better bite is right around the corner.")
                .font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)
            NavigationLink { RestaurantMenuView(restaurant: SampleMenu.restaurants[0]) } label: {
                Label("Find your next bite", systemImage: "arrow.up.right")
                    .font(.subheadline.weight(.semibold)).padding(.horizontal, 18).padding(.vertical, 13)
                    .foregroundStyle(.white).background(Theme.green, in: RoundedRectangle(cornerRadius: 10))
            }
            HStack(spacing: 8) {
                Label("Nutrition up front", systemImage: "leaf")
                Text("·")
                Text("Demo dining")
            }.font(.caption2).foregroundStyle(Theme.sage)
        }.padding(25).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.soft, in: RoundedRectangle(cornerRadius: 20))
            .overlay(alignment: .topTrailing) {
                Image(systemName: "sun.max.fill").font(.title).foregroundStyle(Theme.gold).padding(20).accessibilityHidden(true)
            }
    }
}

struct RestaurantCard: View {
    @Environment(DiningStore.self) private var store
    let restaurant: Restaurant
    @State private var error: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink { RestaurantMenuView(restaurant: restaurant) } label: {
                FoodArtwork(symbol: restaurant.symbol).frame(height: 150)
            }.accessibilityLabel("View \(restaurant.name) menu")
            HStack(alignment: .top) {
                NavigationLink { RestaurantMenuView(restaurant: restaurant) } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(restaurant.name).font(.title3.bold()).foregroundStyle(Theme.green)
                        Text(restaurant.cuisine).font(.caption).foregroundStyle(.secondary)
                        Label("Open in demo · Nutrition available", systemImage: "leaf").font(.caption2).foregroundStyle(Theme.sage)
                    }
                }
                Spacer()
                Button {
                    do { try store.toggleFavorite(restaurant.id) } catch { self.error = error.localizedDescription }
                } label: {
                    Image(systemName: store.data.favoriteRestaurants.contains(restaurant.id) ? "heart.fill" : "heart").padding(10)
                }.accessibilityLabel("Toggle favorite for \(restaurant.name)")
            }.padding(17)
        }.background(.white, in: RoundedRectangle(cornerRadius: 16)).clipShape(RoundedRectangle(cornerRadius: 16))
            .alert("Couldn’t save favorite", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }
}
