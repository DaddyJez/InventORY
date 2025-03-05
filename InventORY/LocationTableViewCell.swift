//
//  LocationTableViewCell.swift
//  InventORY
//
//  Created by Влад Карагодин on 03.03.2025.
//

import UIKit

class LocationTableViewCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var cabinetLabel: UILabel!
    @IBOutlet var conditionLabel: UILabel!
    
    var item: LocationItem!
    
    weak var delegate: LocationItemDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        DispatchQueue.main.async {
            let interaction = UIContextMenuInteraction(delegate: self)
            self.addInteraction(interaction)
        }
    }
}

extension LocationTableViewCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let relocateAction = UIAction(title: "Relocate", image: UIImage(systemName: "info.triangle")) { [weak self] _ in
                print("delegate to be next")
                guard let self = self else { return }
                
                self.delegate?.didTapRelocate(for: self)
                }

            return UIMenu(title: "", children: [relocateAction])
        }
    }
}
