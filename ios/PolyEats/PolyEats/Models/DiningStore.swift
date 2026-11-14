import Foundation
import Observation

enum Protein: String, Codable, CaseIterable, Identifiable {
    case chicken = "Grilled chicken", steak = "Grilled steak", beans = "Extra black beans"
    var id: String { rawValue }
    var priceCents: Int { self == .steak ? 150 : 0 }
}

struct CartItem: Identifiable, Codable {
    var id = UUID()
    let mealID: String
    var quantity = 1
    var protein: Protein = .chicken
    var extraIDs: Set<String> = []
    var removedIngredients: Set<String> = []
    var instructions = ""
    var meal: Meal? { SampleMenu.meal(mealID) }
    var selectedExtras: [Extra] { SampleMenu.extras.filter { extraIDs.contains($0.id) } }
    var unitPriceCents: Int {
        guard let meal else { return 0 }
        return meal.priceCents + (meal.customizable ? protein.priceCents + selectedExtras.reduce(0) { $0 + $1.priceCents } : 0)
    }
    var totalCents: Int { unitPriceCents * quantity }
    var estimatedCalories: Int {
        guard let meal else { return 0 }
        let delta = protein == .steak ? 45 : protein == .beans && !meal.vegetarian ? -70 : 0
        return (meal.calories + (meal.customizable ? delta + selectedExtras.reduce(0) { $0 + $1.calories } : 0)) * quantity
    }
    var estimatedProtein: Int {
        guard let meal else { return 0 }
        let delta = protein == .steak ? 2 : protein == .beans && !meal.vegetarian ? -16 : 0
        return (meal.protein + (meal.customizable ? delta + selectedExtras.reduce(0) { $0 + $1.protein } : 0)) * quantity
    }
    var customizationSummary: String {
        var parts: [String] = []
        if meal?.customizable == true {
            parts.append(protein.rawValue)
            parts += selectedExtras.map(\.name)
            parts += removedIngredients.sorted().map { "No \($0)" }
        }
        if !instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { parts.append(instructions) }
        return parts.joined(separator: " · ")
    }
}

enum OrderStatus: String, Codable, CaseIterable, Identifiable {
    case placed = "Order placed", preparing = "Preparing", ready = "Ready for pickup", completed = "Completed"
    var id: String { rawValue }
    var index: Int { Self.allCases.firstIndex(of: self) ?? 0 }
    var next: Self? { index < Self.allCases.count - 1 ? Self.allCases[index + 1] : nil }
    var action: String {
        switch self {
        case .placed: "Start preparing"
        case .preparing: "Mark ready for pickup"
        case .ready: "Complete order"
        case .completed: "Completed"
        }
    }
}

struct OrderLine: Identifiable, Codable {
    let id: UUID
    let name: String
    let quantity: Int
    let unitPriceCents: Int
    let summary: String
    let original: CartItem
    var totalCents: Int { unitPriceCents * quantity }
}

struct DiningOrder: Identifiable, Codable {
    let id: UUID
    let number: Int
    let restaurantID: String
    let lines: [OrderLine]
    let totalCents: Int
    let calories: Int
    let protein: Int
    let createdAt: Date
    let pickup: String
    var status: OrderStatus = .placed
    var pickupCode: String { String(id.uuidString.suffix(4)) }
}

struct WalletTransaction: Identifiable, Codable {
    let id: UUID
    let orderNumber: Int
    let amountCents: Int
    let date: Date
}

struct DemoData: Codable {
    var balanceCents = 15_000
    var cart: [CartItem] = []
    var orders: [DiningOrder] = []
    var transactions: [WalletTransaction] = []
    var favoriteRestaurants: Set<String> = []
    var favoriteMeals: Set<String> = []
}

struct DiningError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// One main-actor store owns the local demo. Orders and wallet changes are saved together.
/// Replace this persistence boundary with authenticated database RPCs for cross-device use.
@MainActor @Observable
final class DiningStore {
    private(set) var data: DemoData
    private(set) var persistenceWarning: String?
    private let defaults: UserDefaults
    private let key = "polyeats.native.demo.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let saved = defaults.data(forKey: key) {
            do { data = try JSONDecoder().decode(DemoData.self, from: saved) }
            catch {
                data = DemoData()
                persistenceWarning = "Saved demo data could not be read. The original data is retained until you reset the demo."
            }
        } else { data = DemoData() }
    }

    var cartTotal: Int { data.cart.reduce(0) { $0 + $1.totalCents } }
    var cartCalories: Int { data.cart.reduce(0) { $0 + $1.estimatedCalories } }
    var cartProtein: Int { data.cart.reduce(0) { $0 + $1.estimatedProtein } }
    var cartCount: Int { data.cart.reduce(0) { $0 + $1.quantity } }
    var activeOrders: [DiningOrder] { data.orders.filter { $0.status != .completed } }

    private func save(_ next: DemoData) throws {
        guard persistenceWarning == nil else { throw DiningError(message: "Reset the demo in Account before changing unreadable saved data.") }
        let encoded = try JSONEncoder().encode(next)
        defaults.set(encoded, forKey: key)
        data = next
    }

    func add(_ item: CartItem) throws {
        guard let meal = item.meal, meal.available, (1...20).contains(item.quantity) else {
            throw DiningError(message: "This item is unavailable or its quantity is invalid.")
        }
        if let first = data.cart.first?.meal, first.restaurantID != meal.restaurantID {
            throw DiningError(message: "Please finish or clear your current bag before ordering from another restaurant.")
        }
        var next = data
        next.cart.append(item)
        try save(next)
    }

    func changeQuantity(_ id: UUID, to quantity: Int) throws {
        guard (1...20).contains(quantity), let index = data.cart.firstIndex(where: { $0.id == id }) else { return }
        var next = data
        next.cart[index].quantity = quantity
        try save(next)
    }

    func remove(_ id: UUID) throws {
        var next = data
        next.cart.removeAll { $0.id == id }
        try save(next)
    }

    func clearCart() throws {
        var next = data
        next.cart = []
        try save(next)
    }

    @discardableResult
    func checkout(accessiblePickup: Bool) throws -> UUID {
        guard let first = data.cart.first?.meal else { throw DiningError(message: "Your bag is empty.") }
        guard data.cart.allSatisfy({ $0.meal?.available == true && $0.meal?.restaurantID == first.restaurantID && (1...20).contains($0.quantity) }) else {
            throw DiningError(message: "Please update your bag. An item is unavailable or belongs to another restaurant.")
        }
        guard cartTotal <= data.balanceCents else { throw DiningError(message: "Not enough simulated Dining Dollars. Remove an item or reset the demo in Account.") }
        let id = UUID()
        let now = Date()
        let number = 1001 + data.orders.count
        let total = cartTotal
        let lines = data.cart.map { item in
            OrderLine(id: item.id, name: item.meal?.name ?? "Meal", quantity: item.quantity, unitPriceCents: item.unitPriceCents, summary: item.customizationSummary, original: item)
        }
        let pickup = (SampleMenu.restaurant(first.restaurantID)?.pickup ?? "Demo pickup counter") + (accessiblePickup ? " · Accessible handoff requested" : "")
        let order = DiningOrder(id: id, number: number, restaurantID: first.restaurantID, lines: lines, totalCents: total, calories: cartCalories, protein: cartProtein, createdAt: now, pickup: pickup)
        var next = data
        next.balanceCents -= total
        next.orders.insert(order, at: 0)
        next.transactions.insert(WalletTransaction(id: UUID(), orderNumber: number, amountCents: -total, date: now), at: 0)
        next.cart = []
        try save(next)
        return id
    }

    func advance(_ id: UUID) throws {
        guard let index = data.orders.firstIndex(where: { $0.id == id }), let status = data.orders[index].status.next else { return }
        var next = data
        next.orders[index].status = status
        try save(next)
    }

    func reorder(_ order: DiningOrder) throws {
        guard data.cart.isEmpty else { throw DiningError(message: "Finish or clear your current bag before reordering.") }
        guard order.lines.allSatisfy({ $0.original.meal?.available == true }) else { throw DiningError(message: "An item in this order is currently unavailable.") }
        var next = data
        next.cart = order.lines.map { line in
            var item = line.original
            item.id = UUID()
            return item
        }
        try save(next)
    }

    func toggleFavorite(_ id: String, meal: Bool = false) throws {
        var next = data
        if meal {
            if next.favoriteMeals.contains(id) { next.favoriteMeals.remove(id) } else { next.favoriteMeals.insert(id) }
        } else {
            if next.favoriteRestaurants.contains(id) { next.favoriteRestaurants.remove(id) } else { next.favoriteRestaurants.insert(id) }
        }
        try save(next)
    }

    func reset() throws {
        let encoded = try JSONEncoder().encode(DemoData())
        defaults.set(encoded, forKey: key)
        persistenceWarning = nil
        data = DemoData()
    }
}
