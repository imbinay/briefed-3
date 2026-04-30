import 'package:in_app_purchase/in_app_purchase.dart' if (dart.library.js_interop) '../core/iap_stub.dart';

class ProPurchaseService {
  static const String proProductId = 'briefed_pro_lifetime';
  static const String fallbackPriceLabel = 'A\$2.99 one-time';

  static final InAppPurchase _iap = InAppPurchase.instance;

  static Stream<List<PurchaseDetails>> get purchaseStream =>
      _iap.purchaseStream;

  static bool isProPurchase(PurchaseDetails purchase) =>
      purchase.productID == proProductId;

  static bool unlocksPro(PurchaseDetails purchase) =>
      isProPurchase(purchase) &&
      (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored);

  static Future<ProductDetails> loadProProduct() async {
    final available = await _iap.isAvailable();
    if (!available) {
      throw StateError('Purchases are not available on this device.');
    }

    final response = await _iap.queryProductDetails({proProductId});
    if (response.error != null) {
      throw StateError(response.error!.message);
    }
    if (response.productDetails.isEmpty) {
      throw StateError(
        'Pro one-time product is not configured yet. Create $proProductId in Play Console at A\$2.99.',
      );
    }
    return response.productDetails.first;
  }

  static Future<void> buyPro(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  static Future<void> restorePurchases() => _iap.restorePurchases();

  static Future<void> complete(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }
}
