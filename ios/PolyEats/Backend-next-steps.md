# Backend migration, when needed

The native app is intentionally a working local demo. Supabase is not connected; adding a URL/key alone will not enable cross-device synchronization.

For a remote version, add the official Supabase Swift package using Xcode's Package Dependencies. Use a public project URL and anon/publishable key, never a service-role key in the app. Authenticate students/staff with Supabase Auth. Replace the demo code with server-verified staff membership.

Equivalent database models:

- profiles (auth user ID, name, role)
- restaurants and menu_categories
- menu_items (restaurant/category FKs, price_cents, availability, verified or estimated nutrient source)
- item_customizations (menu item FK, group, price/nutrition deltas)
- wallets (user FK, nonnegative integer balance_cents)
- orders (user/restaurant FKs, constrained status, total_cents, pickup snapshot, idempotency key)
- order_items (order/menu FKs, quantity, price/name/customization snapshots)
- wallet_transactions (user/order FKs, signed integer amount_cents)
- favorites and staff_restaurants relationships

Implement checkout as a PostgreSQL transaction/RPC: authenticate the caller, validate items and customizations using authoritative database prices, enforce one restaurant, lock the wallet row, check funds, insert order/items, deduct funds, insert the wallet debit, and commit together. Use a unique idempotency key to prevent duplicate orders on retries. Any failure must roll back the entire transaction. Do not accept client-supplied wallet balances, prices, roles, or order status.

Enable RLS on every table. Students read their own wallet/orders and cannot edit wallet balances or statuses. Staff see only assigned restaurants. A server RPC enforces ordered status transitions and staff membership. Subscribe to authorized order changes with Supabase Realtime, refetch after reconnects, and isolate local demo data from remote data.

Test two student accounts, unauthorized staff, simultaneous checkouts, duplicate requests, insufficient funds, offline retries, and subscription reconnects before enabling a shared demo. Official menus, nutritional/allergen data, pickup locations, campus approval, and a separately secured payment integration are needed before real use.
