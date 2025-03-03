//
//  StorageAlert.swift
//  InventORY
//
//  Created by Влад Карагодин on 03.03.2025.
//

import Foundation
import UIKit

class StorageAlert {
    @MainActor static let shared = StorageAlert() // Синглтон

    @MainActor
    func chooseQuantityToBuy(itemArticul: String, controller: UIViewController) async {
        let alertController = UIAlertController(title: "How much do you want to buy?", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Quantity"
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            guard
                let quantToBuy = alertController.textFields?[0].text
            else {
                return
            }
            Task {
                do {
                    await self.provideBuying(itemArticul: itemArticul, quant: quantToBuy)
                }
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        controller.present(alertController, animated: true)
        }
    
    @MainActor
    private func provideBuying(itemArticul: String, quant: String? = "1") async {
        if quant == "" {
            await SupabaseManager.shared.buyItemFromStore(articul: itemArticul, quantity: "1")
        } else {
            await SupabaseManager.shared.buyItemFromStore(articul: itemArticul, quantity: quant!)
        }
        
    }
}
