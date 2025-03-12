// src/config/app.bal
import ballerina/http;
import oroblanco.framework.core as coreFramework;

// Application configuration record
public type AppConfig record {|
    string name = "Oroblanco App"; // App name
    string env = "development";    // Environment: "development", "production", etc.
    boolean debug = true;          // Debug mode
    string host = "localhost";     // Server host
    int port = 3000;              // Server port
    string frontendFramework?;     // "next", "nuxt", "sveltekit", or null
    string frontendDir = "frontend"; // Directory for frontend code
|};

// Default app configuration (overridden by TOML at runtime)
public AppConfig appConfig = {
    name: "Oroblanco App",
    env: "development",
    debug: true,
    host: "localhost",
    port: 3000,
    frontendFramework: "next",
    frontendDir: "frontend"
};

// Function to initialize the application
public function initApp() returns error? {
    // Hypothetical TOML parsing (to be implemented in framework core)
    // appConfig = parseTomlConfig("config.toml", "server");
    // Merge with [frontend] section if present

    // Configure HTTP server
    http:Listener server = check new (appConfig.port, host = appConfig.host);
    check coreFramework.registerServer(server);

    // Set debug mode
    coreFramework.setDebugMode(appConfig.debug);

    // Register frontend integration (if any)
    if appConfig.frontendFramework is string {
        match appConfig.frontendFramework {
            "next" => check coreFramework.registerFrontend("next", appConfig.frontendDir);
            "nuxt" => check coreFramework.registerFrontend("nuxt", appConfig.frontendDir);
            "sveltekit" => check coreFramework.registerFrontend("sveltekit", appConfig.frontendDir);
            _ => return error("Unsupported frontend framework: " + appConfig.frontendFramework);
        }
    }
}