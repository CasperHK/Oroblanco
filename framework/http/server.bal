// src/framework/http/server.bal
import ballerina/http;
import src.framework.core.services as serviceRegistry;
import src.framework.routing.router as router;
import src.framework.utils.logger as logger;

public class HttpServer {
    private http:Listener server;
    private map<string> frontendAdapters = {};

    // Initialize the HTTP server
    public function init(http:Listener listener) returns error? {
        self.server = listener;
        check router:initRouter(); // Attach routing service
        logger:logger.info("HTTP server initialized on port " + listener.local.port.toString());
    }

    // Start the server (called by core/application.bal)
    public function start() returns error? {
        check self.server.start();
        logger:logger.info("HTTP server started");
    }

    // Stop the server gracefully
    public function stop() returns error? {
        check self.server.gracefulStop();
        logger:logger.info("HTTP server stopped");
    }

    // Register a frontend framework adapter
    public function registerFrontend(string framework, string dir) returns error? {
        match framework {
            "next" => {
                logger:logger.info("Registering Next.js frontend adapter at " + dir);
                // Placeholder for Next.js integration (e.g., SSR, API routes)
                self.frontendAdapters[framework] = dir;
                check self.setupNextJsBridge(dir);
            }
            "nuxt" => {
                logger:logger.info("Registering Nuxt.js frontend adapter at " + dir);
                // Placeholder for Nuxt.js integration
                self.frontendAdapters[framework] = dir;
                check self.setupNuxtJsBridge(dir);
            }
            "sveltekit" => {
                logger:logger.info("Registering SvelteKit frontend adapter at " + dir);
                // Placeholder for SvelteKit integration
                self.frontendAdapters[framework] = dir;
                check self.setupSvelteKitBridge(dir);
            }
            _ => {
                return error("Unsupported frontend framework: " + framework);
            }
        }
    }

    // Placeholder for Next.js bridge (SSR/SSG integration)
    private function setupNextJsBridge(string dir) returns error? {
        // Hypothetical: Serve Next.js API routes or SSR pages
        // Could involve spawning a subprocess or proxying requests
        logger:logger.debug("Next.js bridge setup for directory: " + dir);
    }

    // Placeholder for Nuxt.js bridge
    private function setupNuxtJsBridge(string dir) returns error? {
        logger:logger.debug("Nuxt.js bridge setup for directory: " + dir);
    }

    // Placeholder for SvelteKit bridge
    private function setupSvelteKitBridge(string dir) returns error? {
        logger:logger.debug("SvelteKit bridge setup for directory: " + dir);
    }

    // Check if a frontend adapter is registered
    public function hasFrontend(string framework) returns boolean {
        return self.frontendAdapters.hasKey(framework);
    }
}

// Initialize the HTTP server and register it with the service registry
public function initHttpServer(http:Listener listener) returns error? {
    HttpServer httpServer = new();