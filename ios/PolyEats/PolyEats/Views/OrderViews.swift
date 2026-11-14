import SwiftUI

struct CartView: View {
    @Environment(DiningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var accessiblePickup = false
    @State private var error: String?
    @State private var confirmedOrder: UUID?

    var body: some View {
        Group {
            if let confirmedOrder {
                OrderDetailView(orderID: confirmedOrder)
            } else if store.data.cart.isEmpty {
                ContentUnavailableView("A little empty in here.", systemImage: "bag", description: Text("Find something that hits the spot."))
            } else {
                List {
                    Section {
                        ForEach(store.data.cart) { item in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(item.meal?.name ?? "Meal").font(.headline)
                                    Spacer()
                                    Text(item.totalCents.dollars).font(.subheadline.bold())
                                }
                                if !item.customizationSummary.isEmpty { Text(item.customizationSummary).font(.caption).foregroundStyle(.secondary) }
                                Stepper("Quantity: \(item.quantity)", value: Binding(get: { item.quantity }, set: { quantity in
                                    do { try store.changeQuantity(item.id, to: quantity) } catch { self.error = error.localizedDescription }
                                }), in: 1...20).font(.subheadline)
                                Button("Remove", role: .destructive) {
                                    do { try store.remove(item.id) } catch { self.error = error.localizedDescription }
                                }.font(.caption)
                            }.padding(.vertical, 6)
                        }
                    } header: { Text(SampleMenu.restaurant(store.data.cart.first?.meal?.restaurantID ?? "")?.name ?? "Your meal") }
                    Section {
                        NutritionSummary(calories: store.cartCalories, protein: store.cartProtein)
                        Text("Demo estimates. Ingredient removals may reduce totals.").font(.caption).foregroundStyle(.secondary)
                        Toggle("Accessible pickup handoff", isOn: $accessiblePickup)
                    } header: { Text("Your pickup") }
                    Section {
                        LabeledContent("Subtotal", value: store.cartTotal.dollars)
                        LabeledContent("Demo service fee", value: 0.dollars)
                        LabeledContent("Total", value: store.cartTotal.dollars).bold()
                        LabeledContent("Simulated balance", value: store.data.balanceCents.dollars)
                        Button {
                            do { confirmedOrder = try store.checkout(accessiblePickup: accessiblePickup) }
                            catch { self.error = error.localizedDescription }
                        } label: { Text("Place demo order · \(store.cartTotal.dollars)").fontWeight(.semibold) }
                            .disabled(store.cartTotal > store.data.balanceCents)
                        if store.cartTotal > store.data.balanceCents {
                            Text("Insufficient simulated funds. Remove items or reset your demo in Account.").font(.caption).foregroundStyle(.red)
                        }
                    } footer: { Text("No real payment. Order and wallet are saved together on this device.") }
                    Section {
                        Button("Clear bag", role: .destructive) {
                            do { try store.clearCart() } catch { self.error = error.localizedDescription }
                        }
                    }
                }
            }
        }.navigationTitle(confirmedOrder == nil ? "Your bag" : "Order confirmed").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .alert("Couldn’t update order", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }
}

struct OrdersView: View {
    @Environment(DiningStore.self) private var store
    var body: some View {
        List {
            if store.data.orders.isEmpty {
                ContentUnavailableView("Your next favorite is waiting.", systemImage: "receipt", description: Text("Your orders will appear here."))
            } else {
                Section("In the kitchen") {
                    ForEach(store.activeOrders) { OrderRow(order: $0) }
                    if store.activeOrders.isEmpty { Text("No active orders.").foregroundStyle(.secondary) }
                }
                Section("Previously enjoyed") {
                    ForEach(store.data.orders.filter { $0.status == .completed }) { OrderRow(order: $0) }
                }
            }
        }.navigationTitle("Your orders")
    }
}

struct OrderRow: View {
    let order: DiningOrder
    var body: some View {
        NavigationLink { OrderDetailView(orderID: order.id) } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(SampleMenu.restaurant(order.restaurantID)?.name ?? "Dining").font(.headline)
                    Spacer()
                    StatusLabel(status: order.status)
                }
                Text("Order #\(order.number) · \(order.totalCents.dollars)").font(.subheadline)
                Text(order.createdAt, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(.secondary)
            }.padding(.vertical, 5)
        }
    }
}

struct OrderDetailView: View {
    @Environment(DiningStore.self) private var store
    let orderID: UUID
    @State private var error: String?
    @State private var showingKitchen = false
    @State private var showingBag = false
    private var order: DiningOrder? { store.data.orders.first { $0.id == orderID } }

    var body: some View {
        Group {
            if let order {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(order.status == .ready ? "Your next bite is ready!" : order.status == .completed ? "Hope that hit the spot." : "Good things are coming.").font(.title2.bold())
                            Text(SampleMenu.restaurant(order.restaurantID)?.name ?? "Dining").foregroundStyle(.secondary)
                            StatusLabel(status: order.status)
                        }.padding(.vertical, 10)
                        ForEach(OrderStatus.allCases) { status in
                            Label(status.rawValue, systemImage: status.index <= order.status.index ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(status.index <= order.status.index ? Theme.green : .secondary)
                        }
                    }
                    Section("Your pickup") {
                        Text(order.pickupCode).font(.system(size: 38, weight: .semibold, design: .monospaced)).tracking(6)
                        Text(order.pickup).font(.subheadline)
                        Text("Show this code at the demo counter. No guaranteed preparation time.").font(.caption).foregroundStyle(.secondary)
                    }
                    Section("What’s in your bag") {
                        ForEach(order.lines) { line in
                            VStack(alignment: .leading, spacing: 6) {
                                LabeledContent("\(line.quantity) × \(line.name)", value: line.totalCents.dollars)
                                if !line.summary.isEmpty { Text(line.summary).font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                        LabeledContent("Simulated payment", value: order.totalCents.dollars).bold()
                        NutritionSummary(calories: order.calories, protein: order.protein)
                    }
                    Section {
                        Button("Open demo kitchen", systemImage: "frying.pan") { showingKitchen = true }
                        if order.status == .completed {
                            Button("Reorder at current prices", systemImage: "arrow.clockwise") {
                                do { try store.reorder(order); showingBag = true } catch { self.error = error.localizedDescription }
                            }
                        }
                    } footer: { Text("The kitchen and student screens share local data on this device. No cross-device synchronization in this version.") }
                }
            } else {
                ContentUnavailableView("Order not found", systemImage: "receipt", description: Text("The demo may have been reset."))
            }
        }.navigationTitle("Order #\(order?.number ?? 0)").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingKitchen) { NavigationStack { KitchenView() } }
            .sheet(isPresented: $showingBag) { NavigationStack { CartView() } }
            .alert("Couldn’t reorder", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }
}
