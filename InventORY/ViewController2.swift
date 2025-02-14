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
    @IBOutlet weak var storageScrollView: UIScrollView!
    @IBOutlet weak var changeNameButton: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    private var tableStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.userData = self.databaseManager.DefaultsOperator.loadUserData()
        
        oneMoreGreetLabel.text = "Hello, \(String(describing: self.userData["name"]))!"
        
        updateView()
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
    
    // Показываем главное окно
    private func showMainWindow() {
        oneMoreGreetLabel.text = "Hello, \(String(describing: self.userData["name"]!))!"
    }
    
    // Показываем окно с настройками аккаунта
    private func showAccountSettingsWindow() {
        oneMoreGreetLabel.text = "Account settings"
        onLoadGreetLabel.text = """
        Name: \(String(describing: self.userData["name"]!))
        Identifier: \(String(describing: self.userData["identifier"]!))
        Access level: \(String(describing: self.userData["accessLevel"]!))
        """
    }
    
    private func showStorageWindow() {
        Task {
            do {
                oneMoreGreetLabel.text = "Storage"

                let tableData = self.tableData.isEmpty ? try await SupabaseManager.shared.fetchStorageData() : self.tableData

                // Очистка предыдущего контента в storageScrollView
                for subview in storageScrollView.subviews {
                    subview.removeFromSuperview()
                }

                // Контейнер для таблицы
                let contentView = UIView()
                contentView.translatesAutoresizingMaskIntoConstraints = false
                storageScrollView.addSubview(contentView)

                NSLayoutConstraint.activate([
                    contentView.topAnchor.constraint(equalTo: storageScrollView.topAnchor),
                    contentView.leadingAnchor.constraint(equalTo: storageScrollView.leadingAnchor),
                    contentView.trailingAnchor.constraint(equalTo: storageScrollView.trailingAnchor),
                    contentView.bottomAnchor.constraint(equalTo: storageScrollView.bottomAnchor),
                    contentView.widthAnchor.constraint(equalTo: storageScrollView.widthAnchor)
                ])

                // Создание таблицы
                let tableScrollView = UIScrollView()
                tableScrollView.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(tableScrollView)

                let tableHeight: CGFloat = 350
                NSLayoutConstraint.activate([
                    tableScrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
                    tableScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                    tableScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                    tableScrollView.heightAnchor.constraint(equalToConstant: tableHeight)
                ])

                tableStackView = UIStackView()
                tableStackView.axis = .vertical
                tableStackView.spacing = 8 // Расстояние между строками
                tableStackView.translatesAutoresizingMaskIntoConstraints = false
                tableScrollView.addSubview(tableStackView)

                NSLayoutConstraint.activate([
                    tableStackView.topAnchor.constraint(equalTo: tableScrollView.topAnchor),
                    tableStackView.leadingAnchor.constraint(equalTo: tableScrollView.leadingAnchor),
                    tableStackView.trailingAnchor.constraint(equalTo: tableScrollView.trailingAnchor),
                    tableStackView.bottomAnchor.constraint(equalTo: tableScrollView.bottomAnchor),
                    tableStackView.widthAnchor.constraint(equalTo: tableScrollView.widthAnchor)
                ])

                // Добавляем шапку таблицы
                let headerStackView = UIStackView()
                headerStackView.axis = .horizontal
                headerStackView.spacing = 8 // Расстояние между колонками
                headerStackView.distribution = .fillEqually

                let headers = ["Articul", "Name", "Quant.", "Buyer"]
                for header in headers {
                    let headerLabel = UILabel()
                    headerLabel.text = header
                    headerLabel.textAlignment = .center
                    headerLabel.font = UIFont.boldSystemFont(ofSize: 16)
                    headerLabel.backgroundColor = .systemGray
                    headerLabel.layer.cornerRadius = 2
                    headerLabel.layer.masksToBounds = true
                    headerStackView.addArrangedSubview(headerLabel)
                }

                tableStackView.addArrangedSubview(headerStackView)

                for (index, row) in tableData.enumerated() {
                    let rowStackView = UIStackView()
                    rowStackView.axis = .horizontal
                    rowStackView.spacing = 4 // Расстояние между колонками
                    rowStackView.distribution = .fillEqually
                    rowStackView.tag = index // Сохраняем индекс строки

                    let articul = row["articul"] ?? ""
                    let name = row["name"] ?? ""
                    let quantity = row["quantity"] ?? ""
                    let buyerName = row["buyerName"] ?? ""
                    let whoBought = row["whoBought"] ?? ""

                    let cellData = [articul, name, quantity, buyerName]

                    for cellText in cellData {
                        let cellLabel = UILabel()
                        cellLabel.text = cellText
                        cellLabel.textAlignment = .center
                        cellLabel.backgroundColor = .lightGray
                        cellLabel.layer.cornerRadius = 4
                        cellLabel.layer.masksToBounds = true
                        rowStackView.addArrangedSubview(cellLabel)
                    }

                    // Раскрывающаяся область
                    let expandableView = UIView()
                    expandableView.backgroundColor = .lightGray
                    expandableView.isHidden = true
                    expandableView.translatesAutoresizingMaskIntoConstraints = false

                    let detailLabel = UILabel()
                    detailLabel.text = """
                    Category: \(row["category"] ?? "")
                    Articul: \(articul)
                    Name: \(name)
                    Quantity: \(quantity)
                    Buyer: \(buyerName) (\(whoBought))
                    Purchased at: \(row["dateOfBuy"] ?? "")
                    """
                    detailLabel.numberOfLines = 0
                    detailLabel.translatesAutoresizingMaskIntoConstraints = false
                    expandableView.addSubview(detailLabel)

                    // Добавляем кнопку "Report broken"
                    let reportBrokenButton = UIButton(type: .system)
                    reportBrokenButton.setTitle("Report broken", for: .normal)
                    reportBrokenButton.backgroundColor = .systemRed
                    reportBrokenButton.setTitleColor(.white, for: .normal)
                    reportBrokenButton.layer.cornerRadius = 8
                    reportBrokenButton.translatesAutoresizingMaskIntoConstraints = false
                    reportBrokenButton.isHidden = true // Скрываем кнопку по умолчанию
                    reportBrokenButton.addAction(UIAction { [weak self] _ in
                        guard let self = self else { return }
                        self.reportButtonTapped(sender: reportBrokenButton, articul: articul)
                    }, for: .touchUpInside)

                    // Показываем кнопку, если accessLevel >= 2
                    if let accessLevel = Int(self.userData["accessLevel"] ?? "0"), accessLevel >= 2 {
                        reportBrokenButton.isHidden = false
                    }

                    expandableView.addSubview(reportBrokenButton)
                    
                    NSLayoutConstraint.activate([
                        detailLabel.topAnchor.constraint(equalTo: expandableView.topAnchor, constant: 8),
                        detailLabel.leadingAnchor.constraint(equalTo: expandableView.leadingAnchor, constant: 8),
                        detailLabel.trailingAnchor.constraint(equalTo: expandableView.trailingAnchor, constant: -8),
                    ])

                    NSLayoutConstraint.activate([
                        reportBrokenButton.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 8),
                        reportBrokenButton.leadingAnchor.constraint(equalTo: expandableView.leadingAnchor, constant: 8),
                        reportBrokenButton.trailingAnchor.constraint(equalTo: expandableView.trailingAnchor, constant: -8),
                        reportBrokenButton.heightAnchor.constraint(equalToConstant: 40),
                        reportBrokenButton.bottomAnchor.constraint(equalTo: expandableView.bottomAnchor, constant: -8)
                    ])

                    let containerStackView = UIStackView()
                    containerStackView.axis = .vertical
                    containerStackView.spacing = 8
                    containerStackView.addArrangedSubview(rowStackView)
                    containerStackView.addArrangedSubview(expandableView)

                    tableStackView.addArrangedSubview(containerStackView)

                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleRowTap(_:)))
                    rowStackView.addGestureRecognizer(tapGesture)
                }

                let totalHeight = tableStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
                tableScrollView.contentSize = CGSize(width: tableScrollView.bounds.width, height: totalHeight)

                let stackView = UIStackView()
                stackView.axis = .vertical
                stackView.alignment = .fill
                stackView.distribution = .equalSpacing
                stackView.spacing = 16 // Устанавливаем отступ между элементами
                stackView.translatesAutoresizingMaskIntoConstraints = false

                contentView.addSubview(stackView)

                NSLayoutConstraint.activate([
                    stackView.topAnchor.constraint(equalTo: tableScrollView.bottomAnchor, constant: 16),
                    stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                    stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                    stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16) // Чтобы контент не выходил за пределы
                ])

                let buttonTitles = [
                    "Filter by",
                    "Item Location",
                    "Store"
                ]

                for title in buttonTitles {
                    let button = UIButton(type: .system)
                    button.setTitle(title, for: .normal)
                    button.backgroundColor = .systemBlue
                    button.setTitleColor(.white, for: .normal)
                    button.layer.cornerRadius = 8
                    button.translatesAutoresizingMaskIntoConstraints = false

                    button.heightAnchor.constraint(equalToConstant: 50).isActive = true

                    button.addTarget(self, action: #selector(storageButtonTapped(_:)), for: .touchUpInside)

                    stackView.addArrangedSubview(button)
                }

            } catch {
                print("Ошибка при отображении данных: \(error)")
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
        
        // Новая кнопка для сброса фильтров
        let clearFiltersAction = UIAlertAction(title: "Clear Filters", style: .destructive) { [weak self] _ in
            self?.clearFilters()
        }
        
        // Кнопка для отмены
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // Добавляем все кнопки в UIAlertController
        alertController.addAction(filterByNameAction)
        alertController.addAction(filterByQuantityAction)
        alertController.addAction(filterByBuyerAction)
        alertController.addAction(filterByCategoryAction)
        alertController.addAction(clearFiltersAction) // Добавляем кнопку сброса фильтров
        alertController.addAction(cancelAction)
        
        // Отображаем UIAlertController
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func clearFilters() {
        Task {
            do {
                // Загружаем исходные данные из Supabase
                let fetchedData = try await SupabaseManager.shared.fetchStorageData()
                
                // Обновляем tableData
                self.tableData = fetchedData
                
                // Обновляем таблицу
                updateTable(with: fetchedData)
                
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
                    // После загрузки данных вызываем метод снова
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
        // Фильтруем tableData по выбранной категории
        let filteredData = tableData.filter { $0["category"] == category }
        
        // Обновляем таблицу с отфильтрованными данными
        updateTable(with: filteredData)
    }
    
    private func applyFilter(criterion: String) {
        Task {
            do {
                let filteredData = try await SupabaseManager.shared.fetchStorageData()
                
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
                
                // Обновление таблицы
                updateTable(with: sortedData)
            } catch {
                print("Ошибка при фильтрации данных: \(error)")
            }
        }
    }
    
    private func updateTable(with data: [[String: String]]) {
        for subview in storageScrollView.subviews {
            subview.removeFromSuperview()
        }
        
        tableData = data
        
        showStorageWindow()
    }
    
    @objc func handleRowTap(_ sender: UITapGestureRecognizer) {
        guard let rowStackView = sender.view as? UIStackView else { return }
        
        if let containerStackView = rowStackView.superview as? UIStackView {
            let expandableView = containerStackView.arrangedSubviews[1]
            
            UIView.animate(withDuration: 0.3) {
                expandableView.isHidden = !expandableView.isHidden
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func buyMoreButtonTapped(_ sender: UIButton) {
        if let containerStackView = sender.superview?.superview as? UIStackView,
           let rowStackView = containerStackView.arrangedSubviews.first as? UIStackView {
            let index = rowStackView.tag
            
            let selectedItem = tableData[index]
            
            print("Buy more tapped for item: \(selectedItem["articul"]!)")
            }
    }
    
    private func updateView() {
        storageScrollView.isHidden = segmentedControl.selectedSegmentIndex != 0
        mainScrollView.isHidden = segmentedControl.selectedSegmentIndex != 1
        accountScrollView.isHidden = segmentedControl.selectedSegmentIndex != 2
        
        let selectedSegment = segmentedControl.selectedSegmentIndex
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
    
    @IBAction func ifLogOut() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ViewController")
        self.navigationController?.setViewControllers([vc], animated: true)
    }
}
