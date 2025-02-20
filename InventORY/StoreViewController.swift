//
//  StoreViewController.swift
//  InventORY
//
//  Created by Влад Карагодин on 18.02.2025.
//

import UIKit

class StoreViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    private var shopItems: [ShopItem] = []
    private let supabaseManager = SupabaseManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadData()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        //tableView.register(UINib(nibName: "ShopItemTableViewCell", bundle: nil), forCellReuseIdentifier: "ShopCell")
    }

    private func loadData() {
        Task {
            do {
                shopItems = try await supabaseManager.fetchShopItems()
                tableView.reloadData()
            } catch {
                print("Не удалось загрузить данные: \(error)")
            }
        }
    }
}

extension StoreViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shopItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ShopCell", for: indexPath) as! ShopItemTableViewCell
        let item = shopItems[indexPath.row]
        
        cell.articulLabel.text = item.articul
        cell.nameLabel.text = item.name
        cell.costLabel.text = "\(item.cost) $"
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40 
    }
}
