import UIKit
import CoreData

class UserControls {
    private(set) var userIdentifier: String?
    private(set) var login: String
    private var passw: String
    private var databaseManager: SupabaseManager = SupabaseManager()
    private var name: String?
    
    init(login: String!, password: String!) {
        self.login = login
        self.passw = password
        
        databaseManager = SupabaseManager()
    }

    func register() async -> Bool {
        guard await isValidLogin(self.login) && isValidPassword(self.passw) else {
            print("Некорректный логин или пароль")
            return false
        }

        self.userIdentifier = await generateUserIdentifier()

        return await databaseManager.register(id: self.userIdentifier!, login: self.login, password: self.passw)
    }

    func tryToLog() async -> Bool {
        if await databaseManager.login(enteredLogin: self.login, enteredPassword: self.passw) ?? false {
            print("Пользователь \(login) успешно вошел!")
            return true
        } else {
            print("Неверный логин или пароль")
            return false
        }
    }

    private func generateUserIdentifier() async -> String {
        return await databaseManager.generateUniqueID()
    }

    private func isValidLogin(_ login: String) async -> Bool {
        if await databaseManager.isLoginExists(login: login){
            return login.count >= 6
        } else {return false}
    }

    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "InventORY")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

