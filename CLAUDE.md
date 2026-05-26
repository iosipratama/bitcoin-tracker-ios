# Bitcoin Tracker — Claude Context

## What this app is

A minimalist, read-only Bitcoin wallet tracker for iOS. Users create named wallets, add public Bitcoin addresses, and track BTC balance and optional fiat equivalent. Each wallet holding one or more on-chain addresses. No private keys. No transactions. No trading. 

The app fetches live balances and price and displays them — nothing else. 

**Core philosophy:** help people stack sats and *not* get shaken by volatility. The UI should feel calm, grounded, and intentional — not like a trading terminal.


### ideal users
long-term Bitcoin holder. someone who bought and isn't selling. They don't want to trade, they don't watch the price obsessively, and they're actively turned off by the anxiety-inducing UI of most crypto apps. They probably keep their BTC in cold storage and just want a calm, occasional check-in.

- The quiet HODLer — has held for years, doesn't talk about it much, values privacy and restraint. The iA Writer aesthetic resonates because they think of Bitcoin more like a savings account than a speculative asset.
- The privacy-conscious user — appreciates that there's no account, no backend, no data leaving their phone. The read-only, address-paste model feels right to them.
- The minimalist / indie software person — uses apps like Things, iA Writer, Reeder. Has high standards for native iOS design and immediately uninstalls anything that feels bloated or gamified.
- The gift recipient / new holder — someone whose partner or friend convinced them to buy some Bitcoin. They're not deep in crypto culture and would be alienated by a typical exchange app. This one feels approachable and unintimidating.


### Screens
- Main View — list of wallets
- Wallet Detail — wallet name, aggregated balance, list of addresses with individual balances, last transactions. 
- Add Wallet — simple text field for wallet name
- Add Address — paste or type address, validate format, preview balance, save
- Settings — popular fiat currency selector, fiat show/hide toggle, about/API attribution

## Architecture

- **SwiftUI + SwiftData** (no UIKit, no third-party dependencies)
- **Models:** `Wallet` (name, cascade → addresses) and `BitcoinAddress` (address string, balance in satoshis, lastUpdated, fetchError)
- **Services:** both are Swift `actor` singletons
  - `BitcoinAPIService` — fetches on-chain balance via Blockstream API (`blockstream.info/api`)
  - `PriceService` — fetches BTC/USD/EUR/GBP price via CoinGecko, 1-minute in-memory cache
- **ViewModel:** `PortfolioViewModel` drives the home screen
- **Views:** `HomeView`, `WalletDetailView`, `AddWalletView`, `AddAddressView`, `SettingsView`
- **Helpers:** `WalletCard`, `AnimatingNumber`
- **Extensions:** `Color+Extensions` (custom palette + `cardRadius`/`rowRadius`), `Font+Extensions`


## Key conventions

- Internal balances are always **satoshis** (`Int64`); convert to BTC only at display time
- `shortAddress` truncates to `first6...last6`
- Prefer editing existing files over creating new ones
- No comments unless the WHY is non-obvious
- No third-party packages — keep it dependency-free


### Design principles 
- Dark only. 


