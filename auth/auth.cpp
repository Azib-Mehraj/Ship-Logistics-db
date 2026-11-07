#include "auth.hpp"
#include "passwordUtils.hpp"
#include <iostream>

using namespace std;
bool login(DBConnection& db, LoggedInUser& currentUser) {
    string username;

    cout << "\nUsername: ";
    getline(cin, username);
//check for empty username
    if (username.empty()) {
        cout << "Username cannot be empty.\n";
        return false;
    }
    string password = getHiddenPassword();
    if (password.empty()) {
        cout << "Password cannot be empty.\n";
        return false;
    }

    auto result = db.getSession().sql(
        "SELECT u.user_id, u.employee_id, u.password_hash, "
        "r.role_name, e.employee_name, u.role_id "
        "FROM logistics.users u "
        "JOIN logistics.roles r ON u.role_id = r.role_id "
        "JOIN logistics.employees e ON u.employee_id = e.employee_id "
        "WHERE u.username = ?"
    ).bind(username).execute();
    auto row = result.fetchOne();
    if (!row) {
        cout << "\nInvalid username or password.\n";
        return false;
    }
    string storedHash = row[2].get<string>();
    if (!verifyPassword(password, storedHash)) {
        cout << "\nInvalid username or password.\n";
        return false;
    }
    currentUser.userId = row[0].get<unsigned int>();
    currentUser.employeeId = row[1].get<unsigned int>();
    currentUser.roleName = row[3].get<string>();
    currentUser.employeeName = row[4].get<string>();
    currentUser.roleId = row[5].get<unsigned int>();
//fetch permission from db
    auto permissionResult = db.getSession().sql(
        "SELECT permission_name "
        "FROM logistics.role_permissions "
        "WHERE role_id = ?"
    ).bind(currentUser.roleId).execute();
    auto permissionRow = permissionResult.fetchOne();
    while (permissionRow) {
        currentUser.permissions.push_back(
            permissionRow[0].get<string>()
        );
        permissionRow = permissionResult.fetchOne();
    }
    cout << "\nLogin successful!\n";
    cout << "Welcome, " << currentUser.employeeName << "!\n";
    cout << "Role: " << currentUser.roleName << "\n";
    return true;
}
//checks if user has permission
bool hasPermission(const LoggedInUser& user,const string& permission) {
    for (const string& userPermission : user.permissions) {
        if (userPermission == permission) {
            return true;
        }
    }
    return false;
}