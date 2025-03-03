//
//  SupabaseManager.swift
//  InventORY
//

import Supabase
import Foundation

class SupabaseManager {
    @MainActor static let shared = SupabaseManager() // Синглтон

    private let client: SupabaseClient
    let DefaultsOperator: UserDefaultsManager
    var result: [[String: String]] = []

    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://ukgeippwcvmzqirugeio.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVrZ2VpcHB3Y3ZtenFpcnVnZWlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzczMzU5MDEsImV4cCI6MjA1MjkxMTkwMX0.GJEg05_DOZlFUntJCHehR44uhI5aKlxNWyIU1sEyjE4"
        )
        DefaultsOperator = UserDefaultsManager()
    }
    
    //MARK: USER OPERATIONS
    func fetchUsersData(identifier: String) async throws -> [[String: String]] {
        do {
            // Выполняем запрос к таблице "storage"
            let response: [UserData] = try await client
                .from("users")
                .select()
                .eq("identifier", value: identifier)
                .execute()
                .value

            // Преобразуем данные в [[String: String]]
            self.result = []
            for item in response {
                let identifier = item.identifier
                let name = item.name
                let login = item.login
                let password = item.password
                let level = item.level
                
                // Добавляем в результат
                result.append([
                    "identifier": identifier,
                    "name": name,
                    "login": login,
                    "password": password,
                    "level": String(level)
                ])
            }
            
            return result
        } catch {
            print("Ошибка при получении данных из таблицы storage: \(error)")
            throw error
        }
    }
    
    //MARK: STORAGE OPERATIONS
    func fetchStorageData() async throws -> [[String: String]] {
        do {
            // Выполняем запрос к таблице "storage" с JOIN на таблицу "users"
            let response: [StorageItem] = try await client
                .from("storage")
                .select("category, articul, name, quantity, whoBought, dateOfBuy, users:users(name)")
                .execute()
                .value
            
            var result: [[String: String]] = []
            for item in response {
                result.append([
                    "category": item.category,
                    "articul": item.articul,
                    "name": item.name,
                    "quantity": String(item.quantity),
                    "whoBought": item.whoBought,
                    "buyerName": item.users?.name ?? "Unknown",
                    "dateOfBuy": item.dateOfBuy,
                ])
            }

            return result
        } catch {
            print("Ошибка при получении данных из таблицы storage: \(error)")
            throw error
        }
    }
    
    //MARK: USER OPERATIONS
    func register(id: String, login: String, password: String) async -> Bool {
        do {
            let response = try await client
                .from("users")
                .insert([
                    "identifier": id,
                    "login": login,
                    "password": password,
                    "name": login,
                ])
                .execute()

            print("Пользователь зарегистрирован: \(response)")
            return true
        } catch {
            print("Ошибка при регистрации пользователя: \(error)")
            return false
        }
    }

    func login(enteredLogin: String, enteredPassword: String) async -> Bool? {
        do {
            let response: [UserData] = try await client
                .from("users")
                .select()
                .eq("login", value: enteredLogin)
                .eq("password", value: enteredPassword)
                .execute()
                .value
                        
            if (response.first != nil) {
                DefaultsOperator.saveUserData(identifier: response.first!.identifier, login: response.first!.login, password: response.first!.password, name: response.first!.name, accessLevel: response.first!.level)
                
                return true
            }
        } catch {
            print("Ошибка при входе пользователя: \(error)")
        }
        return nil
    }
    
    @MainActor func updateUserName(newName: String, oldData: [String: String]) async -> Bool {
        do {
            let response = try await client.from("users")
                .update(["name": newName])
                .eq("identifier", value: oldData["identifier"]!)
                .execute()
            
            print("Имя пользователя обновлено: \(response)")
            
            DefaultsOperator.saveUserData(
                identifier: oldData["identifier"]!,
                login: oldData["login"]!,
                password: oldData["password"]!,
                name: newName,
                accessLevel: Int8(oldData["accessLevel"]!)!
            )
            
            return true
        } catch {
            print("Ошибка при обновлении имени пользователя: \(error)")
            return false
        }
    }
    
    func isLoginExists(login: String) async -> Bool {
        do {
            let response: [UserData] = try await client
                .from("users")
                .select()
                .eq("login", value: login)
                .execute()
                .value

            return response.isEmpty
        } catch {
            print("Ошибка при проверке логина: \(error)")
            return false
        }
    }
    
    func getAllIDs(table: String, col: String) async -> Set<String> {
        do {
            switch table {
            case "users":
                let response: [UserData] = try await client
                    .from(table)
                    .select(col)
                    .execute()
                    .value

                let ids = response.map { $0.identifier }
                return Set(ids)
            case "shopItems":
                let response: [ShopItem] = try await client
                    .from(table)
                    .select(col)
                    .execute()
                    .value

                let ids = response.map { $0.articul }
                return Set(ids)
            default:
                preconditionFailure("Неверно указана таблица")
            }
            
        } catch {
            print("Ошибка при получении идентификаторов: \(error)")
            return []
        }
    }
    
    func generateUniqueID(table: String = "users", column: String = "identifier", length: Int = 6) async -> String {
        var generatedIDs: Set<String> = await getAllIDs(table: table, col: column)

        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ0123456789"
        let charactersArray = Array(characters)

        while true {
            let newID = (0..<length).map { _ in
                charactersArray.randomElement()!
            }.reduce("", { String($0) + String($1) })

            if !generatedIDs.contains(newID) {
                generatedIDs.insert(newID)
                return newID
            }
        }
    }
    
    //MARK: STORE ITEMS
    @MainActor
    func fetchShopItems() async throws -> [[String: String]] {
        do {
            let response: [ShopItem] = try await client
                .from("shopItems")
                .select()
                .execute()
                .value
            
            var result: [[String: String]] = []
            for item in response {
                result.append([
                    "articul": item.articul,
                    "category": item.category,
                    "name": item.name,
                    "cost": String(item.cost),
                    "description": item.description,
                ])
            }
            return result
        } catch {
            print("Ошибка при загрузке товаров: \(error)")
            throw error
        }
    }
    
    func addStoreItem(category: String, name: String, cost: String, description: String) async -> String {
        do {
            let articul = await generateUniqueID(table: "shopItems", column: "articul", length: 4)
            let response = try await client
                .from("shopItems")
                .insert([
                    "articul": articul,
                    "category": category,
                    "name": name,
                    "cost": cost,
                    "description": description
                ])
                .execute()

            print("Товар добавлен: \(response)")
            return articul
        } catch {
            print("Ошибка при регистрации товара: \(error)")
            return ""
        }
    }
    
    private func isItemInStorage(articul: String) async -> (Int, Bool) {
        do {
            let response: [StorageItem] = try await client
                .from("storage")
                .select()
                .eq("articul", value: articul)
                .execute()
                .value
            
            if response.first != nil {
                return (response.first!.quantity, true)
            } else {
                return (0, true)
            }
        } catch {
            print("error with checking item in storage: \(error)")
            return (0, false)
        }
    }
    
    private func newStorageChange(type: String = "BUY", art: String, quant: String, price: String, personalName: String) async {
        print("\(type) \(art) \(quant) \(price) \(personalName)")
        do {
            _ = try await client
                .from("storageChanges")
                .insert([
                    "type": type,
                    "itemArticul": art,
                    "quantity": quant,
                    "cost": price,
                    "personalName": personalName,
                ])
                .execute()
        } catch {
            print(error)
        }
    }
    
    func buyItemFromStore(articul: String, quantity: String) async {
        do {
            let response: [ShopItem] = try await client
                .from("shopItems")
                .select()
                .eq("articul", value: articul)
                .execute()
                .value
            
            if (response.first != nil) {
                let userData = self.DefaultsOperator.loadUserData()
                let itemInStorage: (Int, Bool) = await isItemInStorage(articul: response.first!.articul)
                if itemInStorage.1 {
                    if itemInStorage.0 > 0  {
                        _ = try await client.from("storage")
                            .update(["quantity": String(itemInStorage.0 + Int(quantity)!)])
                            .eq("articul", value: response.first!.articul)
                            .execute()
                    } else {
                        _ = try await client
                            .from("storage")
                            .insert([
                                "articul": response.first!.articul,
                                "name": response.first!.name,
                                "quantity": quantity,
                                "whoBought": userData["identifier"],
                                "category": response.first!.category
                            ])
                            .execute()
                    }
                    await newStorageChange(type: "BUY", art: response.first!.articul, quant: quantity, price: String((response.first!.cost * Int(quantity)!)), personalName: userData["identifier"]!)
                }
            }
        } catch {
            print("error: \(error)")
        }
    }
    
    //MARK: LOCATION OPERATIONS
    func fetchLocations(col: String, value: String) async -> [LocationItem] {
        do {
            let response: [LocationItem] = try await client
                .from("itemList")
                .select("ItemArticul, cabinet, condition, storage:storage(name),cabinets:cabinets(responsible)")
                .eq(col, value: value)
                .execute()
                .value
            print(response)
            return response
        } catch {
            print(error)
            return []
        }
    }
}

struct UserData: Codable {
    let identifier: String
    let login: String
    let password: String
    let name: String
    let level: Int8
}

struct StorageItem: Decodable {
    let category: String
    let articul: String
    let name: String
    let quantity: Int
    let whoBought: String
    let dateOfBuy: String
    let users: UserData?

    struct UserData: Decodable {
        let name: String
    }
}

struct ShopItem: Decodable {
    let articul: String
    let category: String
    let name: String
    let cost: Int
    let description: String
}

struct LocationItem: Decodable {
    let ItemArticul: String
    let cabinet: Int
    let condition: Bool

    let storage: StorageItem?
        
    struct StorageItem: Decodable {
        let name: String
    }
    
    let cabinets: Cabinets?
    
    struct Cabinets: Decodable {
        let responsible: String
    }
}
