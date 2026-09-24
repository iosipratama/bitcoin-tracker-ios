# Sato — Claude Context

## What this app is

A minimalist, read-only Bitcoin wallet tracker for iPhone. Users create named wallets, add public Bitcoin addresses, and track BTC balance and optional fiat equivalent. Each wallet holds one or more on-chain addresses. No private keys. No transactions. No trading.

The app fetches live balances and price and displays them — nothing else.

**Core philosophy:** help people stack sats and *not* get shaken by volatility. The UI should feel calm, grounded, and intentional — not like a trading terminal.

The App Store name is "Sato: BTC Portfolio Tracker" from 1.1 (1.0 shipped as "Sato - Bitcoin Tracker"); names stop at 30 characters. The display name is Sato. The Xcode target, project folder, and bundle ID (`com.iosipratama.BitcoinTracker`) all still say Bitcoin Tracker. The bundle ID is registered with App Store Connect and must never change.


### ideal users
long-term Bitcoin holder. someone who bought and isn't selling. They don't want to trade, they don't watch the price obsessively, and they're actively turned off by the anxiety-inducing UI of most crypto apps. They probably keep their BTC in cold storage and just want a calm, occasional check-in.

- The quiet HODLer — has held for years, doesn't talk about it much, values privacy and restraint. The iA Writer aesthetic resonates because they think of Bitcoin more like a savings account than a speculative asset.
- The privacy-conscious user — appreciates that there's no account, no backend, no data leaving their phone. The read-only, address-paste model feels right to them.
- The minimalist / indie software person — uses apps like Things, iA Writer, Reeder. Has high standards for native iOS design and immediately uninstalls anything that feels bloated or gamified.
- The gift recipient / new holder — someone whose partner or friend convinced them to buy some Bitcoin. They're not deep in crypto culture and would be alienated by a typical exchange app. This one feels approachable and unintimidating.


### Screens
- Welcome — nine lines of copy shown once, before any balance appears
- Home — list of wallets
- Wallet Detail — wallet name, aggregated balance, list of addresses with individual balances
- Add Wallet — a single flow covering the name, the first address, and its preview
- Wallet Customizer — symbol and accent colour for a wallet
- Settings — fiat currency selector, fiat show/hide, satoshi toggle, flip-to-hide, Face ID lock, hide in app switcher, theme (Automatic / Light / Dark), support links, API attribution, restore purchase
- Paywall — the one purchase, reachable only when adding a second wallet (Settings has Restore Purchase, not the paywall)
- Debug — DEBUG-only toggles (fake unlock, force paywall, force empty state)

## Architecture

- **SwiftUI + SwiftData** (no UIKit, no third-party dependencies)
- **Platform:** iPhone only (`TARGETED_DEVICE_FAMILY = 1`), iOS 18 and later. There is no iPad adaptation anywhere — no size classes, no width clamps — so adding iPad means real layout work, not just a build setting.
- **Models:** `Wallet` (name, createdAt, optional symbol/accent raw strings, cascade → addresses, `freeLimit`) and `BitcoinAddress` (address, `balanceSatoshis`, `pendingSatoshis`, lastUpdated, fetchError). Supporting value types: `AddressBalance`, `Quote`, `FiatCurrency` (29 currencies), `WalletSymbol`, `WalletAccent`, `AppTheme`, `SupportLinks`, `SupportEnvironment`
- **Services:**
  - `BitcoinAPIService` — `actor`; fetches on-chain balance from Esplora-compatible explorers, mempool.space first, then mempool.emzy.de and blockstream.info as fallbacks
  - `PriceService` — `actor`; fetches BTC price via CoinGecko, 60-second in-memory cache
  - `StoreManager` — `@Observable @MainActor`; the only file that imports StoreKit. One non-consumable (`…​.plus`) lifts the wallet limit
  - `AppLock` — `@Observable @MainActor`; Face ID (device owner authentication) on launch and return from background, plus the app-switcher cover. `PrivacyCover` draws both in its own alert-level `UIWindow` so it sits above sheets
  - `ReviewPrompt` — decides whether the app has earned the right to ask for a review
- **ViewModel:** `PortfolioViewModel` drives the home screen
- **Views:** `RootView`, `WelcomeView`, `HomeView`, `WalletDetailView`, `AddWalletFlow`, `AddAddressView`, `WalletCustomizer`, `SettingsView`, `PaywallView`, `DebugView`
- **Helpers:** `WalletCard`, `AnimatingNumber`, `ProminentCapsuleButton`, `SettingsRow`, `StaleStamp`
- **Extensions:** `Color+Extensions` (adaptive palette — every token carries a light and a dark value via `Color(light:dark:)` — plus `cardRadius`/`rowRadius`), `Font+Extensions`, `Double+Bitcoin`

## Purchases

One non-consumable, "Sato Plus". `Wallet.freeLimit` is 1, so the paywall appears when adding a second wallet. Keep `StoreManager` as the only StoreKit surface: everything else asks `isUnlocked` or `canAddWallet(existing:)`. Any claim about how many wallets are free appears in three places that must agree — `Wallet.freeLimit`, the App Store description, and the in-app purchase description in `appStoreConnect/`.

## App Store Connect

The listing lives in `appStoreConnect/` and syncs through Bitrig. Edit those files, never the App Store Connect website — web edits surface as conflicts. Screenshot images under `assets/` are gitignored; only the manifests are committed. Sato Plus is manually priced in 26 territories by purchasing power, so the amounts don't track exchange rates and want a review once a year.


## Key conventions

- Internal balances are always **satoshis** (`Int64`); convert to BTC only at display time
- `shortAddress` truncates to `first6...last6`
- Prefer editing existing files over creating new ones
- No comments unless the WHY is non-obvious
- No third-party packages — keep it dependency-free
- iOS 26 is the reference design; iOS 18 is the floor because it runs on the same iPhones as iOS 17 (XR/XS and later), so going lower gains no devices. iOS 26 APIs (Liquid Glass, scroll edge effects) go behind `#available(iOS 26.0, *)` with a plain iOS 18 fallback that keeps the colour roles, e.g. `softScrollEdge(for:)` and `SheetConfirmButton`


### Design principles
- Two themes, one design. Dark came first and sets the structure: page is the deepest surface, cards lift off it, the inset panel drops back to the page tone. Light inverts the direction (paper page `F4F3F0`, white cards, paper inset) but keeps the structure.
- Theme is a setting (`PortfolioViewModel.theme`, default Automatic) applied once via `preferredColorScheme` at the app root. Never hard-code `.dark`, `.white` or `.black` in a view; every colour goes through a role in `Color+Extensions`.
- The accent `F7931A` and `onAccent` are the only colours that don't change with the theme.
