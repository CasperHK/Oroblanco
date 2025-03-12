// src/framework/routing/router.bal
import ballerina/http;
import src.framework.routing.middleware_pipeline as middlewarePipeline;
import src.framework.core.services as serviceRegistry;

public type RouteHandler function(http:Caller, http:Request, map<string> params) returns error?;

public type Route record {|
    string method;        // HTTP method (e.g., "GET", "POST")
    string path;          // Route path (e.g., "/users/{id}")
    RouteHandler handler; // Handler function or controller action
    middlewarePipeline:Middleware[] middleware; // Middleware stack for this route
|};

// Global route registry
private Route[] routes = [];

// Register a route
public function registerRoute(string method, string path, RouteHandler handler, middlewarePipeline:Middleware[] middleware = []) {
    routes.push({method: method.toUpper(), path, handler, middleware});
    io:println("Registered route: " + method + " " + path);
}

// Convenience functions for common HTTP methods
public function get(string path, RouteHandler handler, middlewarePipeline:Middleware[] middleware = []) {
    registerRoute("GET", path, handler, middleware);
}

public function post(string path, RouteHandler handler, middlewarePipeline:Middleware[] middleware = []) {
    registerRoute("POST", path, handler, middleware);
}

public function put(string path, RouteHandler handler, middlewarePipeline:Middleware[] middleware = []) {
    registerRoute("PUT", path, handler, middleware);
}

public function delete(string path, RouteHandler handler, middlewarePipeline:Middleware[] middleware = []) {
    registerRoute("DELETE", path, handler, middleware);
}

// HTTP service to handle incoming requests
service class RouterService {
    *http:Service;

    resource function 'default [string... segments](http:Caller caller, http:Request req) returns error? {
        string path = "/" + string:'join("/", ...segments);
        string method = req.method;
        map<string> params = {};

        // Find matching route
        Route? matchingRoute = findMatchingRoute(method, path, params);
        if matchingRoute is () {
            check caller->respond({ "error": "Route not found" }, statusCode = 404);
            return;
        }

        // Execute middleware pipeline
        middlewarePipeline:RequestContext context = { caller, req, params };
        check middlewarePipeline:executeMiddleware(matchingRoute.middleware, context);

        // Call the route handler
        check matchingRoute.handler(caller, req, params);
    }
}

// Initialize the router and attach it to the HTTP server
public function initRouter() returns error? {
    http:Listener server = check serviceRegistry:getTypedService<http:Listener>("httpServer");
    RouterService routerService = new;
    check server.attach(routerService, []);
}

// Find a matching route and extract parameters
private function findMatchingRoute(string method, string path, map<string> params) returns Route? {
    foreach var route in routes {
        if route.method != method {
            continue;
        }

        string[] routeSegments = route.path.split("/");
        string[] requestSegments = path.split("/");

        if routeSegments.length() != requestSegments.length() {
            continue;
        }

        boolean matches = true;
        params.removeAll();

        foreach int i in 0 ..< routeSegments.length() {
            string routeSegment = routeSegments[i];
            string requestSegment = requestSegments[i];

            if routeSegment.startsWith("{") && routeSegment.endsWith("}") {
                string paramName = routeSegment.substring(1, routeSegment.length() - 1);
                params[paramName] = requestSegment;
            } else if routeSegment != requestSegment {
                matches = false;
                break;
            }
        }

        if matches {
            return route;
        }
    }
    return ();
}