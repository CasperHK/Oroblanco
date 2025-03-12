// src/framework/auth/jwt_auth.bal
import ballerina/http;
import ballerina/jwt;
import src.config.auth as authConfig;
import src.framework.utils.logger as logger;
import src.framework.http.response_utils as httpUtils;

public type JwtUser record {|
    string sub; // Subject (e.g., user ID)
    string name?;
    string email?;
    int exp; // Expiry timestamp
    string iss; // Issuer
|};

// JWT authentication service
public class JwtAuth {
    private final jwt:IssuerConfig issuerConfig;

    public function init() {
        self.issuerConfig = {
            issuer: authConfig:authConfig.issuer,
            expTime: authConfig:authConfig.tokenExpiry,
            signatureConfig: {
                secret: authConfig:authConfig.secretKey
            }
        };
    }

    // Generate a JWT for a user
    public function generateToken(JwtUser user) returns string|error {
        jwt:Header header = { alg: "HS256", typ: "JWT" };
        jwt:Payload payload = {
            sub: user.sub,
            iss: user.iss,
            exp: user.exp,
            "name": user.name,
            "email": user.email
        };

        string|jwt:Error token = jwt:issue(header, payload, self.issuerConfig);
        if token is error {
            logger:logger.error("Failed to generate JWT: " + token.message());
            return token;
        }

        logger:logger.debug("Generated JWT for user: " + user.sub);
        return token;
    }

    // Validate a JWT and return the user payload
    public function validateToken(string token) returns JwtUser|error {
        jwt:ValidatorConfig validatorConfig = {
            issuer: authConfig:authConfig.issuer,
            signatureConfig: {
                secret: authConfig:authConfig.secretKey
            }
        };

        jwt:Payload|jwt:Error result = jwt:validate(token, validatorConfig);
        if result is jwt:Error {
            logger:logger.warn("JWT validation failed: " + result.message());
            return result;
        }

        JwtUser user = {
            sub: result.sub ?: "",
            name: result["name"].toString(),
            email: result["email"].toString(),
            exp: result.exp ?: 0,
            iss: result.iss ?: ""
        };
        logger:logger.debug("Validated JWT for user: " + user.sub);
        return user;
    }

    // Middleware-like function to authenticate requests
    public function authenticate(http:Caller caller, http:Request req, function (JwtUser) returns error? next) returns error? {
        string? authHeader = req.getHeader("Authorization");
        if authHeader is () {
            check httpUtils:sendError(caller, "Unauthorized: No token provided", 401);
            return;
        }

        string[] parts = authHeader.split(" ");
        if parts.length() != 2 || parts[0] != "Bearer" {
            check httpUtils:sendError(caller, "Unauthorized: Invalid token format", 401);
            return;
        }

        JwtUser|error user = self.validateToken(parts[1]);
        if user is error {
            check httpUtils:sendError(caller, "Unauthorized: Invalid token", 401);
            return;
        }

        req.setPayload({ "user": user });
        check next(user);
    }
}

// Singleton JWT auth instance
public final JwtAuth jwtAuth = new();