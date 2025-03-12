// src/framework/utils/error_handler.bal
import ballerina/http;
import src.framework.utils.logger as logger;

public type AppError record {|
    string message;
    int statusCode;
    string? details?;
|};

// Create an error response
public function createErrorResponse(string message, int statusCode, string? details = ()) returns json {
    AppError err = { message, statusCode, details };
    logger:logger.error("Error: " + message + (details is string ? " - " + details : ""));
    return {
        "status": "error",
        "message": message,
        "details": details ?: null
    };
}

// Handle an error and send a response to the caller
public function handleError(http:Caller caller, error err, int defaultStatusCode = 500) returns error? {
    string message = err.message();
    int statusCode = defaultStatusCode;
    string? details = err.detail().toString() != "{}" ? err.detail().toString() : ();

    if err is http:Error {
        statusCode = err.statusCode ?: 500;
    }

    json response = createErrorResponse(message, statusCode, details);
    check caller->respond(response, statusCode = statusCode);
}

// Wrap a function to catch and handle errors
public function withErrorHandling(function(http:Caller, http:Request) returns error? handler) 
    returns function(http:Caller, http:Request) returns error? {
    return function(http:Caller caller, http:Request req) returns error? {
        do {
            check handler(caller, req);
        } on fail error e {
            check handleError(caller, e);
        }
    };
}