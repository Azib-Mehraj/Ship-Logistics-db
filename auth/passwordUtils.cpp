#include "passwordUtils.hpp"
#include <iostream>
#include <argon2.h> //password hashing
#include <stdexcept> //throw exceptions
#include <openssl/rand.h> //for random salt
#include <conio.h> //for _getch()

using namespace std;
string hashPassword(const string& password) {
    //input validation
    if (password.empty()) {
        throw invalid_argument("Password cannot be empty.");
    }
    // Argon2id configuration
    constexpr uint32_t timeCost = 2;
    constexpr uint32_t memoryCost = 19 * 1024;
    constexpr uint32_t parallelism = 1;

    constexpr size_t saltLength = 16;
    constexpr size_t hashLength = 32;
    // Generate a cryptographically secure random salt
    string salt(saltLength, '\0');
    if (RAND_bytes(
        reinterpret_cast<unsigned char*>(salt.data()),
        static_cast<int>(salt.size())
    ) != 1) {
        throw runtime_error("Failed to generate random salt.");
    }
    // Buffer for the encoded Argon2 hash
    string encodedHash(512, '\0');
    int result = argon2id_hash_encoded(
        timeCost,
        memoryCost,
        parallelism,
        password.data(),
        password.size(),
        salt.data(),
        salt.size(),
        hashLength,
        encodedHash.data(),
        encodedHash.size()
    );
    if (result != ARGON2_OK) {
        throw runtime_error(argon2_error_message(result));
    }
    encodedHash.resize(encodedHash.find('\0'));
    return encodedHash;
}

bool verifyPassword(const string& password, const string& storedHash) {
    if(password.empty() || storedHash.empty()) return false;

    int result = argon2id_verify(
        storedHash.c_str(),
        password.data(), 
        password.size()
    );
    return result == ARGON2_OK;
}
string getHiddenPassword() {
    string password;
    char ch;
    cout << "Password: ";
    while ((ch = _getch()) != '\r') { // \r loop until Enter
        if (ch == '\b') { // \b if backspace pressed
            if (!password.empty()) {
                password.pop_back();
                cout << "\b \b";
            }
        }
        else {
            password += ch;
            cout << "*";
        }
    }
    cout << "\n";
    return password;
}