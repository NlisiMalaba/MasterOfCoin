/// Supported currencies for the Zimbabwe market.
/// USD - US Dollar, ZWG - Zimbabwe Gold (ZiG).
enum Currency {
  usd('USD', '\$'),
  zwg('ZWG', 'Z\$');

  const Currency(this.code, this.symbol);

  final String code;
  final String symbol;

  static Currency fromCode(String code) {
    return Currency.values.firstWhere(
      (c) => c.code == code,
      orElse: () => Currency.usd,
    );
  }
}
