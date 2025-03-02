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
        filterStoreButton.setTitle("Filter by", for: .normal)
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
        let filteredData = self.tableData
        
        let sortedData: [[String: String]]
        if criterion == "category" {
            sortedData = filteredData.filter { $0["category"] != nil }
        } else if criterion == "cost" {
            sortedData = filteredData.sorted {
                guard let firstValue = $0[criterion], let secondValue = $1[criterion] else { return false }
                return Int(firstValue)! < Int(secondValue)!
            }
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
    }
    
    private func showCategoryFilterOptions() {
        if tableData.isEmpty {
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
        let filterByQuantityAction = UIAlertAction(title: "Cost", style: .default) { [weak self] _ in
            self?.applyFilter(criterion: "cost")
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
        alertController.addAction(filterByCategoryAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func clearStoreFilters() {
        Task {
            do {
                let fetchedData = try await supabaseManager.fetchShopItems()
                self.tableData = fetchedData
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                filterStoreButton.setTitle("Filter by", for: .normal)
            } catch {
                print("Ошибка при сбросе фильтров: \(error)")
            }
        }
    }
    
    private func provideAddingItem() {
        let alertController = UIAlertController(title: "Add item", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Category"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Name"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Cost"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Description"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            guard
                let categoryToAdd = alertController.textFields?[0].text,
                let nameToAdd = alertController.textFields?[1].text,
                let costToAdd = alertController.textFields?[2].text,
                let descriptionToAdd = alertController.textFields?[3].text
            else {
                return
            }
            self.guardAddingItem(category: categoryToAdd, name: nameToAdd, cost: costToAdd, description: descriptionToAdd)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        present(alertController, animated: true)
    }
    
    private func guardAddingItem(category: String, name: String, cost: String, description: String) {
        Task {
            do {
                if let item: String? = await SupabaseManager.shared.addStoreItem(category: category, name: name, cost: cost, description: description) {
                    await chooseQuantityToBuy(itemArticul: item!)
                }
            }
        }
    }
    
    private func chooseQuantityToBuy(itemArticul: String) async {
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
        
        present(alertController, animated: true)
        }
    
    private func provideBuying(itemArticul: String, quant: String? = "1") async {
        if quant == "" {
            await SupabaseManager.shared.buyItemFromStore(articul: itemArticul, quantity: "1")
        } else {
            await SupabaseManager.shared.buyItemFromStore(articul: itemArticul, quantity: quant!)
        }
        
    }
    
    @IBAction func filterStoreButtonTapped(_ sender: Any) {
        showFilterStoreOptions()
    }
    
    @IBAction func resetStoreFilterTapped(_ sender: Any) {
        clearStoreFilters()
    }
    
    @IBAction func addItemButtonTapped(_ sender: Any) {
        provideAddingItem()
    }
    
    private func onCellTapped(cell: UITableViewCell!) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let rowData = tableData[indexPath.row]
        let message = """
        Articul: \(rowData["articul"] ?? "") 
        Category: \(rowData["category"] ?? "")
                
        \(rowData["description"] ?? "")
        
        Cost: \(rowData["cost"] ?? "")
        """
        let alertController = UIAlertController(
            title: "Buy '\(rowData["name"] ?? "")'?",
            message: message,
            preferredStyle: .alert
        )
        
        let proceedAction = UIAlertAction(title: "Yes", style: .default) {
            [weak self] _ in
            guard let self = self else { return }
            Task {
                do {
                    await chooseQuantityToBuy(itemArticul: rowData["articul"]!)
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alertController.addAction(proceedAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}

extension StoreViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ShopCell", for: indexPath) as! ShopItemTableViewCell
        let item = tableData[indexPath.row]
        
        cell.articulLabel.text = item["articul"]
        cell.nameLabel.text = item["name"]
        cell.costLabel.text = "\(item["cost"] ?? "cost") $"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        self.onCellTapped(cell: cell)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40 
    }
}
