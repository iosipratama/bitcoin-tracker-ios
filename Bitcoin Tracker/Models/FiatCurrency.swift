import Foundation

/// Popular fiat currencies, all of which CoinGecko quotes directly. Ordered
/// roughly by how widely they're held rather than alphabetically, so the most
/// likely choices sit at the top of the menu.
nonisolated enum FiatCurrency: String, CaseIterable, Codable, Sendable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case cny = "CNY"
    case chf = "CHF"
    case cad = "CAD"
    case aud = "AUD"
    case nzd = "NZD"
    case hkd = "HKD"
    case sgd = "SGD"
    case inr = "INR"
    case idr = "IDR"
    case krw = "KRW"
    case twd = "TWD"
    case thb = "THB"
    case myr = "MYR"
    case php = "PHP"
    case vnd = "VND"
    case brl = "BRL"
    case mxn = "MXN"
    case zar = "ZAR"
    case ngn = "NGN"
    case aed = "AED"
    case sar = "SAR"
    case try_ = "TRY"
    case rub = "RUB"
    case pln = "PLN"
    case sek = "SEK"

    var id: String { rawValue }

    /// CoinGecko keys its response by lowercase code.
    var apiKey: String { rawValue.lowercased() }

    /// Localized to the reader, so an Indonesian user sees "Dolar AS" rather
    /// than a hardcoded English name.
    var displayName: String {
        Locale.current.localizedString(forCurrencyCode: rawValue) ?? rawValue
    }
}
