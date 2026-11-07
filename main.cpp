#include <iostream>
#include <fstream> //fileIO
#include "auth/passwordUtils.hpp"
#include "auth/auth.hpp"
#include <unordered_map>
#include "database/dbConnection.hpp"
#include <stdexcept> //throw exceptions

unordered_map<string, string> loadEnv(const string& filename);

struct loggedInUser {
    unsigned int userId;
    unsigned int employeeId;
    string employeeName;
    string roleName;
};
int main() {
    cout << "Ship Logistics Project" << endl;
    auto env = loadEnv(".env");
    if (!env.count("DB_HOST") ||
        !env.count("DB_PORT") ||
        !env.count("DB_USER") ||
        !env.count("DB_PASSWORD") ||
        !env.count("DB_NAME")) {
        cerr << "Missing required settings in .env" << endl;
        return 1;
    }
    try {
        DBConnection db(
            env.at("DB_HOST"),
            stoul(env.at("DB_PORT")),
            env.at("DB_USER"),
            env.at("DB_PASSWORD"),
            env.at("DB_NAME")
        );
        db.connect();
        LoggedInUser currentUser;
        if (!login(db, currentUser)) {
            return 0;
        }
        cout << "\n--- Permission Test ---\n";
        cout << "Manage employees: "
            << (hasPermission(currentUser, "MANAGE_EMPLOYEES") ? "Yes" : "No")
            << "\n";
        cout << "Manage shipments: "
            << (hasPermission(currentUser, "MANAGE_SHIPMENTS") ? "Yes" : "No")
            << "\n";
        cout << "Delete records: "
            << (hasPermission(currentUser, "DELETE_RECORDS") ? "Yes" : "No")
            << "\n";
    } catch (const std::exception& error) {
        cerr << "Configuration error: " << error.what() << endl;
        return 1;
    }
    
    return 0;
}

unordered_map<string, string> loadEnv(const string& filename) {
    unordered_map<string, string> variables;
    ifstream file(filename);
    string line;
    while (getline(file, line)) {
        if (line.empty() || line[0] == '#') continue;
        size_t separator = line.find('=');
        if (separator == string::npos) continue;
        string key = line.substr(0, separator);
        string value = line.substr(separator + 1);
        variables[key] = value;
    }
    return variables;
}
