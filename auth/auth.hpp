#ifndef AUTH_HPP
#define AUTH_HPP

#include <string>
#include "../database/dbConnection.hpp"

struct LoggedInUser {
    unsigned int userId;
    unsigned int employeeId;
    unsigned int roleId;
    string employeeName;
    string roleName;
    vector<string> permissions;
};
bool login(DBConnection& db, LoggedInUser& currentUser);
bool hasPermission(const LoggedInUser& user,const string& permission);
#endif