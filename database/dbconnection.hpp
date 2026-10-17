#ifndef DBCONNECTION_HPP
#define DBCONNECTION_HPP

#include <string>
using namespace std;
class DBConnection {
    private:
    string host;
    unsigned int port;
    string username;
    string password;
    string database;
    public:
    DBConnection(
        const string& host,
        unsigned int port,
        const string& username,
        const string& password,
        const string& database
    );
    void connect();
};
#endif