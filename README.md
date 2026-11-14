# PolyEats

An independent student-built Cal Poly campus dining prototype. Next.js App Router, TypeScript, Tailwind CSS, shadcn-style Button (Radix Slot/CVA), and Lucide icons. All sample prices and nutrition are illustrative, not official. No university systems or real payments are connected.

## Run

Node 20.9+ and npm:

```sh
npm ci
npm run dev
# http://localhost:3000
npm test
npm run typecheck
npm run build
```

`next.config.ts` exports static files to `out/`. Deploy on Vercel as a Next.js static export or serve `out/` with any static host. No API keys required. Sites hosting configuration is in `.openai/hosting.json`; replace/remove the project identity before hosting elsewhere.

## Demo walkthrough

1. Open the student view at `/`. Alex Johnson starts with **$150 simulated Dining Dollars**.
2. Select Streats, then Build your own burrito. Choose protein, included ingredients, optional extras, quantity, and instructions. Price updates immediately; customized nutrition is explicitly unverified.
3. Add to the bag. Adjust quantities or remove items, review estimated base nutrition, select the restaurant pickup counter, and place a demo order.
4. The confirmation displays an order number, pickup code, items, total and status. Checkout checks funds, snapshots items, deducts the balance, records a wallet transaction and clears the bag in one local storage update. Browser Web Locks serialize checkout across tabs where supported.
5. Open `/kitchen/` **in another tab of the same browser and origin**, not incognito. Enter **POLY2026**. Filter by restaurant, start preparing, mark ready and complete the order. The student tracking panel updates via the storage event without refreshing.
6. Review orders, reorder, save restaurants/meals, and view wallet activity in the AJ account. Reset demo data from the account to restore $150 and clear all records. Reset affects every tab on the same origin.

All five demo restaurants are available. Search matches foods, descriptions and restaurant names. Filters use listed sample values: protein ≥35g, calories <600, price <$10, or vegetarian. Favorites, bag, wallet, transactions and orders persist after reload in `polyeats-demo-v1` localStorage. A bag contains one restaurant at a time. Local mode has one shared demo student, and synchronizes only within the same browser profile. There is no cross-device synchronization in local mode. Web Locks are not supported in every browser; browsers without them have a single-tab atomic write but no cross-tab serialization guarantee.

## Supabase upgrade path

No Supabase project was provided, so this build intentionally uses local demo mode. Merely adding credentials does not switch storage backends. `supabase/schema.sql` provides a normalized starting schema with users, restaurants, categories, menu items, customization options, wallets, transactions, orders and order items. It enables restrictive RLS and includes an atomic checkout RPC. It is a starting point for backend integration, not an already-connected backend.

1. Create a Supabase project and run the schema in the SQL editor; seed the menu from `lib/data.ts` and assign stable UUIDs. The catalog has price/nutrition snapshots; customization options belong to a menu item.
2. Add `@supabase/supabase-js`; create a client with `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in `.env.local` or Vercel environment settings. Never expose a service-role key to the client.
3. Replace `read`/`transact` in `lib/store.ts` behind a repository interface with authenticated queries. Use Supabase Auth, provision a wallet on account creation on a trusted server, and map users to `auth.uid()`.
4. Call the `place_order` RPC for checkout rather than client-side balance writes. It locks the wallet row, validates catalog prices and selected paid options, snapshots order lines and debits the wallet in one database transaction. Extend it for ingredient removals, free choices, taxes and real availability rules before launch.
5. Implement staff roles with trusted membership and restaurant scope. Add staff-only order read/update RLS policies (the included defaults intentionally do not grant staff access). The visible demo PIN is not authentication.
6. Enable Realtime for `orders` in the Supabase dashboard; subscribe to authenticated order changes and re-fetch authorized records. Students must only read their orders; staff only their assigned restaurants. Add idempotency keys and retry handling for checkout before production.

## What works

Student search and menu browsing, estimated nutrition and filters, customization, single-restaurant cart, simulated wallet checks/deductions, order creation and pickup code, cross-tab kitchen updates, staff demo gate, order history/reordering, favorites, wallet history and reset.

## What is simulated / limitations

All data, wallet funds, pickup counters and menus are demo data. There are no real payments, Dining Dollars/PolyCard integrations, official preparation times, official nutrition, or verified allergy claims. The demo kitchen code is publicly visible and provides no security. Local storage is editable by the visitor and can be cleared by the browser. It must never hold real financial data. Nutrition totals use base items; customization changes values without pretending to know exact ingredient nutrition.

Food photographs use Unsplash's image CDN (Unsplash License); they illustrate sample meals and are not photographs of Cal Poly dining products. Network access is needed for these external images. No analytics are installed.

## Before real-world use

Priorities: (1) authenticated Supabase persistence, scoped staff authorization and Realtime; (2) server-authoritative pricing, wallet transaction security, idempotent checkout and audit logs; (3) approved campus menus, verified nutrition and dietary metadata; (4) campus payment/POS integration under university approval; (5) accessibility and real-device QA, monitoring, order cancellation/refunds and operational readiness. Cost savings are a business hypothesis, not a verified claim.

## Verification

`npm test` covers checkout deductions, item snapshots, empty and insufficient-funds rejection, and restaurant restrictions. `npm run build` checks the production export and TypeScript. Browser visual and multi-tab end-to-end QA must still be performed; the supplied execution environment did not expose the supported browser QA tool.

## GitHub source repository

Source is mirrored to https://github.com/evangvaden-collab/PolyEats.

In the original workspace, `origin` remains the Sites source remote so the publishing connection is preserved; `github` is the GitHub remote. To push future reviewed commits from this workspace:

```sh
git status
git diff --cached
git push github main
```

A fresh clone from GitHub uses GitHub as `origin` normally. Authenticate on your own computer with `gh auth login` followed by `gh auth setup-git`, or use your existing SSH configuration. Never put a personal access token in the remote URL, source files, or commits. Do not force-push. Fetch and inspect any new remote commits before reconciling divergent history.

`.gitignore` excludes environment files, private keys, common credential files, local databases, generated output, dependency folders and local hosting state. `.openai/hosting.json` is intentionally tracked deployment metadata, not a credential. Always inspect staged changes before committing; ignore rules do not protect secrets already tracked. The demo staff code is intentionally public and must not be used for production access.
