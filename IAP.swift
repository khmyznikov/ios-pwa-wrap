//
//  IAP.swift
//  pwa-shell
//
//  Created by GlebKh on 05.10.2023.
//

import StoreKit

struct TransactionInfo: Codable {
    let productID: String
    let transactionID: String
}

@MainActor final class StoreKitAPI: ObservableObject {
   @Published private(set) var products: [Product] = []
   @Published private(set) var productsJson: String = "[]"
   @Published private(set) var activeTransactions: Set<StoreKit.Transaction> = []
   @Published private(set) var activeTransactionsJson: String = "[]"
   private var updates: Task<Void, Never>?
   
   init() {
       updates = Task {
           for await update in StoreKit.Transaction.updates {
               if let transaction = try? update.payloadValue {
                  self.activeTransactions.insert(transaction)
                   await transaction.finish()
               }
           }
       }
   }

   deinit {
       updates?.cancel()
   }

    func fetchProducts(productIDs: [String]) async {
       do {
           self.products = try await Product.products(for: productIDs)
           
           // Convert each product representation (Data) to JSON String
           let productJSONStrings: [String] = self.products.compactMap { product in
              guard let jsonString = String(data: product.jsonRepresentation, encoding: .utf8) else {
                  return nil
              }
              return jsonString
           }
           
           self.productsJson = "[\(productJSONStrings.joined(separator: ","))]"
           returnProductsResult(jsonString: self.productsJson)
       } catch {
           self.products = []
           // handle error
       }
    }
   
    func purchaseProduct(productID: String) async throws {
        guard let product = products.first(where: { $0.id == productID }) else {
            // Product not found.
            throw ProductError.productNotFound
        }

        do {
           let result = try await product.purchase()
           switch result {
           case .success(let verificationResult):
               if let transaction = try? verificationResult.payloadValue {
                   self.activeTransactions.insert(transaction)
                   await transaction.finish()
               }
           case .userCancelled:
               throw ProductError.userCanceled
           case .pending:
               throw ProductError.pending
           @unknown default:
               throw ProductError.unknown
           }
        } catch {
           // handle or throw error
           throw error
        }
    }

    enum ProductError: Error {
        case productNotFound
        case userCanceled
        case pending
        case unknown
    }
   
   func fetchActiveTransactions() async {
        var activeTransactions: Set<StoreKit.Transaction> = []
        var jsonRepresentation: [String] = []
        
       for await verificationResult in Transaction.currentEntitlements {
           let transaction = verificationResult.unsafePayloadValue
           jsonRepresentation.append(String(data: transaction.jsonRepresentation, encoding: .utf8)!)
       }
//        for await entitlement in StoreKit.Transaction.currentEntitlements {
//            if let transaction = try? entitlement.payloadValue {
//               activeTransactions.insert(transaction)
//                if let jsonString = String(data: transaction.jsonRepresentation, encoding: .utf8) {
//                    jsonRepresentation.append(jsonString)
//                }
//            }
//        }
        
//        self.activeTransactions = activeTransactions
        self.activeTransactionsJson = "[\(jsonRepresentation.joined(separator: ","))]"
       
        returnActiveTransactions(jsonString: self.activeTransactionsJson)
    }
}

func returnProductsResult(jsonString: String){
    DispatchQueue.main.async(execute: {
        PWAShell.webView.evaluateJavaScript("this.dispatchEvent(new CustomEvent('iap-products-result', { detail: '\(jsonString)' }))")
    })
}

func returnPaymentResult(state: String){
    DispatchQueue.main.async(execute: {
        PWAShell.webView.evaluateJavaScript("this.dispatchEvent(new CustomEvent('iap-purchase-result', { detail: '\(state)' }))")
    })
}

func returnActiveTransactions(jsonString: String){
    DispatchQueue.main.async(execute: {
        PWAShell.webView.evaluateJavaScript("this.dispatchEvent(new CustomEvent('iap-transactions-result', { detail: '\(jsonString)' }))")
    })
}
