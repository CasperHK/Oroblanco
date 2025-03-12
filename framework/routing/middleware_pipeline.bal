// src/framework/routing/middleware_pipeline.bal
import ballerina/http;

public type Middleware function(http:Caller, http:Request, map<string> params, function () returns error?) returns error?;

public type RequestContext record {|
    http:Caller caller;
    http:Request req;
    map<string> params;
|};

// Execute the middleware pipeline
public function executeMiddleware(Middleware[] middleware, RequestContext context) returns error? {
    if middleware.length() == 0 {
        return;
    }

    function next() returns error? = ();

    // Build the middleware chain in reverse order
    foreach int i in (middleware.length() - 1) ... 0 {
        Middleware current = middleware[i];
        function prevNext() returns error? = next;
        next = () => current(context.caller, context.req, context.params, prevNext);
    }

    // Start the chain
    check next();
}

// Example middleware: Logging
public function loggingMiddleware(http:Caller caller, http:Request req, map<string> params, function () returns error? next) returns error? {
    io:println("Request: " + req.method + " " + req.rawPath);
    check next();
    io:println("Response sent for: " + req.rawPath);
}

// Example middleware: Authentication (placeholder)
public function authMiddleware(http:Caller caller, http:Request req, map<string> params, function () returns error? next) returns error? {
    string? authHeader = req.getHeader("Authorization");
    if authHeader is () {
        check caller->respond({ "error": "Unauthorized" }, statusCode = 401);
        return;
    }
    // Hypothetical token validation
    // if !validateToken(authHeader) {
    //     check caller->respond({ "error": "Invalid token" }, statusCode = 401);
    //     return;
    // }
    check next();
}