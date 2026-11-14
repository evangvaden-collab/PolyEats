import XCTest
@testable import PolyEats

final class DiningStoreTests: XCTestCase {
    @MainActor
    func testCheckoutDeductsWalletAndCreatesOrderTogether() throws {
        let (store, defaults, suite) = makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }
        try store.add(CartItem(mealID: "burrito"))
        let id = try store.checkout(accessiblePickup: false)
        XCTAssertEqual(store.data.balanceCents, 14050)
        XCTAssertTrue(store.data.cart.isEmpty)
        XCTAssertEqual(store.data.orders.first?.id, id)
        XCTAssertEqual(store.data.transactions.first?.amountCents, -950)
        let reloaded = DiningStore(defaults: defaults)
        XCTAssertEqual(reloaded.data.orders.first?.id, id)
        XCTAssertEqual(reloaded.data.balanceCents, 14050)
    }

    @MainActor
    func testInsufficientFundsPreservesWalletAndCart() throws {
        let (store, defaults, suite) = makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }
        try store.add(CartItem(mealID: "burrito", quantity: 20))
        XCTAssertThrowsError(try store.checkout(accessiblePickup: false))
        XCTAssertEqual(store.data.balanceCents, 15000)
        XCTAssertEqual(store.data.cart.count, 1)
        XCTAssertTrue(store.data.orders.isEmpty)
        XCTAssertTrue(store.data.transactions.isEmpty)
    }

    @MainActor
    func testMixedRestaurantsAndUnavailableMealsAreRejected() throws {
        let (store, defaults, suite) = makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }
        try store.add(CartItem(mealID: "burrito"))
        XCTAssertThrowsError(try store.add(CartItem(mealID: "pizza")))
        XCTAssertThrowsError(try store.add(CartItem(mealID: "pasta")))
        XCTAssertThrowsError(try store.add(CartItem(mealID: "burrito", quantity: 0)))
        XCTAssertEqual(store.data.cart.count, 1)
    }

    func testCustomizationsUseIntegerCentsAndQuantity() {
        let item = CartItem(mealID: "burrito", quantity: 2, protein: .steak, extraIDs: ["guac", "cheese"])
        XCTAssertEqual(item.totalCents, 2650)
        XCTAssertEqual(item.estimatedCalories, 1790)
        XCTAssertEqual(item.estimatedProtein, 92)
    }

    @MainActor
    func testOrderProgressionAndReset() throws {
        let (store, defaults, suite) = makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }
        try store.add(CartItem(mealID: "burrito"))
        let id = try store.checkout(accessiblePickup: true)
        for status in [OrderStatus.preparing, .ready, .completed] {
            try store.advance(id)
            XCTAssertEqual(store.data.orders.first?.status, status)
        }
        XCTAssertTrue(store.data.orders.first?.pickup.contains("Accessible") == true)
        try store.advance(id)
        XCTAssertEqual(store.data.balanceCents, 14050)
        try store.reorder(store.data.orders[0])
        XCTAssertEqual(store.cartTotal, 950)
        try store.reset()
        XCTAssertEqual(store.data.balanceCents, 15000)
        XCTAssertTrue(store.data.orders.isEmpty)
        XCTAssertTrue(store.data.cart.isEmpty)
    }

    @MainActor
    private func makeStore() -> (DiningStore, UserDefaults, String) {
        let suite = "PolyEats.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return (DiningStore(defaults: defaults), defaults, suite)
    }
}
