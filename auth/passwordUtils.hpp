#ifndef PASSWORDUTILS_HPP
#define PASSOWORDUTILS_HPP
#include <string>
using namespace std;
string hashPassword(const string& password);
bool verifyPassword(const string& password, const string& storedHash);
string getHiddenPassword();
#endif