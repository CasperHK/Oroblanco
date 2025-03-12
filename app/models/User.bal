// src/app/models/User.bal
import ballerina/sql;
import oroblanco.framework.database as dbFramework;

// User record type representing the database schema
public type User record {|
    int id;          // Auto-incrementing primary key
    string name;     // User's name
    string email;    // User's email (unique)
    string? password?; // Hashed password (optional for OAuth scenarios)
    string createdAt; // Timestamp of creation
    string updatedAt; // Timestamp of last update
|};

// User model class with ORM-like functionality
public class UserModel {
    // Table name for this model
    private final string tableName = "users";

    // Create a new user
    public function create(string name, string email, string password) returns User|error {
        string currentTime = getCurrentTimestamp();
        User newUser = {
            id: 0, // Will be set by the database
            name: name,
            email: email,
            password: check hashPassword(password), // Hypothetical password hashing
            createdAt: currentTime,
            updatedAt: currentTime
        };
        
        sql:ParameterizedQuery query = `INSERT INTO ${self.tableName} 
            (name, email, password, created_at, updated_at) 
            VALUES (${name}, ${email}, ${newUser.password}, ${currentTime}, ${currentTime})
            RETURNING *`;
        
        table<User> result = check dbFramework.query(query);
        return result.getIterator().next() ?: error("Failed to create user");
    }

    // Find a user by ID
    public function find(int id) returns User|error {
        sql:ParameterizedQuery query = `SELECT * FROM ${self.tableName} WHERE id = ${id}`;
        table<User> result = check dbFramework.query(query);
        return result.getIterator().next() ?: error("User not found");
    }

    // Find a user by email
    public function findByEmail(string email) returns User|error {
        sql:ParameterizedQuery query = `SELECT * FROM ${self.tableName} WHERE email = ${email}`;
        table<User> result = check dbFramework.query(query);
        return result.getIterator().next() ?: error("User not found");
    }

    // Update a user by ID
    public function update(int id, record {| string name?; string email?; string password?; |} data) returns User|error {
        string updatedAt = getCurrentTimestamp();
        sql:ParameterizedQuery query = `UPDATE ${self.tableName} 
            SET name = ${data.name ?: (