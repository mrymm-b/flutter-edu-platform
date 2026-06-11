// Tap Payments configuration.
//
// The secret key is stored as a Supabase Edge Function secret (TAP_SECRET_KEY)
// and is never shipped in the app binary.
// Set it with: supabase secrets set TAP_SECRET_KEY=sk_...
class TapConfig {
  static const String currency = 'BHD';

  // Tap redirects here after payment. Wire to a deep link in production
  // (e.g. myapp://payment-complete) so the OS returns the user to the app.
  static const String redirectUrl = 'https://YOUR_DOMAIN/payment-complete';

  static const String edgeFunction = 'tap-payments';
}
