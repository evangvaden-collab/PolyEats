import SwiftUI

enum Theme {
    static let green = Color(red: 0.14, green: 0.30, blue: 0.22)
    static let sage = Color(red: 0.41, green: 0.51, blue: 0.34)
    static let cream = Color(red: 0.97, green: 0.98, blue: 0.95)
    static let soft = Color(red: 0.92, green: 0.94, blue: 0.88)
    static let gold = Color(red: 0.91, green: 0.74, blue: 0.34)
}

struct Brand: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "fork.knife").font(.subheadline.bold())
                .foregroundStyle(Theme.cream).padding(9)
                .background(Theme.green, in: RoundedRectangle(cornerRadius: 11))
            (Text("poly").fontWeight(.bold) + Text("eats").fontWeight(.regular) + Text(".").foregroundColor(Theme.gold))
                .font(.system(.title2, design: .rounded)).tracking(-1)
        }.foregroundStyle(Theme.green)
    }
}

struct DemoDisclaimer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Independent student-built prototype").fontWeight(.medium)
            Text("Not affiliated with Cal Poly. Menus, prices, pickup locations, and nutrition are demo data. All payments are simulated.")
        }.font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 16)
    }
}

struct FoodArtwork: View {
    let symbol: String
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.soft, Theme.sage.opacity(0.32)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Theme.cream.opacity(0.8)).frame(width: 100, height: 100)
            Circle().strokeBorder(Theme.gold.opacity(0.7), lineWidth: 2).frame(width: 112, height: 112)
            Image(systemName: symbol).font(.system(size: 40, weight: .light)).foregroundStyle(Theme.green)
        }.accessibilityHidden(true)
    }
}

struct StatusLabel: View {
    let status: OrderStatus
    var body: some View {
        Text(status.rawValue).font(.caption2.weight(.semibold))
            .foregroundStyle(status == .ready ? Theme.green : .secondary)
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(status == .preparing ? Theme.gold.opacity(0.22) : Theme.soft, in: Capsule())
    }
}

struct NutritionSummary: View {
    let calories: Int
    let protein: Int
    var body: some View {
        HStack(spacing: 12) {
            Label("\(calories) cal", systemImage: "flame")
            Label("\(protein)g protein", systemImage: "bolt")
            Text("est.").foregroundStyle(.secondary)
        }.font(.caption).foregroundStyle(Theme.sage)
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.soft, in: RoundedRectangle(cornerRadius: 10))
    }
}
