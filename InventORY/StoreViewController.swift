//
//  StoreViewController.swift
//  InventORY
//
//  Created by Влад Карагодин on 18.02.2025.
//

import UIKit

class StoreViewController: UIViewController {
    @IBOutlet weak var filterStoreButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    private var shopItems: [ShopItem] = []
    private var tableData: [[String: String]] = []
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
                let tableData = try await supabaseManager.fetchShopItems()
                self.tableData = tableData
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("Не удалось загрузить данные: \(error)")
            }
        }
    }
    
    private func applyFilter(criterion: String) {
        filterStoreButton.setTitle("Filter by: \(criterion)", for: .normal)
        Task {
            do {
                let filteredData = try await SupabaseManager.shared.fetchStorageData()
                
                let sortedData: [[String: String]]
                if criterion == "category" {
                    sortedData = filteredData.filter { $0["category"] != nil }
                } else {
                    sortedData = filteredData.sorted {
                        guard let firstValue = $0[criterion], let secondValue = $1[criterion] else { return false }
                        return firstValue < secondValue
                    }
                }
                
                self.tableData = sortedData
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("Ошибка при фильтрации данных: \(error)")
            }
        }
    }
    
    private func showCategoryFilterOptions() {
        // Проверяем, загружены ли данные
        if tableData.isEmpty {
            // Если данные не загружены, загружаем их
            Task {
                do {
                    self.tableData = try await SupabaseManager.shared.fetchStorageData()
                    self.showCategoryFilterOptions()
                } catch {
                    print("Ошибка при загрузке данных: \(error)")
                }
            }
            return
        }
        
        // Получаем уникальные категории из tableData
        let categories = Set(tableData.compactMap { $0["category"] })
        
        // Создаем UIAlertController для отображения списка категорий
        let alertController = UIAlertController(title: "Filter by Category", message: "Choose a category", preferredStyle: .actionSheet)
        
        // Добавляем кнопку для каждой категории
        for category in categories {
            let action = UIAlertAction(title: category, style: .default) { [weak self] _ in
                self?.applyCategoryFilter(category: category)
            }
            alertController.addAction(action)
        }
        
        // Добавляем кнопку "Cancel"
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Отображаем UIAlertController
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func applyCategoryFilter(category: String) {
        filterStoreButton.setTitle("Filter by: \(category)", for: .normal)
        let filteredData = tableData.filter { $0["category"] == category }
        
        self.tableData = filteredData
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func showFilterStoreOptions() {
        let alertController = UIAlertController(title: "Filter by", message: "Choose a filter criterion", preferredStyle: .actionSheet)
        
        // Кнопка для фильтрации по имени
        let filterByNameAction = UIAlertAction(title: "Name", style: .default) { [weak self] _ in
            self?.applyFilter(criterion: "name")
        }
        
        // Кнопка для фильтрации по количеству
        let filterByQuantityAction = UIAlertAction(title: "Quantity", style: .default) { [weak self] _ in
            self?.applyFilter(criterion: "quantity")
        }
        
        // Кнопка для фильтрации по покупателю
        let filterByBuyerAction = UIAlertAction(title: "Buyer", style: .default) { [weak self] _ in
            self?.applyFilter(criterion: "buyerName")
        }
        
        // Кнопка для фильтрации по категории
        let filterByCategoryAction = UIAlertAction(title: "Category", style: .default) { [weak self] _ in
            self?.showCategoryFilterOptions()
        }
        
        // Кнопка для отмены
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // Добавляем все кнопки в UIAlertController
        alertController.addAction(filterByNameAction)
        alertController.addAction(filterByQuantityAction)
        alertController.addAction(filterByBuyerAction)
        alertController.addAction(filterByCategoryAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func filterStoreButtonTapped(_ sender: Any) {
        showFilterStoreOptions()
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
