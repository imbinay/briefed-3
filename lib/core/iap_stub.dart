import 'dart:async';

// A dummy class so the web compiler doesn't crash when it sees PurchaseDetails
class DummyVerificationData {
  final String serverVerificationData = '';
  final String source = '';
}

class PurchaseDetails {
  final String productID = '';
  final DummyVerificationData verificationData = DummyVerificationData();
  final PurchaseStatus status = PurchaseStatus.pending;
  final bool pendingCompletePurchase = false;
}

class ProductDetails {
  final String id = '';
  final String title = '';
  final String description = '';
  final String price = '';
}

class PurchaseParam {
  final ProductDetails productDetails;
  PurchaseParam({required this.productDetails});
}

enum PurchaseStatus { pending, purchased, error, restored, canceled }

class IAPError {
  final String message = 'Not supported on web';
}

class ProductDetailsResponse {
  final List<ProductDetails> productDetails = [];
  final IAPError? error = IAPError();
}

class InAppPurchase {
  static final InAppPurchase instance = InAppPurchase();
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();
  Future<bool> isAvailable() async => false;
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async => ProductDetailsResponse();
  Future<void> buyNonConsumable({required PurchaseParam purchaseParam}) async {}
  Future<void> restorePurchases() async {}
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}