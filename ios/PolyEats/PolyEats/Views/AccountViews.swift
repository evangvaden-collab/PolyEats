import SwiftUI

struct FavoritesView: View {
    @Environment(DiningStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("The usual, please.").font(.title2.bold())
                Text("Your favorite spots").font(.headline)
                ForEach(SampleMenu.restaurants.filter { store.data.favoriteRestaurants.contains($0.id) }) { RestaurantCard(restaurant: $0) }
                if store.data.favoriteRestaurants.isEmpty { Text("Tap a heart on a dining spot to save it here.").font(.subheadline).foregroundStyle(.secondary) }
                Text("Your favorite meals").font(.headline).padding(.top, 10)
                ForEach(SampleMenu.meals.filter { store.data.favoriteMeals.contains($0.id) }) { MealRow(meal: $0) }
                if store.data.favoriteMeals.isEmpty { Text("Save a meal from any restaurant menu.").font(.subheadline).foregroundStyle(.secondary) }
            }.padding(20).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }.background(Theme.cream).navigationTitle("Favorites")
    }
}

struct AccountView: View {
    @Environment(DiningStore.self) private var store
    @State private var showingKitchen = false
    @State private var confirmingReset = false
    @State private var error: String?
    var body: some View {
        List {
            Section {
                Label("Jordan Lee", systemImage: "person.crop.circle.fill").font(.title2.bold())
                Text("Demo student account").foregroundStyle(.secondary)
            }
            Section("Simulated Dining Dollars") {
                Text(store.data.balanceCents.dollars).font(.system(size: 40, weight: .semibold, design: .rounded)).foregroundStyle(Theme.green)
                Text("Demo funds only. No real payment or PolyCard connection.").font(.caption).foregroundStyle(.secondary)
            }
            if let warning = store.persistenceWarning { Section { Text(warning).foregroundStyle(.red) } }
            Section("Behind the counter") {
                Button("Open demo kitchen", systemImage: "frying.pan") { showingKitchen = true }
                Text("Demo staff code: MUSTANG. This is a presentation gate, not secure authentication.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Wallet activity") {
                ForEach(store.data.transactions) { transaction in
                    VStack(alignment: .leading, spacing: 6) {
                        LabeledContent("Order #\(transaction.orderNumber)", value: transaction.amountCents.dollars)
                        Text(transaction.date, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(.secondary)
                    }
                }
                if store.data.transactions.isEmpty { Text("No simulated purchases yet.").foregroundStyle(.secondary) }
            }
            Section {
                Button(role: .destructive) { confirmingReset = true } label: { Label("Reset demo data", systemImage: "arrow.counterclockwise") }
            } footer: { DemoDisclaimer() }
        }.navigationTitle("Your account")
            .sheet(isPresented: $showingKitchen) { NavigationStack { KitchenView() } }
            .confirmationDialog("Start fresh?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Reset to $150", role: .destructive) {
                    do { try store.reset() } catch { self.error = error.localizedDescription }
                }
                Button("Cancel", role: .cancel) { }
            } message: { Text("This clears all orders, bag items, favorites, and wallet activity on this device.") }
            .alert("Couldn’t reset demo", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }
}

struct KitchenView: View {
    @Environment(DiningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var authenticated = false
    @State private var code = ""
    @State private var restaurant = "all"
    @State private var completed = false
    @State private var error: String?
    private var orders: [DiningOrder] {
        store.data.orders.filter { (restaurant == "all" || $0.restaurantID == restaurant) && (completed ? $0.status == .completed : $0.status != .completed) }.sorted { $0.createdAt < $1.createdAt }
    }
    var body: some View {
        Group {
            if authenticated {
                List {
                    Section {
                        Picker("Kitchen", selection: $restaurant) {
                            Text("All restaurants").tag("all")
                            ForEach(SampleMenu.restaurants) { Text($0.name).tag($0.id) }
                        }
                        Picker("Orders", selection: $completed) {
                            Text("Active").tag(false)
                            Text("Completed").tag(true)
                        }.pickerStyle(.segmented)
                    }
                    ForEach(orders) { order in
                        Section {
                            HStack { Text("Order #\(order.number)").font(.headline); Spacer(); StatusLabel(status: order.status) }
                            LabeledContent("Restaurant", value: SampleMenu.restaurant(order.restaurantID)?.name ?? "Dining")
                            LabeledContent("Pickup code", value: order.pickupCode)
                            Text(order.createdAt, format: .dateTime.hour().minute()).font(.caption).foregroundStyle(.secondary)
                            ForEach(order.lines) { line in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(line.quantity) × \(line.name)").fontWeight(.medium)
                                    if !line.summary.isEmpty { Text(line.summary).font(.caption).foregroundStyle(.secondary) }
                                }
                            }
                            Text(order.pickup).font(.caption).foregroundStyle(.secondary)
                            LabeledContent("Simulated payment", value: order.totalCents.dollars)
                            if order.status != .completed {
                                Button(order.status.action, systemImage: "arrow.right") {
                                    do { try store.advance(order.id) } catch { self.error = error.localizedDescription }
                                }.fontWeight(.semibold)
                            }
                        }
                    }
                    if orders.isEmpty {
                        ContentUnavailableView("You’re all caught up.", systemImage: "checkmark.circle", description: Text("Orders placed on this device appear here."))
                    }
                    Section { Text("Local demo only. Status changes appear immediately in student order tracking. Other devices do not share this data.").font(.caption).foregroundStyle(.secondary) }
                }
            } else {
                Form {
                    Section {
                        Brand().padding(.vertical, 15)
                        Text("Welcome to the kitchen.").font(.title2.bold())
                        Text("Behind every good bite.").foregroundStyle(.secondary)
                        TextField("Demo staff code", text: $code).textInputAutocapitalization(.characters).autocorrectionDisabled()
                        Button("Enter demo kitchen", systemImage: "arrow.right") {
                            if code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "MUSTANG" { authenticated = true }
                            else { error = "Use the demo staff code MUSTANG." }
                        }
                    } footer: { Text("Code: MUSTANG. This local presentation gate is not secure staff authentication. No real orders are sent.") }
                }
            }
        }.navigationTitle("Demo kitchen").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
                if authenticated { ToolbarItem(placement: .topBarLeading) { Button("Sign out") { authenticated = false; code = "" } } }
            }
            .alert("Kitchen notice", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }
}
