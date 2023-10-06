//
//  IAP.swift
//  pwa-shell
//
//  Created by GlebKh on 05.10.2023.
//

import StoreKit

final class StoreHelper: NSObject {
    static let shared = StoreHelper()
    private override init() {}
    
    var productsRequest: SKProductsRequest?
    var demoProduct: SKProduct?

    func purchase(productID: String, completion: @escaping (Bool, Error?) -> Void) {
        let payment = SKPayment(product: demoProduct!)
        SKPaymentQueue.default().add(payment)
    }
    
    func start() {
        SKPaymentQueue.default().add(self)
        fetchProducts()
    }
    
    func fetchProducts() {
        let productIdentifiers = Set(["demo_product_id"]) // Replace "demo_product_id" with your actual product ID
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
}

extension StoreHelper: SKPaymentTransactionObserver {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                //completion(true, nil) // Purchase successful
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                //completion(false, transaction.error) // Purchase unsuccessful
            default: break
            }
        }
    }
}

extension StoreHelper: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if let product = response.products.first {
            self.demoProduct = product
        }
    }
}

