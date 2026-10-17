#include <iostream>
#include "dbconnection.hpp"
#include <mysqlx/xdevapi.h>
DBConnection::DBConnection(
    const string& host,
    unsigned int port,
    const string& username,
    const string& password,
    const string& database
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
        cout << "Database connection successful!" << endl;
        cout << "Connected to database: " << mySchema.getName() << endl;
        mySession.close();
    }
    catch(const mysqlx::Error& error) {
        cout << "Database connection failed!" << endl;
        cerr << error.what() << '\n';
    }
    
}