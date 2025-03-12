// src/framework/middleware/auth_middleware.bal
import ballerina/http;
import ballerina/jwt;
import src.config.auth as authConfig;
import src.framework.http.response_utils as httpUtils;
import src.framework.utils.logger as logger;

public function authMiddleware(http:Caller caller, http:Request req, map<string> params, function () returns error? next) returns error? {
    string? authHeader = req.getHeader("Authorization");
    if authHeader is () {
        logger:logger.warn("No Authorization header provided");
        check httpUtils:sendError(caller, "Unauthorized: No token provided", 401);
        return;
    }

    // Expect "Bearer <token>"
    string[] headerParts = authHeader.split(" ");
    if headerParts.length() != 2 || headerParts[0] != "Bearer" {
        logger:logger.warn("Invalid Authorization header format");
        check httpUtils:sendError(caller, "Unauthorized: Invalid token format", 401);
        return;
    }

    string token = headerParts[1];
    jwt:ValidatorConfig validatorConfig = {
        issuer: authConfig:authConfig.issuer,
        signatureConfig: {
            secret: authConfig:authConfig.secretKey
        }
    };

    jwt:Payload|jwt:Error validationResult = jwt:validate(token, validatorConfig);
    if validationResult is jwt:Error {
        logger:logger.warn("JWT validation failed: " + validationResult.message());
        check httpUtils:sendError(caller, "Unauthorized: Invalid token", 401);
        return;
    }

    // Token is valid; attach payload to request for downstream use
    req.setPayload({ "user": validationResult });
    logger:logger.debug("Authenticated request for user: " + validationResult.sub.toString());
    check next();
}