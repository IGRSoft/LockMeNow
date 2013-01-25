//
//  InAppPurchaseManager.h
//
//  Copyright (c) 2012 Symbiotic Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#define KEY_TRANSACTION								@"transaction"
#define KEY_PRODUCT									@"product"
#define KEY_PRODUCT_ID								@"productId"
#define KEY_TRANSACTION_ERROR						@"error"
#define NOTIFICATION_PURCHASE_SUCCEEDED				@"NOTIFICATION_INAPPPURCHASE_SUCCEEDED"
#define NOTIFICATION_PURCHASE_FAILED				@"NOTIFICATION_INAPPPURCHASE_FAILED"
#define NOTIFICATION_INAPPPURCHASE_UPDATE_DATA		@"NOTIFICATION_INAPPPURCHASE_UPDATE_DATA"

@interface InAppPurchaseManager : NSObject <SKPaymentTransactionObserver, SKProductsRequestDelegate> {

	SKProductsRequest *productsRequest;
}
+ (InAppPurchaseManager *)sharedManager;
// After setting up appropriate purchase notification listeners call startManager to start observering transactions
- (void)startManager;
- (BOOL)canMakePurchases;
- (void)restoreCompletedTransactions;
- (void)purchase:(NSString *)productId;
// finishTransaction: must be called only after a successful purchase notification
- (void)finishTransaction:(SKPaymentTransaction *)transaction;
- (void)requestUpgradeProductData:(NSString*)InAppID;

@end
