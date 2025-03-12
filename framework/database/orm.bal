// src/framework/database/orm.bal
import ballerina/sql;
import src.framework.database.connection as dbConnection;

public client class ORM {
    private final DatabaseClient client;

    function init() returns error? {
        self.client = dbConnection:getClient();
        if self.client is error {
            return error("Database client not initialized. Call initConnection() first.");
        }
    }

    // Execute a parameterized query and return a table of records
    public remote function queryTyped<RecType>(sql:ParameterizedQuery query) returns table<RecType>|error {
        if self.client is sql:Client {
            stream<RecType, sql:Error?> resultStream = self.client->query(query);
            return resultStream.toTable();
        }
        return error("Database client not available");
    }

    // Execute a parameterized query without returning data (e.g., INSERT, UPDATE, DELETE)
    public remote function execute(sql:ParameterizedQuery query) returns error? {
        if self.client is sql:Client {
            sql:ExecutionResult result = check self.client->execute(query);
            if result.affectedRowCount < 0 {
                return error("Execution failed: No rows affected");
            }
        } else {
            return error("Database client not available");
        }
    }

    // Generic query method (untyped, for flexibility)
    public remote function query(sql:ParameterizedQuery query) returns table<anydata>|error {
        if self.client is sql:Client {
            stream<anydata, sql:Error?> resultStream = self.client->query(query);
            return resultStream.toTable();
        }
        return error("Database client not available");
    }

    // Batch execute multiple queries (e.g., for bulk inserts)
    public remote function batchExecute(sql:ParameterizedQuery[] queries) returns error? {
        if self.client is sql:Client {
            foreach var query in queries {
                check self.client->execute(query);
            }
        } else {
            return error("Database client not available");
        }
    }
}

// Helper function to create an ORM instance
public function newORM() returns ORM|error {
    ORM orm = new();
    check orm.init();
    return orm;
}