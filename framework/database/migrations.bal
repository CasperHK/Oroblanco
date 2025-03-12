// src/framework/database/migrations.bal
import ballerina/sql;
import src.framework.database.orm as ormFramework;

public type Migration record {|
    string id;      // Unique migration ID (e.g., "20250312_create_users_table")
    function up;    // Function to apply the migration
    function down;  // Function to rollback the migration
|};

private ORM orm = check ormFramework:newORM();

// List of registered migrations
private Migration[] migrations = [];

// Initialize the migrations table if it doesn't exist
public function initMigrations() returns error? {
    sql:ParameterizedQuery createTableQuery = `
        CREATE TABLE IF NOT EXISTS migrations (
            id VARCHAR(255) PRIMARY KEY,
            applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`;
    check orm->execute(createTableQuery);
}

// Register a new migration
public function registerMigration(string id, function () returns error? upFunc, function () returns error? downFunc) {
    migrations.push({id: id, up: upFunc, down: downFunc});
}

// Run all pending migrations
public function migrate() returns error? {
    check initMigrations();
    
    table<string> appliedMigrations = check orm->queryTyped<string>(`SELECT id FROM migrations`);
    string[] appliedIds = from var row in appliedMigrations select row.id;

    foreach var migration in migrations {
        if !(appliedIds.some(id => id == migration.id)) {
            check migration.up();
            sql:ParameterizedQuery insertQuery = `INSERT INTO migrations (id) VALUES (${migration.id})`;
            check orm->execute(insertQuery);
            io:println("Applied migration: " + migration.id);
        }
    }
}

// Rollback the last migration
public function rollback() returns error? {
    check initMigrations();
    
    table<string> appliedMigrations = check orm->queryTyped<string>(`SELECT id FROM migrations ORDER BY applied_at DESC LIMIT 1`);
    string? lastMigrationId = appliedMigrations.getIterator().next()?.id;
    
    if lastMigrationId is string {
        Migration? lastMigration = migrations.filter(m => m.id == lastMigrationId)[0];
        if lastMigration is Migration {
            check lastMigration.down();
            sql:ParameterizedQuery deleteQuery = `DELETE FROM migrations WHERE id = ${lastMigrationId}`;
            check orm->execute(deleteQuery);
            io:println("Rolled back migration: " + lastMigrationId);
        }
    }
}

// Example migration: Create users table
public function createUsersTableMigration() {
    registerMigration("20250312_create_users_table",
        function () returns error? {
            sql:ParameterizedQuery query = `
                CREATE TABLE users (
                    id SERIAL PRIMARY KEY,
                    name TEXT NOT NULL,
                    email TEXT UNIQUE NOT NULL,
                    password TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )`;
            check orm->execute(query);
        },
        function () returns error? {
            sql:ParameterizedQuery query = `DROP TABLE users`;
            check orm->execute(query);
        }
    );
}