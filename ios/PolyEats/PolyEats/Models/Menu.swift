import Foundation

struct Restaurant: Identifiable {
    let id: String
    let name: String
    let cuisine: String
    let tagline: String
    let symbol: String
    let pickup: String
}

struct Meal: Identifiable {
    let id: String
    let restaurantID: String
    let name: String
    let description: String
    let category: String
    let priceCents: Int
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let vegetarian: Bool
    var available = true
    var customizable = false
    let symbol: String
}

struct Extra: Identifiable {
    let id: String
    let name: String
    let priceCents: Int
    let calories: Int
    let protein: Int
}

enum SampleMenu {
    static let restaurants: [Restaurant] = [
        Restaurant(id: "streats", name: "Streats", cuisine: "Burritos & bowls", tagline: "Big flavors. Your way.", symbol: "takeoutbag.and.cup.and.straw.fill", pickup: "Streats demo pickup counter"),
        Restaurant(id: "hearth", name: "Hearth", cuisine: "Pizza & Italian", tagline: "Fresh from the oven.", symbol: "flame.fill", pickup: "Hearth demo pickup counter"),
        Restaurant(id: "polychoice", name: "PolyChoice", cuisine: "Bowls & comfort food", tagline: "A little something for everyone.", symbol: "fork.knife.circle.fill", pickup: "PolyChoice demo pickup counter"),
        Restaurant(id: "panda", name: "Panda Express", cuisine: "Chinese-inspired", tagline: "Your go-to, wok fresh.", symbol: "takeoutbag.and.cup.and.straw.fill", pickup: "Panda Express demo pickup counter"),
        Restaurant(id: "balance", name: "Balance Café", cuisine: "Salads & café", tagline: "Good food. Good energy.", symbol: "leaf.fill", pickup: "Balance Café demo pickup counter")
    ]
    static let meals: [Meal] = [
        Meal(id: "burrito", restaurantID: "streats", name: "Build your own burrito", description: "A warm tortilla, cilantro-lime rice, black beans, pico, and your choice of protein.", category: "Burritos & bowls", priceCents: 950, calories: 680, protein: 38, carbs: 82, fat: 22, vegetarian: false, customizable: true, symbol: "takeoutbag.and.cup.and.straw.fill"),
        Meal(id: "chicken-bowl", restaurantID: "streats", name: "Grilled chicken bowl", description: "Grilled chicken, brown rice, roasted corn, and salsa verde.", category: "Burritos & bowls", priceCents: 1050, calories: 560, protein: 44, carbs: 63, fat: 15, vegetarian: false, customizable: true, symbol: "fork.knife"),
        Meal(id: "veggie-bowl", restaurantID: "streats", name: "Roasted veggie bowl", description: "Seasonal vegetables, rice, black beans, and lime.", category: "Burritos & bowls", priceCents: 875, calories: 510, protein: 17, carbs: 72, fat: 18, vegetarian: true, customizable: true, symbol: "leaf.fill"),
        Meal(id: "chips", restaurantID: "streats", name: "Chips & fresh salsa", description: "Crisp tortilla chips with tomato salsa.", category: "Sides", priceCents: 325, calories: 270, protein: 4, carbs: 36, fat: 12, vegetarian: true, symbol: "sun.max.fill"),
        Meal(id: "pizza", restaurantID: "hearth", name: "Margherita pizza", description: "Tomato, mozzarella, basil, and a golden crust.", category: "Pizza", priceCents: 1100, calories: 720, protein: 28, carbs: 88, fat: 29, vegetarian: true, symbol: "flame.fill"),
        Meal(id: "pasta", restaurantID: "hearth", name: "Pesto pasta", description: "Penne with basil pesto, tomatoes, and parmesan.", category: "Pasta", priceCents: 975, calories: 630, protein: 20, carbs: 76, fat: 27, vegetarian: true, available: false, symbol: "fork.knife"),
        Meal(id: "harvest", restaurantID: "polychoice", name: "Harvest grain bowl", description: "Quinoa, sweet potatoes, greens, chickpeas, and tahini.", category: "Bowls", priceCents: 1000, calories: 540, protein: 21, carbs: 69, fat: 21, vegetarian: true, symbol: "carrot.fill"),
        Meal(id: "plate", restaurantID: "polychoice", name: "Grilled chicken plate", description: "Herb chicken, roasted vegetables, and brown rice.", category: "Plates", priceCents: 1150, calories: 590, protein: 48, carbs: 60, fat: 18, vegetarian: false, symbol: "fork.knife"),
        Meal(id: "orange", restaurantID: "panda", name: "Orange chicken bowl", description: "Crispy chicken in citrus sauce with steamed rice.", category: "Bowls", priceCents: 1095, calories: 820, protein: 30, carbs: 112, fat: 28, vegetarian: false, symbol: "takeoutbag.and.cup.and.straw.fill"),
        Meal(id: "tofu", restaurantID: "panda", name: "Vegetable noodle bowl", description: "Wok-tossed noodles with broccoli, cabbage, and tofu.", category: "Bowls", priceCents: 950, calories: 580, protein: 22, carbs: 78, fat: 20, vegetarian: true, symbol: "carrot.fill"),
        Meal(id: "salad", restaurantID: "balance", name: "Green goddess salad", description: "Greens, avocado, cucumber, quinoa, and herby dressing.", category: "Salads", priceCents: 1025, calories: 430, protein: 16, carbs: 34, fat: 26, vegetarian: true, symbol: "leaf.fill"),
        Meal(id: "power", restaurantID: "balance", name: "Chicken power salad", description: "Chicken, greens, edamame, quinoa, and lemon vinaigrette.", category: "Salads", priceCents: 1175, calories: 490, protein: 46, carbs: 32, fat: 19, vegetarian: false, symbol: "leaf.circle.fill")
    ]
    static let extras = [
        Extra(id: "guac", name: "Guacamole", priceCents: 150, calories: 90, protein: 1),
        Extra(id: "cheese", name: "Extra cheese", priceCents: 75, calories: 80, protein: 5),
        Extra(id: "salsa", name: "Extra salsa", priceCents: 0, calories: 10, protein: 0)
    ]
    static let ingredients = ["Rice", "Black beans", "Pico de gallo", "Lettuce"]
    static func meal(_ id: String) -> Meal? { meals.first { $0.id == id } }
    static func restaurant(_ id: String) -> Restaurant? { restaurants.first { $0.id == id } }
}

extension Int {
    var dollars: String { (Double(self) / 100).formatted(.currency(code: "USD")) }
}
