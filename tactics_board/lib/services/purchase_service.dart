import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

/// Owns the RevenueCat SDK and the "remove ads" (Pro) entitlement.
///
/// Gated like [AdService]: every entry point is a no-op unless [isStoreEnabled],
/// i.e. a release build that injected a RevenueCat public SDK key via
/// `--dart-define=RC_IOS_KEY=...` (set by the production iOS build, mirroring
/// HUB_ADS). With no key the service stays disabled, [hasPro] is always false,
/// and the shared dev build / Android builds are completely unaffected.
///
/// Apple-only for now (Google Play comes later once volume justifies a merchant
/// account); an Android key slot is left for that. The Pro entitlement is NOT
/// tied to login — RevenueCat keys it to an anonymous app-user id, so removing
/// ads works offline and without an account; signing in only enables optional
/// cross-device restore.
class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  /// The single entitlement that unlocks ad removal. Both the yearly
  /// subscription and the lifetime product must grant this entitlement in the
  /// RevenueCat dashboard.
  static const String entitlementId = 'pro';

  // Public SDK keys, injected per-platform by the release build. Empty → off.
  static const String _iosKey = String.fromEnvironment('RC_IOS_KEY');
  static const String _androidKey = String.fromEnvironment('RC_ANDROID_KEY');

  bool _configured = false;
  bool _hasPro = false;

  /// True only when a key is configured for the current platform.
  bool get isStoreEnabled {
    if (Platform.isIOS) return _iosKey.isNotEmpty;
    if (Platform.isAndroid) return _androidKey.isNotEmpty;
    return false;
  }

  /// Whether the user currently owns the ad-removal entitlement. Read live by
  /// [AdService] to gate every ad. Defaults to false; flips when the SDK
  /// reports the entitlement (init, purchase, restore, or a background update).
  bool get hasPro => _hasPro;

  String get _key => Platform.isIOS ? _iosKey : _androidKey;

  /// Configure the SDK and read the current entitlement. Safe to call once from
  /// main(); returns immediately when the store is disabled for this build.
  Future<void> init() async {
    if (_configured || !isStoreEnabled) return;
    _configured = true;
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(_key));
      Purchases.addCustomerInfoUpdateListener(_apply);
      _apply(await Purchases.getCustomerInfo());
    } catch (_) {
      // Network/StoreKit hiccup — stay non-Pro; a later listener update or a
      // manual restore can still unlock.
    }
  }

  /// The current offering's purchasable packages (yearly + lifetime), or null
  /// when the store is off or none are configured.
  Future<List<Package>?> packages() async {
    if (!isStoreEnabled) return null;
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages;
    } catch (_) {
      return null;
    }
  }

  /// Buy a package. Returns true if the user now owns Pro.
  Future<bool> buy(Package package) async {
    if (!isStoreEnabled) return false;
    try {
      // purchasePackage is soft-deprecated in 10.x for purchase(PurchaseParams)
      // but still functional; swap when wiring real products + testing.
      final result = await Purchases.purchasePackage(package);
      _apply(result.customerInfo);
    } on PlatformException catch (e) {
      // User cancellation is not an error worth surfacing.
      if (PurchasesErrorHelper.getErrorCode(e) !=
          PurchasesErrorCode.purchaseCancelledError) {
        rethrow;
      }
    }
    return _hasPro;
  }

  /// Restore prior purchases (required by App Store). Returns true if Pro.
  Future<bool> restore() async {
    if (!isStoreEnabled) return false;
    try {
      _apply(await Purchases.restorePurchases());
    } catch (_) {}
    return _hasPro;
  }

  void _apply(CustomerInfo info) {
    final pro = info.entitlements.active.containsKey(entitlementId);
    if (pro == _hasPro) return;
    _hasPro = pro;
    notifyListeners();
  }
}
