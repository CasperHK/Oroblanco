// src/framework/core/config_loader.bal
import src.config.app as appConfig;
import src.config.database as dbConfig;
import src.config.auth as authConfig;

public type ConfigMap map<anydata>;

// Load all configurations (placeholder for TOML parsing)
public function loadAllConfigs() returns error? {
    // Hypothetical TOML parsing (replace with real implementation)
    ConfigMap tomlConfig = loadTomlConfig("config.toml");
    
    // Update app config
    appConfig:appConfig = mergeConfig(appConfig:appConfig, tomlConfig["server"] ?: {}, tomlConfig["frontend"] ?: {});
    
    // Update database config
    dbConfig:dbConfig = mergeConfig(dbConfig:dbConfig, tomlConfig["database"] ?: {});
    
    // Update auth config
    authConfig:authConfig = mergeConfig(authConfig:authConfig, tomlConfig["auth"] ?: {});
}

// Merge TOML data into a config record
private function mergeConfig<T>(T defaultConfig, ConfigMap... tomlSections) returns T|error {
    ConfigMap merged = {};
    foreach var section in tomlSections {
        foreach var [key, value] in section.entries() {
            merged[key] = value;
        }
    }
    // Convert merged map to the target record type (simplified)
    return merged.cloneWithType(typeof defaultConfig);
}

// Placeholder for TOML loading (implement with a real TOML parser)
private function loadTomlConfig(string filePath) returns ConfigMap {
    // In a real implementation, parse config.toml here
    // For now, return hardcoded defaults matching src/config/
    return {
        "server": {
            "name": "Oroblanco App",
            "env": "development",
            "debug": true,
            "host": "localhost",
            "port": 3000
        },
        "frontend": {
            "framework": "next",
            "dir": "frontend"
        },
        "database": {
            "type": "postgres",
            "url": "postgres://user:password@localhost:5432/oroblanco_db",
            "username": "user",
            "password": "password",
            "maxPoolSize": 10
        },
        "auth": {
            "authType": "jwt",
            "secretKey": "your-secure-secret-key-here",
            "tokenExpiry": 3600,
            "issuer": "oroblanco"
        }
    };
}