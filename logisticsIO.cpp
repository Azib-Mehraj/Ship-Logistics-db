#include "logisticsIO.hpp"
#include <iostream>
#include <limits>
using namespace std;
//employeeManager constructor
EmployeeManager::EmployeeManager(
    DBConnection& connection,
    const LoggedInUser& user) : 
    db(connection), currentUser(user) {}
//employee management menu
void EmployeeManager::showMenu() {
    int choice;
    do {
        cout << "\n========== EMPLOYEE MANAGEMENT ==========\n";
        cout << "1. View Employees\n";
        cout << "2. Add Employee\n";
        cout << "3. Update Employee\n";
        cout << "4. Delete Employee\n";
        cout << "0. Back to Main Menu\n";
        cout << "=========================================\n";
        if (!(cin >> choice)) {
            cin.clear();
            cin.ignore(10000, '\n');
            cout << "Invalid input. Please enter a number.\n";
            continue;
        }
        switch (choice) {
            case 1:
                EmployeeManager::viewEmployees();
                break;
    
            case 2:
                EmployeeManager::addEmployee();
                break;
    
            // case 3:
            //     EmployeeManager::updateEmployee();
            //     break;
    
            // case 4:
            //     EmployeeManager::deleteEmployee();
            //     break;
    
            case 0:
                cout << "Returning to main menu...\n";
                break;
            default:
                cout << "Invalid choice. Try again.\n";
            }
    } while (choice!=0);
}
//logisticsApp constructor
LogisticsApp::LogisticsApp(
    DBConnection& connection, 
    const LoggedInUser& user) :
    db(connection), currentUser(user) {}
// main application menu
void LogisticsApp::run() {
    int choice;
    do {
        cout << "\n========== SHIP LOGISTICS SYSTEM ==========\n";
        cout << "Welcome, " << currentUser.employeeName << "\n";
        cout << "Role: " << currentUser.roleName << "\n\n";

        cout << "1. Employee Management\n";
        cout << "2. Ship Management (Coming Soon)\n";
        cout << "3. Route Management (Coming Soon)\n";
        cout << "4. Shipment Management (Coming Soon)\n";
        cout << "0. Logout\n";
        cout << "===========================================\n";
        cout << "Enter your choice: ";
        if (!(cin >> choice)) {
            cin.clear();
            cin.ignore(10000, '\n');
            cout << "Invalid input. Please enter a number.\n";
            continue;
        }
        switch(choice) {
            case 1: 
            if (hasPermission(currentUser, "MANAGE_EMPLOYEES")) {
                EmployeeManager employees(db, currentUser);
                employees.showMenu();
            }
            else {
                cout << "Access denied.\n";
            }
            break;
            case 2:
            case 3:
            case 4:
                cout << "This feature is not implemented yet.\n";
                break;
    
            case 0:
                cout << "Logging out...\n";
                break;
    
            default:
                cout << "Invalid choice. Try again.\n"; 
        }
    } while (choice!=0);
}

//employeeManager functions
void EmployeeManager::viewEmployees() {
    try {
        mysqlx::Session& session = db.getSession();
        mysqlx::SqlResult result = session.sql(
            "SELECT employee_id, employee_name "
            "FROM logistics.employees "
            "ORDER BY employee_id"
        ).execute();

        cout << "\n========== EMPLOYEE LIST ==========\n";
        cout << "ID\tEmployee Name\n";
        cout << "-----------------------------------\n";
        bool found = false;
        for (mysqlx::Row row : result) {
            found = true;
            cout << row[0].get<unsigned int>()
                 << "\t"
                 << row[1].get<string>()
                 << "\n";
        }
        if (!found) {
            cout << "No employees found.\n";
        }
        cout << "===================================\n";
    }
    catch (const exception& error) {
        cerr << "Error retrieving employees: "
             << error.what() << "\n";
    }
}

void EmployeeManager::addEmployee() {
    try {
        cin.ignore(numeric_limits<streamsize>::max(), '\n');
        cout << "Enter employee name: ";
        string name;
        getline(cin, name);
        if (name.empty()) {
            cout << "Employee name cannot be empty.\n";
            return;
        }

        mysqlx::Session& session = db.getSession();
        mysqlx::SqlResult result = session.sql(
            "INSERT INTO logistics.employees (employee_name) "
            "VALUES (?)"
        ).bind(name).execute();

        cout << "Employee added successfully!\n";
        cout << "New Employee ID: "
             << result.getAutoIncrementValue() << "\n";
    }
    catch (const exception& error) {
        cerr << "Error inserting employee: "
             << error.what() << "\n";
    }
}



