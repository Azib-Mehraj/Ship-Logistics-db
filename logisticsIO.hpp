
#ifndef LOGISTICS_IO_HPP
#define LOGISTICS_IO_HPP

#include "database/dbConnection.hpp"
#include "auth/auth.hpp"

class EmployeeManager {
private:
    DBConnection& db;//object
    const LoggedInUser& currentUser;//struct
public:
    EmployeeManager(DBConnection& connection, const LoggedInUser& user);

    void showMenu();
    void viewEmployees();
    void addEmployee();
    void updateEmployee();
    void deleteEmployee();
};

class LogisticsApp {
private:
    DBConnection& db;
    const LoggedInUser& currentUser;

public:
    LogisticsApp(DBConnection& connection, const LoggedInUser& user);
    void run();
};
#endif
