#include <iostream>
#include <stdexcept>
#include "dbconnection.hpp"
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
    session = make_unique<mysqlx::Session>(
        host,
        port,
        username,
        password
    );
    mysqlx::Schema mySchema = session->getSchema(database);
    cout << "Database connection successful!" << endl;
    cout << "Connected to database: " << mySchema.getName() << endl;
}
mysqlx::Session& DBConnection::getSession() {
    if (!session) {
        throw runtime_error("Database session is not connected.");
    }
    return *session;
}