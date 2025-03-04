//
//  LocateItemsViewController.swift
//  InventORY
//
//  Created by Влад Карагодин on 03.03.2025.
//

import UIKit

class LocateItemsViewController: UIViewController {
    @IBOutlet weak var identifyButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    private var tableData: [LocationItem] = []
    private var userData: [String: String] = [:]
    
    private let databaseManager = SupabaseManager.shared
    
    var criterion: (column: String?, criterion: String?)?
    var count: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            do {
                self.userData = self.databaseManager.DefaultsOperator.loadUserData()
                await setup()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func setup() async {
        tableView.delegate = self
        tableView.dataSource = self
                
        self.tableData = await SupabaseManager.shared.fetchLocations(col: (criterion?.column)!, value: (criterion?.criterion)!)
        if self.count == 0 {
            identifyButton.isHidden = true
        }
        if self.tableData.count == self.count {
            identifyButton.setTitle("All items identified", for: .normal)
            identifyButton.isEnabled = false
        } else if self.tableData.count < self.count ?? 0 {
            identifyButton.setTitle("Identify items (\(self.tableData.count)/\(self.count ?? 0))", for: .normal)
            identifyButton.isEnabled = true
        } else {
            identifyButton.setTitle("There is some problem", for: .normal)
            identifyButton.isEnabled = false
        }
    }
    
    private func setCondition(for rowData: LocationItem, userName: String) async {
        print("condition \(rowData.condition) will be set to \(!rowData.condition) on the row \(rowData.rowid)")
        
        await SupabaseManager.shared.setConditionOnLocation(rowData: rowData, condition: !rowData.condition, userName: userName)
        
        self.tableData = await SupabaseManager.shared.fetchLocations(col: (criterion?.column)!, value: (criterion?.criterion)!)
        self.tableView.reloadData()
    }
    
    private func onCellTapped(cell: UITableViewCell!) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let rowData = tableData[indexPath.row]
        
        var titleMessage: String!
        if rowData.condition {
            titleMessage = "Report '\(String(describing: rowData.storage!.name))' as broken?"
        } else {
            titleMessage = "Report '\(String(describing: rowData.storage!.name))' as working?"
        }
        
        let message = "U can change the status later"
        let alertController = UIAlertController(
            title: titleMessage,
            message: message,
            preferredStyle: .alert
        )
        
        let proceedAction = UIAlertAction(title: "Yes", style: .default) {
            [weak self] _ in
            guard let self = self else { return }
            Task {
                do {
                    await setCondition(for: rowData, userName: userData["identifier"]!)
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alertController.addAction(proceedAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func identifyItemButtonTapped(_ sender: Any) {
        Task{
            do {
                let cabinets = try await SupabaseManager.shared.fetchCabinets()
                
                let alertController = UIAlertController(title: "Locate items", message: "Choose a cabinet", preferredStyle: .actionSheet)
                
                for cabinet in cabinets {
                    let action = UIAlertAction(title: String(cabinet.cabinetNum), style: .default) { [weak self] _ in
                        print("\(cabinet.cabinetNum) \(String(describing: self!.criterion!.criterion!))")
                        Task {
                            do {
                                await SupabaseManager.shared.locateItem(articul: self!.criterion!.criterion!, cabinet: cabinet.cabinetNum, userName: (self?.userData["identifier"])!)
                                self!.tableData = await SupabaseManager.shared.fetchLocations(col: (self?.criterion?.column)!, value: (self?.criterion?.criterion)!)
                                self?.tableView.reloadData()
                                await self?.setup()
                            }
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
}

extension LocateItemsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as! LocationTableViewCell
        let item = tableData[indexPath.row]
        
        cell.nameLabel.text = item.storage?.name
        cell.cabinetLabel.text = String(item.cabinet)
        if item.condition {
            cell.conditionLabel.text = "✅"
        } else {
            cell.conditionLabel.text = "❌"
        }
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
