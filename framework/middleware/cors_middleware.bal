// src/framework/middleware/cors_middleware.bal
import ballerina/http;
import src.framework.http.response_utils as httpUtils;
import src.framework.utils.logger as logger;

public type CorsConfig record {|
    string allowedOrigins = "*"; // e.g., "http://localhost:3000" or "*"
    string allowedMethods = "GET, POST, PUT, DELETE, OPTIONS";
    string allowedHeaders = "Content-Type, Authorization";
    boolean allowCredentials = false;
    int maxAge = 86400; // 24 hours
|};

// Global CORS configuration (could be loaded from TOML)
public CorsConfig corsConfig = {};

// CORS middleware
public function corsMiddleware(http:Caller caller, http:Request req, map<string> params, function () returns error? next) returns error? {
    // Handle preflight OPTIONS requests
    if req.method == "OPTIONS" {
        http:Response response = new;
        response.statusCode = 204; // No Content
        setCorsHeaders(response);
        logger:logger.debug("Handled CORS preflight request");
        check caller->respond(response);
        return;
    }

    // Add CORS headers to all responses
    http:Response response = new;
    setCorsHeaders(response);
    req.setHeader("Origin", req.getHeader("Origin") ?: "*"); // Echo origin for logging

    logger:logger.debug("Applied CORS headers to request: " + req.method + " " + req.rawPath);
    check next();

    // Note: Response headers are set by the handler or response_utils; this middleware only prepares the request
}

// Helper function to set CORS headers
private function setCorsHeaders(http:Response response) {
    response.setHeader("Access-Control-Allow-Origin", corsConfig.allowedOrigins);
    response.setHeader("Access-Control-Allow-Methods", corsConfig.allowedMethods);
    response.setHeader("Access-Control-Allow-Headers", corsConfig.allowedHeaders);
    if corsConfig.allowCredentials {
        response.setHeader("Access-Control-Allow-Credentials", "true");
    }
    response.setHeader("Access-Control-Max-Age", corsConfig.maxAge.toString());
}