// src/framework/auth/auth_manager.bal
import ballerina/http;
import src.framework.auth.jwt_auth as jwtAuthModule;
import src.framework.core.services as serviceRegistry;
import src.framework.utils.logger as logger;
import src.config.auth as authConfig;

public type AuthStrategy function(http:Caller, http:Request, function (anydata) returns error?) returns error?;

public class AuthManager {
    private map<AuthStrategy> strategies = {};

    public function init() returns error? {
        // Register JWT strategy
        self.strategies["jwt"] = function(http:Caller caller, http:Request req, function (anydata) returns error? next) returns error? {
            check jwtAuthModule:jwtAuth.authenticate(caller, req, function(jwtAuthModule:JwtUser user) returns error? {
                check next(user);
            });
        };

        // Placeholder for OAuth2 strategy
        self.strategies["oauth2"] = function(http:Caller caller, http:Request req, function (anydata) returns error? next) returns error? {
            logger:logger.warn("OAuth2 strategy not yet implemented");
            check httpUtils:sendError(caller, "Authentication method not implemented", 501);
        };

        serviceRegistry:registerService("authManager", self);
        logger:logger.info("AuthManager initialized with strategy: " + authConfig:authConfig.authType);
    }

    // Authenticate a request using the configured strategy
    public function authenticate(http:Caller caller, http:Request req, function (anydata) returns error? next) returns error? {
        string authType = authConfig:authConfig.authType;
        AuthStrategy? strategy = self.strategies[authType];
        if strategy is () {
            logger:logger.error("No authentication strategy registered for: " + authType);
            check httpUtils:sendError(caller, "Authentication method not supported", 501);
            return;
        }

        check strategy(caller, req, next);
    }

    // Register a custom authentication strategy
    public function registerStrategy(string name, AuthStrategy strategy) returns error? {
        if self.strategies.hasKey(name) {
            return error("Authentication strategy '" + name + "' already registered");
        }
        self.strategies[name] = strategy;
        logger:logger.info("Registered custom auth strategy: " + name);
    }

    // Get the authenticated user from the request (if any)
    public function getAuthenticatedUser(http:Request req) returns anydata|error {
        json|error payload = req.getJsonPayload();
        if payload is json && payload["user"] is json {
            return payload["user"];
        }
        return error("No authenticated user found in request");
    }
}

// Singleton AuthManager instance
public final AuthManager authManager = new();

// Initialize the auth manager (called during startup)
public function initAuthManager() returns error? {
    check authManager.init();
}