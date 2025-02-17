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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Выполняем на главном потоке
        DispatchQueue.main.async {
            let interaction = UIContextMenuInteraction(delegate: self)
            self.addInteraction(interaction)
        }
    }
    
    func configure(with data: [String: String]) {
        articulLabel.text = data["articul"]
        nameLabel.text = data["name"]
        quantityLabel.text = data["quantity"]
        buyerLabel.text = data["buyerName"]
    }
}

extension StorageTableViewCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let infoAction = UIAction(title: "More info", image: UIImage(systemName: "info.triangle")) { _ in
                print("Поделиться")
            }
            
            let buyAction = UIAction(title: "Buy more", image: UIImage(systemName: "goforward.plus")) { _ in
                print("Редактировать")
            }

            let deleteAction = UIAction(title: "Remove", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                print("Удалить")
            }

            return UIMenu(title: "", children: [infoAction, buyAction, deleteAction])
        }
    }
}

