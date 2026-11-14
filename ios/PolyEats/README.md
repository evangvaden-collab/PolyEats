# PolyEats for iOS

A native **Swift / SwiftUI** campus dining demo for iPhone and iPad. No web view, JavaScript, package dependencies, or API keys. Built around a simple home screen and an optional complete local ordering demo.

## Open in Xcode

1. Unzip this folder on your Mac.
2. Open **PolyEats.xcodeproj**.
3. Use **Xcode 16 or later**, select the **PolyEats** scheme, and choose an **iPhone simulator running iOS 17 or later**.
4. Press **Command-R** to build and run. A simulator does not require an Apple developer account or signing team.
5. To run on your physical iPhone, select the app target → Signing & Capabilities → choose your development team and a unique bundle identifier.

The deployment target is iOS 17. The app uses Observation (`@Observable`) and SwiftUI's environment to share one store across screens. The project uses Swift 5 language mode for broad Xcode compatibility.

**Verification limit:** This project was created in a Linux environment without Swift, Xcode, or an iOS Simulator. Its source syntax, project references, scheme XML, and asset JSON were checked, but it has not been compiled, tested, or visually run in Xcode. The included XCTest tests must be run on your Mac. No claim of a successful Xcode build is made.

## Start with the home screen

`Views/HomeView.swift` contains the home screen: PolyEats branding, simulated Dining Dollars, a welcome card, campus dining spots, search, nutrition filters, and an active-order shortcut. `Views/Theme.swift` contains shared colors and small reusable views. Native SF Symbols provide lightweight artwork without remote images or downloads.

Important organization:

- `PolyEatsApp.swift`: application entry point; creates and shares the store.
- `Models/Menu.swift`: sample restaurants, menu categories, items, extras, integer-cent money formatting.
- `Models/DiningStore.swift`: cart, wallet, order models, validation, and local persistence.
- `Views/ContentView.swift`: Explore, Orders, Favorites, Account tabs and bag shortcut.
- `Views/HomeView.swift`: home screen and restaurant cards.
- `Views/MenuViews.swift`: restaurant menu, macros, favorites, and customization.
- `Views/OrderViews.swift`: cart, checkout, order history, and tracking.
- `Views/AccountViews.swift`: profile, wallet activity, reset, and local kitchen.
- `PolyEatsTests/DiningStoreTests.swift`: checkout, insufficient funds, invalid cart, pricing, persistence, status progression, reorder, and reset tests.

The store is main-actor isolated. Checkout creates the order, deducts the wallet, records a transaction, and empties the cart in one encoded local state update. This avoids partial application-level updates; UserDefaults is local demo storage, not a transactional production database. Order lines snapshot names, paid prices, and customizations. Reorders use current menu prices. SwiftUI observes store changes so the kitchen and student screens always share current state on the same device.

## Try the demo

1. Explore → **Streats** → **Build your own burrito**.
2. Select protein, extras, ingredient removals, quantity, and instructions. Price and estimated nutrition update.
3. Add to bag, then use **View bag** above the tab bar.
4. Place a demo order using the initial **$150 simulated balance**.
5. On the tracking screen, select **Open demo kitchen**. Enter **MUSTANG**.
6. Advance the order through Preparing → Ready for pickup → Completed.
7. Tap Done to return to tracking; the new status is already reflected.
8. Account shows simulated wallet transactions. Orders offers reorder for completed meals. Account → Reset demo data starts fresh after confirmation.

The staff code is a presentation gate, **not secure authentication**. The kitchen is a native screen, not a `/kitchen` web route. This version does not sync between devices, app installations, or the earlier web scaffold. Data persists on this device across launches. Deleting the app clears its local data.

## Nutrition and demo boundaries

All menus, prices, nutrition, availability, and pickup locations are illustrative sample data, not verified or current Cal Poly information. The app is an independent student-built prototype, not affiliated with Cal Poly or its vendors. No real payments, Dining Dollars, PolyCard integration, food preparation, or campus kitchen connection occurs.

Calories/protein are estimates. Customizable items use demo protein/extra deltas; removing ingredients can lower totals, so the displayed totals remain upper estimates. Expanded carbs/fat are for the standard meal. No allergy safety claims are made. There are no verified savings claims. Optional AI recommendations are deferred.

## Build and tests on your Mac

In Xcode, **Command-B** builds, and **Command-U** runs the included tests. Or, from this folder:

```sh
xcodebuild -project PolyEats.xcodeproj -scheme PolyEats \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build

# Replace the simulator name with one installed on your Mac.
xcodebuild -project PolyEats.xcodeproj -scheme PolyEats \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Check Dynamic Type, VoiceOver, dark appearance, iPhone/iPad layouts, keyboard behavior, persistence after relaunch, and the complete ordering demo in Simulator. The prototype intentionally uses a light appearance for its current visual design.

## Next steps

First verify the Xcode build and refine the home screen on your simulator. Then migrate persistence to an authenticated backend if you need two-device student/kitchen demos. Keep the current SwiftUI screens and replace the `DiningStore` persistence boundary with explicit async repository methods. See `Backend-next-steps.md`. Real payment integration, authoritative menus/nutrition, staff authorization, and operational review are prerequisites for real-world use.
