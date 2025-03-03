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
    
    private let databaseManager = SupabaseManager.shared
    
    var criterion: (column: String?, criterion: String?)?
    var count: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            do {
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
        if self.tableData.count == self.count {
            identifyButton.setTitle("All items identified", for: .normal)
        } else {
            identifyButton.setTitle("Identify items (\(self.tableData.count)/\(self.count ?? 0))", for: .normal)
        }
    }
    
    private func onCellTapped(cell: UITableViewCell!) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let rowData = tableData[indexPath.row]
        /*
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
         */
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
