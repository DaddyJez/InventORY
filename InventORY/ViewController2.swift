import UIKit
import Supabase

class ViewController2: UIViewController {
    @MainActor let databaseManager = SupabaseManager()
    
    var userData: [String: String] = [:]
    
    private var tableData: [[String: String]] = []
        
    @IBOutlet weak var onLoadGreetLabel: UILabel!
    @IBOutlet weak var oneMoreGreetLabel: UILabel!
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var accountScrollView: UIScrollView!
    @IBOutlet weak var storageScrollView: UIView!
    
    //@IBOutlet weak var changeNameButton: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var filterByButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    private var tableStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.userData = self.databaseManager.DefaultsOperator.loadUserData()
        
        oneMoreGreetLabel.text = "Hello, \(String(describing: self.userData["name"]))!"
        
        updateView()
        
        tableView.delegate = self
        tableView.dataSource = self
        //tableView.register(UINib(nibName: "StorageTableViewCell", bundle: nil), forCellReuseIdentifier: "StorageCell")
    }
    
    @objc private func handleMoreInfoNotification(_ notification: Notification) {
        guard let cell = notification.object as? StorageTableViewCell,
              let indexPath = tableView.indexPath(for: cell) else { return }
        
        print("handleMoreInfoNotification: \(indexPath)")
    }
    
    @IBAction func segmentedControlChanged(_ sender: Any) {
        updateView()
    }
    
    @IBAction func onChangeNamePressed(_ sender: Any) {
        let alertController = UIAlertController(
            title: "Change name",
            message: "Type new name",
            preferredStyle: .alert
        )
        
        alertController.addTextField { textField in
            textField.placeholder = "New name"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            if let newName = alertController.textFields?.first?.text, !newName.isEmpty {
                Task { [weak self] in
                    guard let self = self else { return }
                    
                    let success = await self.databaseManager.updateUserName(newName: newName, oldData: self.userData)
                    
                    if success {
                        print("Успешное изменение имени")
                        self.userData["name"] = newName
                        self.oneMoreGreetLabel.text = "Hello, \(newName)!"
                    } else {
                        print("Не удалось изменить имя")
                    }
                }
            } else {
                print("Имя не может быть пустым")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func onLogOutPressed(_ sender: Any) {
        let alertController = UIAlertController(
            title: "Are U sure?",
            message: "Want to log out?",
            preferredStyle: .alert
        )
        
        let proceedAction = UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // Очищаем данные пользователя
            self.userData = [:]
            self.databaseManager.DefaultsOperator.clearUserData()
            
            // Переходим на экран авторизации
            self.ifLogOut()
        }
        
        let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alertController.addAction(proceedAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func showMainWindow() {
        oneMoreGreetLabel.text = "Hello, \(String(describing: self.userData["name"]!))!"
    }
    
    private func showAccountSettingsWindow() {
        oneMoreGreetLabel.text = "Account settings"
        onLoadGreetLabel.text = """
        Name: \(String(describing: self.userData["name"]!))
        Identifier: \(String(describing: self.userData["identifier"]!))
        Access level: \(String(describing: self.userData["accessLevel"]!))
        """
    }
    
    @IBAction func filterOptionsButtonTapped(_ sender: Any) {
        showFilterOptions()
    }
    
    @IBAction func resetFiltersTapped(_ sender: Any) {
        clearFilters()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StorageCell", for: indexPath) as! StorageTableViewCell
        
        cell.delegate = self
        
        let rowData = tableData[indexPath.row]
        cell.configure(with: rowData, controller: self)
        
        cell.onMoreInfoTapped = { [weak self] in
            self!.showDetails(cell: cell)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        self.showDetails(cell: cell)
    }
    
    private func showDetails(cell: UITableViewCell!) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let rowData = tableData[indexPath.row]
                    
        let message = """
        Quantity: \(rowData["quantity"] ?? "")
        
        Articul: \(rowData["articul"] ?? "") 
        Category: \(rowData["category"] ?? "")
        
        Buyer: \(rowData["buyerName"] ?? "") (\(rowData["whoBought"] ?? ""))
        Purchased at: \(rowData["dateOfBuy"] ?? "")
        """
        
        let alertController = UIAlertController(
            title: rowData["name"],
            message: message,
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func showStorageWindow() {
        oneMoreGreetLabel.text = "Storage"
        filterByButton.setTitle("Filter by", for: .normal)
        
        Task {
            do {
                let tableData = self.tableData.isEmpty ? try await SupabaseManager.shared.fetchStorageData() : self.tableData
                self.tableData = tableData
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("Ошибка при загрузке данных: \(error)")
            }
        }
    }
    
    @objc func storageButtonTapped(_ sender: UIButton) {
        if let title = sender.currentTitle {
            if title == "Filter by" {
                showFilterOptions()
            } else {
                print("Нажата кнопка: \(title)")
            }
        }
    }
    
    @objc func reportButtonTapped(sender: UIButton, articul: String) {
        print("reportButtonTapped at \(articul)")
    }
    
    private func showFilterOptions() {
        let alertController = UIAlertController(title: "Filter by", message: "Choose a filter criterion", preferredStyle: .actionSheet)
        
        let filterByNameAction = UIAlertAction(title: "Name", style: .default) { [weak self] _ in
            self?.applyFilter(criterion: "name")
        }
        
        let filterByQuantityAction = UIAlertAction(title: "Quantity", style: .default) { [weak self] _ in
            self?.applyFilter(criterion: "quantity")
        }
        
        let filterByBuyerAction = UIAlertAction(title: "Buyer", style: .default) { [weak self] _ in
            self?.applyFilter(criterion: "buyerName")
        }
        
        let filterByCategoryAction = UIAlertAction(title: "Category", style: .default) { [weak self] _ in
            self?.showCategoryFilterOptions()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(filterByNameAction)
        alertController.addAction(filterByQuantityAction)
        alertController.addAction(filterByBuyerAction)
        alertController.addAction(filterByCategoryAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func clearFilters() {
        Task {
            do {
                let fetchedData = try await SupabaseManager.shared.fetchStorageData()
                
                self.tableData = fetchedData
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                filterByButton.setTitle("Filter by", for: .normal)
                print("Фильтры сброшены, отображены все данные.")
            } catch {
                print("Ошибка при сбросе фильтров: \(error)")
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
        filterByButton.setTitle("Filter by: \(category)", for: .normal)
        let filteredData = tableData.filter { $0["category"] == category }
        
        self.tableData = filteredData
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func applyFilter(criterion: String) {
        filterByButton.setTitle("Filter by: \(criterion)", for: .normal)
        let filteredData = self.tableData
        
        let sortedData: [[String: String]]
        if criterion == "category" {
            sortedData = filteredData.filter { $0["category"] != nil }
        } else if criterion == "quantity" {
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
    @IBAction func LocateItemsButtonTapped(_ sender: Any) {
        print("there we will choose cabinet")
        Task{
            do {
                let cabinets = try await SupabaseManager.shared.fetchCabinets()
                
                let alertController = UIAlertController(title: "Locate items", message: "Choose a cabinet", preferredStyle: .actionSheet)
                
                for cabinet in cabinets {
                    let action = UIAlertAction(title: String(cabinet.cabinetNum), style: .default) { [weak self] _ in
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let locateVC = storyboard.instantiateViewController(withIdentifier: "LocateItemsViewController") as? LocateItemsViewController {
                        locateVC.criterion = (column: "cabinet", criterion: String(cabinet.cabinetNum))
                        locateVC.count = 0
                        self?.navigationController?.pushViewController(locateVC, animated: true)
                    }
                    }
                    alertController.addAction(action)
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    private func updateView() {
        let selectedSegment = segmentedControl.selectedSegmentIndex

        storageScrollView.isHidden = selectedSegment != 0
        mainScrollView.isHidden = selectedSegment != 1
        accountScrollView.isHidden = selectedSegment != 2
        
        switch selectedSegment {
        case 0:
            showStorageWindow()
        case 1:
            showMainWindow()
        case 2:
            showAccountSettingsWindow()
        default:
            break
        }
    }
    
    private func ifLogOut() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ViewController")
        self.navigationController?.setViewControllers([vc], animated: true)
    }
    
    @IBAction func AddItemBurronTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let storeVC = storyboard.instantiateViewController(withIdentifier: "StoreViewController") as? StoreViewController {
            self.navigationController?.pushViewController(storeVC, animated: true)
        }
    }
}

extension ViewController2: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
}

extension ViewController2: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
}

extension ViewController2: StorageItemDelegate {
    func didTapLocate(for cell: StorageTableViewCell) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let locateVC = storyboard.instantiateViewController(withIdentifier: "LocateItemsViewController") as? LocateItemsViewController {
            locateVC.criterion = (column: "ItemArticul", criterion: cell.articulLabel.text ?? "")
            locateVC.count = Int(cell.quantityLabel.text ?? "1")
            self.navigationController?.pushViewController(locateVC, animated: true)
        }
    }
}
