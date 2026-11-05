#ifndef DBCONNECTION_HPP
#define DBCONNECTION_HPP

#include <string>
#include <memory>
#include <mysqlx/xdevapi.h>
using namespace std;
class DBConnection {
    private:
    string host;
    unsigned int port;
    string username;
    string password;
    string database;

    unique_ptr<mysqlx::Session> session;
    public:
    DBConnection(
        const string& host,
        unsigned int port,
        const string& username,
        const string& password,
        const string& database
    );
    void connect();
    mysqlx::Session& getSession();
};
#endif