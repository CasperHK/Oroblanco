// src/framework/database/connection.bal
import ballerina/sql;
import config.database as dbConfig;

public type DatabaseClient sql:Client|error; // Union type for SQL client or future NoSQL clients

// Global database client (singleton for simplicity; could be a map for multiple connections)
private DatabaseClient dbClient = error("Database not initialized");

// Initialize the database connection based on config
public function initConnection() returns error? {
    dbConfig:DatabaseConfig config = dbConfig:dbConfig; // From src/config/database.bal
    
    match config.dbType {
        "postgres"|"mysql" => {
            sql:Client client = check new (config.url, 
                                          config.username, 
                                          config.password, 
                                          connectionPool = {maxOpenConnections: config.maxPoolSize});
            dbClient = client;
        }
        "mongodb" => {
            // Placeholder for MongoDB support
            // mongodb:Client mongoClient = check new (config.url);
            // dbClient = mongoClient;
            return error("MongoDB support not yet implemented");
        }
        _ => {
            return error("Unsupported database type: " + config.dbType);
        }
    }
}

// Get the database client (call after initialization)
public function getClient() returns DatabaseClient {
    return dbClient;
}

// Close the database connection
public function closeConnection() returns error? {
    if dbClient is sql:Client {
        check dbClient.close();
        dbClient = error("Database not initialized");
    }
}