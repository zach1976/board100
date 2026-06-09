import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the "remove ads" (Pro) purchase using Apple StoreKit directly via the
/// official in_app_purchase plugin — no third-party backend.
///
/// Two products, both granting the same ad-free entitlement:
///   * [lifetimeId] — a non-consumable (buy once, forever). Fully reliable
///     locally: restore re-delivers it on any device/reinstall.
///   * [yearlyId]   — an auto-renewable subscription. NOTE: without server-side
///     receipt validation we can't see the exact expiry, so a lapsed
///     subscriber may stay ad-free a little longer than they paid for. For an
///     ad-removal perk that's an acceptable, user-friendly leniency; add a
///     Laravel verifyReceipt endpoint later if churn ever matters.
///
/// Gated like [AdService]: a no-op unless [isStoreEnabled] — an iOS release
/// build that opted in via `--dart-define=IAP=1`. The shared dev build, Android
/// builds, and any build without the flag are completely unaffected, and the
/// ad-removal menu item never appears.
///
/// The entitlement is local (StoreKit + a persisted flag), not tied to login —
/// removing ads works offline and without an account.
class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  /// App Store Connect product IDs for THIS app. Each single-sport app and the
  /// hub configure their own products under these same IDs (IDs are scoped per
  /// app, so they can be reused across the 16 apps).
  static const String lifetimeId = 'remove_ads_lifetime';
  // 'remove_ads_yearly' was deleted in ASC (to change its price) and Apple
  // permanently reserves deleted product IDs, so the live yearly product uses a
  // fresh id. Keep in sync with tool/asc_iap.py YEARLY_ID.
  static const String yearlyId = 'remove_ads_annual';
  static const Set<String> _ids = {lifetimeId, yearlyId};

  /// Persisted "owns ad removal" flag, so a returning user is ad-free instantly
  /// and offline, before StoreKit re-confirms.
  static const String _prefKey = 'remove_ads_pro';

  /// Opt-in flag set only by production iOS builds (--dart-define=IAP=1).
  /// Compare the string explicitly: bool.fromEnvironment only treats "true" as
  /// true, so a value of "1" would wrongly read as false.
  static const bool _enabled = String.fromEnvironment('IAP') == '1';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _initialized = false;
  bool _hasPro = false;
  List<ProductDetails> _products = const [];

  // Resolves when an in-flight buy/restore settles (purchased/restored/error).
  Completer<bool>? _pending;

  bool get isStoreEnabled => _enabled && Platform.isIOS;

  /// Whether the user currently owns the ad-removal entitlement. Read live by
  /// [AdService] to gate every ad.
  bool get hasPro => _hasPro;

  /// Loaded products (yearly + lifetime) with localized store prices.
  List<ProductDetails> get products => _products;

  /// Configure StoreKit and resolve the entitlement. Safe to call once from
  /// main(); returns immediately when the store is disabled for this build.
  Future<void> init() async {
    if (_initialized || !isStoreEnabled) return;
    _initialized = true;

    // Trust the persisted flag first — instant, offline-friendly.
    final prefs = await SharedPreferences.getInstance();
    _hasPro = prefs.getBool(_prefKey) ?? false;
    if (_hasPro) notifyListeners();

    if (!await _iap.isAvailable()) return;
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (_) {});
    await _loadProducts();
    // Deliberately NOT auto-restoring here: restorePurchases() can pop an
    // Apple-account sign-in prompt on launch, and Apple recommends restore be
    // user-initiated. Entitlement persists locally (above); after a reinstall
    // or on a new device the user taps "Restore Purchases" in the paywall.
  }

  Future<void> _loadProducts() async {
    try {
      final resp = await _iap.queryProductDetails(_ids);
      _products = resp.productDetails;
      notifyListeners();
    } catch (_) {}
  }

  /// The purchasable products, or null when the store is off / none configured.
  Future<List<ProductDetails>?> productList() async {
    if (!isStoreEnabled) return null;
    if (_products.isEmpty) await _loadProducts();
    return _products.isEmpty ? null : _products;
  }

  /// Buy a product. Completes true once the user owns Pro, false on
  /// error/cancel. The actual result is delivered asynchronously on the
  /// purchase stream; this bridges it back to an awaitable for the paywall.
  Future<bool> buy(ProductDetails product) async {
    if (!isStoreEnabled) return false;
    _pending = Completer<bool>();
    await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product));
    return _pending!.future
        .timeout(const Duration(minutes: 2), onTimeout: () => _hasPro);
  }

  /// Restore prior purchases (required by the App Store). Completes true if Pro.
  Future<bool> restore() async {
    if (!isStoreEnabled) return false;
    _pending = Completer<bool>();
    await _iap.restorePurchases();
    // Restored transactions arrive on the stream; if there are none, nothing is
    // emitted, so fall back to the current flag after a short wait.
    return _pending!.future
        .timeout(const Duration(seconds: 8), onTimeout: () => _hasPro);
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    var unlocked = false;
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (_ids.contains(p.productID)) unlocked = true;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          if (!(_pending?.isCompleted ?? true)) _pending!.complete(_hasPro);
        case PurchaseStatus.pending:
          break;
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
    if (unlocked && !_hasPro) {
      _hasPro = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
      notifyListeners();
    }
    if (unlocked && !(_pending?.isCompleted ?? true)) _pending!.complete(true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
