// src/framework/http/response_utils.bal
import ballerina/http;
import src.framework.utils.logger as logger;
import src.framework.utils.error_handler as errorHandler;

public type ResponseOptions record {|
    int statusCode = 200;
    map<string> headers = {};
    string contentType = "application/json";
|};

// Send a JSON response
public function sendJson(http:Caller caller, json payload, ResponseOptions options = {}) returns error? {
    http:Response response = new;
    response.setJsonPayload(payload);
    response.statusCode = options.statusCode;
    response.setContentType(options.contentType);

    foreach var [key, value] in options.headers.entries() {
        response.setHeader(key, value);
    }

    logger:logger.debug("Sending JSON response with status " + options.statusCode.toString());
    check caller->respond(response);
}

// Send a plain text response
public function sendText(http:Caller caller, string text, ResponseOptions options = {}) returns error? {
    http:Response response = new;
    response.setTextPayload(text);
    response.statusCode = options.statusCode;
    response.setContentType("text/plain");

    foreach var [key, value] in options.headers.entries() {
        response.setHeader(key, value);
    }

    logger:logger.debug("Sending text response with status " + options.statusCode.toString());
    check caller->respond(response);
}

// Redirect to a URL
public function redirect(http:Caller caller, string url, int statusCode = 302) returns error? {
    http:Response response = new;
    response.statusCode = statusCode;
    response.setHeader("Location", url);

    logger:logger.debug("Redirecting to " + url + " with status " + statusCode.toString());
    check caller->respond(response);
}

// Send an error response using error_handler
public function sendError(http:Caller caller, string message, int statusCode = 500, string? details = ()) returns error? {
    json errorResponse = errorHandler:createErrorResponse(message, statusCode, details);
    check sendJson(caller, errorResponse, { statusCode });
}

// Send a frontend-rendered response (placeholder)
public function sendFrontendResponse(http:Caller caller, string framework, string path) returns error? {
    HttpServer httpServer = check serviceRegistry:getTypedService<HttpServer>("httpFramework");
    if !httpServer.hasFrontend(framework) {
        check sendError(caller, "Frontend framework not registered: " + framework, 500);
        return;
    }

    // Placeholder: Render frontend page (e.g., SSR for Next.js)
    string html = "<html><body>Rendered by " + framework + " at " + path + "</body></html>";
    http:Response response = new;
    response.setHtmlPayload(html);
    response.statusCode = 200;
    response.setContentType("text/html");

    logger:logger.debug("Sending frontend response for " + framework + " at " + path);
    check caller->respond(response);
}