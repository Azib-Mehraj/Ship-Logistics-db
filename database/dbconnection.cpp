#include <iostream>
#include "dbconnection.hpp"
#include <mysqlx/xdevapi.h>
DBConnection::DBConnection(
    const std::string& host,
    unsigned int port,
    const std::string& username,
    const std::string& password,
    const std::string& database
    ) : host(host),
      port(port),
      username(username),
      password(password),
      database(database) {}
void DBConnection::connect() {
    try {
        mysqlx::Session mySession (
            host,
            port,
            username,
            password
        );
        mysqlx::Schema mySchema = mySession.getSchema(database);
        std::cout << "Database connection successful!" << std::endl;
        std::cout << "Connected to database: "
                  << mySchema.getName() << std::endl;
        mySession.close();
    }
    catch(const mysqlx::Error& error) {
        cout << "Database connection failed!" << endl;
        cerr << error.what() << '\n';
    }
    
}