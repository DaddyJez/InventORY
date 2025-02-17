//
//  StorageTableViewCell.swift
//  InventORY
//
//  Created by Влад Карагодин on 17.02.2025.
//

import UIKit

class StorageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var articulLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var buyerLabel: UILabel!
    
    func configure(with data: [String: String]) {
        articulLabel.text = data["articul"]
        nameLabel.text = data["name"]
        quantityLabel.text = data["quantity"]
        buyerLabel.text = data["buyerName"]
    }
}
