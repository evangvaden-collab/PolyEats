import SwiftUI

struct RestaurantMenuView: View {
    let restaurant: Restaurant
    private var meals: [Meal] { SampleMenu.meals.filter { $0.restaurantID == restaurant.id } }
    private var categories: [String] { meals.reduce(into: []) { result, meal in if !result.contains(meal.category) { result.append(meal.category) } } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FoodArtwork(symbol: restaurant.symbol).frame(height: 170).clipShape(RoundedRectangle(cornerRadius: 16))
                Text(restaurant.tagline).font(.title2.bold())
                Label(restaurant.pickup, systemImage: "mappin").font(.caption).foregroundStyle(.secondary)
                Text("Sample menu · Estimated nutrition").font(.caption).foregroundStyle(Theme.sage)
                ForEach(categories, id: \.self) { category in
                    Text(category).font(.headline).padding(.top, 8)
                    ForEach(meals.filter { $0.category == category }) { MealRow(meal: $0) }
                }
                DemoDisclaimer()
            }.padding(20).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }.background(Theme.cream).navigationTitle(restaurant.name).navigationBarTitleDisplayMode(.inline)
    }
}

struct MealRow: View {
    @Environment(DiningStore.self) private var store
    let meal: Meal
    @State private var favoriteError: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(meal.name).font(.headline)
                    Text(meal.description).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Button {
                    do { try store.toggleFavorite(meal.id, meal: true) } catch { favoriteError = error.localizedDescription }
                } label: {
                    Image(systemName: store.data.favoriteMeals.contains(meal.id) ? "heart.fill" : "heart").padding(8)
                }.accessibilityLabel("Toggle favorite for \(meal.name)")
            }
            if meal.vegetarian { Label("Vegetarian", systemImage: "leaf").font(.caption2).foregroundStyle(Theme.sage) }
            NutritionSummary(calories: meal.calories, protein: meal.protein)
            DisclosureGroup("Full estimated nutrition") {
                Text("\(meal.carbs)g carbs · \(meal.fat)g fat per standard serving. Demo estimates, not verified nutrition. Allergen information is unverified.")
                    .font(.caption).foregroundStyle(.secondary).padding(.top, 6)
            }.font(.caption)
            HStack {
                Text(meal.priceCents.dollars).font(.headline)
                Spacer()
                NavigationLink { CustomizeMealView(meal: meal) } label: {
                    Label(meal.available ? "Add to bag" : "Unavailable", systemImage: "plus")
                        .font(.caption.weight(.semibold)).padding(11).foregroundStyle(.white)
                        .background(Theme.green, in: RoundedRectangle(cornerRadius: 9))
                }.disabled(!meal.available)
            }
        }.padding(18).background(.white, in: RoundedRectangle(cornerRadius: 14))
            .alert("Couldn’t save favorite", isPresented: Binding(get: { favoriteError != nil }, set: { if !$0 { favoriteError = nil } })) { Button("OK") { favoriteError = nil } } message: { Text(favoriteError ?? "") }
    }
}

struct CustomizeMealView: View {
    @Environment(DiningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let meal: Meal
    @State private var item: CartItem
    @State private var error: String?

    init(meal: Meal) {
        self.meal = meal
        _item = State(initialValue: CartItem(mealID: meal.id, protein: meal.vegetarian ? .beans : .chicken))
    }

    var body: some View {
        Form {
            Section {
                FoodArtwork(symbol: meal.symbol).frame(height: 140).listRowInsets(EdgeInsets())
                Text(meal.description).font(.subheadline).foregroundStyle(.secondary)
                NutritionSummary(calories: item.estimatedCalories, protein: item.estimatedProtein)
                Text("Estimated for selected quantity. Ingredient removals may lower these values. Allergen safety is not verified.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if meal.customizable {
                Section("Choose your protein") {
                    Picker("Protein", selection: $item.protein) {
                        ForEach(Protein.allCases) { protein in
                            Text("\(protein.rawValue)\(protein.priceCents > 0 ? " +\(protein.priceCents.dollars)" : "")").tag(protein)
                        }
                    }.pickerStyle(.inline).labelsHidden()
                }
                Section("Make it yours") {
                    ForEach(SampleMenu.extras) { extra in
                        Toggle("\(extra.name) · \(extra.priceCents == 0 ? "Free" : extra.priceCents.dollars)", isOn: Binding(
                            get: { item.extraIDs.contains(extra.id) },
                            set: { if $0 { item.extraIDs.insert(extra.id) } else { item.extraIDs.remove(extra.id) } }
                        ))
                    }
                }
                Section("Keep it or skip it") {
                    ForEach(SampleMenu.ingredients, id: \.self) { ingredient in
                        Toggle(ingredient, isOn: Binding(
                            get: { !item.removedIngredients.contains(ingredient) },
                            set: { if $0 { item.removedIngredients.remove(ingredient) } else { item.removedIngredients.insert(ingredient) } }
                        ))
                    }
                }
            }
            Section("One more thing") {
                Stepper("Quantity: \(item.quantity)", value: $item.quantity, in: 1...20)
                TextField("Special instructions", text: $item.instructions, axis: .vertical).lineLimit(2...4)
                    .onChange(of: item.instructions) { _, value in if value.count > 240 { item.instructions = String(value.prefix(240)) } }
            }
            Section {
                Button {
                    do { try store.add(item); dismiss() } catch { self.error = error.localizedDescription }
                } label: {
                    HStack { Label("Add to bag", systemImage: "plus"); Spacer(); Text(item.totalCents.dollars).bold() }
                }.disabled(!meal.available)
            } footer: { Text("Demo order only. No real payment or campus kitchen connection.") }
        }.navigationTitle(meal.name).navigationBarTitleDisplayMode(.inline)
            .alert("Couldn’t add item", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }
}
