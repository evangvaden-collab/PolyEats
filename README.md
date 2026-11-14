# PolyEats

Shared team repository for the PolyEats campus dining prototype.

Contribute changes on a separate branch and open a pull request into `main` so teammates can review them before merging.

## Native iOS prototype

The Swift/SwiftUI app lives in [`ios/PolyEats`](ios/PolyEats/README.md), separate from any future web or backend code.

1. Clone or download this repository on a Mac.
2. Open `ios/PolyEats/PolyEats.xcodeproj` in Xcode 16 or later.
3. Choose the **PolyEats** scheme and an iPhone simulator running iOS 17 or later.
4. Press **Command-R** to build/run or **Command-U** to run tests.

The app includes a home screen, sample menus, customization, cart, a simulated wallet, order tracking, and a local demo kitchen. All payments and campus data are simulated. The student and kitchen screens share local data on one device; there is no cross-device backend yet. Demo kitchen code: **MUSTANG** (not secure authentication).

An iOS GitHub Actions workflow builds the app and runs tests on a macOS runner. Source syntax and project configuration were checked in the development environment; an Xcode build has not been verified locally. Check the workflow result before merging.

This is an independent student-built prototype, not affiliated with Cal Poly.
