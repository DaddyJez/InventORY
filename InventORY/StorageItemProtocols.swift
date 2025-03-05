//
//  StorageItemProtocols.swift
//  InventORY
//
//  Created by Влад Карагодин on 03.03.2025.
//

import Foundation

@MainActor
protocol StorageItemDelegate: AnyObject {
    func didTapLocate(for cell: StorageTableViewCell)
}

@MainActor
protocol LocationItemDelegate: AnyObject {
    func didTapRelocate(for cell: LocationTableViewCell)
}
