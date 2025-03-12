// src/framework/core/application.bal
import ballerina/http;
import src.framework.core.services as serviceRegistry;
import src.framework.core.config_loader as configLoader;
import src.framework.database.connection as dbConnection;
import src.framework.http as httpFramework;
import src.config.app as appConfig;
import src.config.database as dbConfig;
import src.config.auth as authConfig;

public class Application {
    private http:Listener? server = ();
    private boolean isRunning = false;

    // Start the application
    public function start() returns error? {
        if self.isRunning {
            return error("Application is already running");
        }

        // Load configurations from TOML (or use defaults)
        check configLoader:loadAllConfigs();

        // Initialize database
        check dbConnection:initConnection();
        serviceRegistry:registerService("database", dbConnection:getClient());

        // Initialize authentication
        check authConfig:initAuth();
        serviceRegistry:registerService("auth", authConfig:authConfig);

        // Initialize HTTP server
        self.server = check new http:Listener(appConfig:appConfig.port, host = appConfig:appConfig.host);
        check httpFramework:initHttpServer(self.server);
        serviceRegistry:registerService("httpServer", self.server);

        // Register frontend integration (if configured)
        if appConfig:appConfig.frontendFramework is string {
            check self.registerFrontend(appConfig:appConfig.frontendFramework, appConfig:appConfig.frontendDir);
        }

        // Start the server
        check self.server.start();
        self.isRunning = true;
        io:println("Oroblanco application started on " + appConfig:appConfig.host + ":" + appConfig:appConfig.port.toString());
    }

    // Stop the application
    public function stop() returns error? {
        if !self.isRunning || self.server is () {
            return error("Application is not running");
        }

        // Stop the HTTP server
        http:Listener server = <http:Listener>self.server;
        check server.gracefulStop();
        self.isRunning = false;

        // Close database connection
        check dbConnection:closeConnection();

        io:println("Oroblanco application stopped");
    }

    // Register frontend framework integration
    private function registerFrontend(string framework, string dir) returns error? {
        match framework {
            "next" => {
                io:println("Registering Next.js frontend at " + dir);
                // Hypothetical frontend bridge initialization
                // check httpFramework:registerFrontendBridge("next", dir);
            }
            "nuxt" => {
                io:println("Registering Nuxt.js frontend at " + dir);
                // check httpFramework:registerFrontendBridge("nuxt", dir);
            }
            "sveltekit" => {
                io:println("Registering SvelteKit frontend at " + dir);
                // check httpFramework:registerFrontendBridge("sveltekit", dir);
            }
            _ => {
                return error("Unsupported frontend framework: " + framework);
            }
        }
    }

    // Check if the application is running
    public function isRunning() returns boolean {
        return self.isRunning;
    }
}

// Singleton application instance
public final Application app = new();

// Main entry point for the framework
public function startApplication() returns error? {
    check app.start();
}

public function stopApplication() returns error? {
    check app.stop();
}