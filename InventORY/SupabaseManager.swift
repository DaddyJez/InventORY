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
    
    @MainActor
    func fetchShopItems() async throws -> [ShopItem] {
        do {
            let response: [ShopItem] = try await client
                .from("shopItems")
                .select()
                .execute()
                .value
            
            print(response)
            return response
        } catch {
            print("Ошибка при загрузке товаров: \(error)")
            throw error
        }
    }
    
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
    
    func fetchStorageData() async throws -> [[String: String]] {
        do {
            // Выполняем запрос к таблице "storage" с JOIN на таблицу "users"
            let response: [StorageItem] = try await client
                .from("storage")
                .select("category, articul, name, quantity, whoBought, dateOfBuy, users:users(name)")
                .execute()
                .value // Используем .value для получения декодированного результата
            
            print(response)

            // Преобразуем данные в [[String: String]]
            var result: [[String: String]] = []
            for item in response {
                let category = item.category
                let articul = item.articul
                let name = item.name
                let quantity = item.quantity
                let whoBought = item.whoBought
                let dateOfBuy = item.dateOfBuy
                
                let buyerName = item.users?.name ?? "Unknown"
                                
                // Добавляем в результат
                result.append([
                    "category": category,
                    "articul": articul,
                    "name": name,
                    "quantity": String(quantity),
                    "whoBought": whoBought,
                    "buyerName": buyerName,
                    "dateOfBuy": dateOfBuy,
                ])
                
            }

            return result
        } catch {
            print("Ошибка при получении данных из таблицы storage: \(error)")
            throw error
        }
    }

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

    // Метод для входа пользователя
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
    
    func getAllUserIDs() async -> Set<String> {
            do {
                let response: [UserData] = try await client
                    .from("users")
                    .select("identifier")
                    .execute()
                    .value

                let ids = response.map { $0.identifier }
                return Set(ids)
            } catch {
                print("Ошибка при получении идентификаторов: \(error)")
                return []
            }
        }
    
    func generateUniqueID() async -> String {
        var generatedIDs: Set<String> = await getAllUserIDs()

        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ0123456789"
        let charactersArray = Array(characters)

        while true {
            let newID = (0..<6).map { _ in
                charactersArray.randomElement()!
            }.reduce("", { String($0) + String($1) })

            if !generatedIDs.contains(newID) {
                generatedIDs.insert(newID)
                return newID
            }
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
    let id: Int
    let articul: String
    let category: String
    let name: String
    let cost: Int
    let description: String
}
