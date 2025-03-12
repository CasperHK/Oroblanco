// src/config/database.bal
import ballerina/sql;
import oroblanco.framework.database as dbFramework;

// Database configuration record
public type DatabaseConfig record {|
    string dbType; // "postgres", "mysql", "mongodb", etc.
    string url;    // Connection string (e.g., "postgres://user:pass@localhost:5432/db")
    string username?;
    string password?;
    int maxPoolSize = 10; // Default connection pool size
|};

// Default database configuration (overridden by TOML at runtime)
public DatabaseConfig dbConfig = {
    dbType: "postgres",
    url: "postgres://user:password@localhost:5432/oroblanco_db",
    username: "user",
    password: "password",
    maxPoolSize: 10
};

// Function to initialize the database connection
public function initDatabase() returns error? {
    // Hypothetical TOML parsing (to be implemented in framework core)
    // dbConfig = parseTomlConfig("config.toml", "database");

    // Initialize database connection based on dbType
    match dbConfig.dbType {
        "postgres"|"mysql" => {
            sql:Client dbClient = check new (dbConfig.url, 
                                            dbConfig.username, 
                                            dbConfig.password, 
                                            connectionPool = {maxOpenConnections: dbConfig.maxPoolSize});
            check dbFramework.registerDatabaseClient(dbClient);
        }
        "mongodb" => {
            // Future MongoDB support (placeholder)
            // mongodb:Client mongoClient = check new (dbConfig.url);
            // check dbFramework.registerMongoClient(mongoClient);
        }
        _ => {
            return error("Unsupported database type: " + dbConfig.dbType);
        }
    }
}