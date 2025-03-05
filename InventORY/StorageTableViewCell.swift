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
    
    weak var delegate: StorageItemDelegate?
    var controller: UIViewController!
    
    //weak var delegate: StorageTableViewCellDelegate?
    var onMoreInfoTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        DispatchQueue.main.async {
            let interaction = UIContextMenuInteraction(delegate: self)
            self.addInteraction(interaction)
        }
    }
    
    func configure(with data: [String: String], controller: UIViewController) {
        articulLabel.text = data["articul"]
        nameLabel.text = data["name"]
        quantityLabel.text = data["quantity"]
        buyerLabel.text = data["buyerName"]
        self.controller = controller
    }
}

extension StorageTableViewCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let infoAction = UIAction(title: "Locations", image: UIImage(systemName: "info.triangle")) { [weak self] _ in
                print("delegate to be next")
                guard let self = self else { return }
                self.delegate?.didTapLocate(for: self)
                }
            
            let buyAction = UIAction(title: "Buy more", image: UIImage(systemName: "goforward.plus")) { _ in
                Task {
                    do {
                        await StorageAlert.shared.chooseQuantityToBuy(itemArticul: self.articulLabel.text!, controller: self.controller)
                        await SupabaseManager.shared.setItemState(art: self.articulLabel.text!, state: "false")
                    }
                }
            }
            
            /*
            let deleteAction = UIAction(title: "Remove", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                print("Удалить")
            }
            */

            return UIMenu(title: "", children: [infoAction, buyAction])
        }
    }
}
