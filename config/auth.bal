// src/config/auth.bal
import oroblanco.framework.auth as authFramework;

// Authentication configuration record
public type AuthConfig record {|
    string authType = "jwt"; // "jwt", "oauth2", "session", etc.
    string secretKey;        // Secret for signing tokens (JWT) or sessions
    int tokenExpiry = 3600;  // Token expiry in seconds (default: 1 hour)
    string issuer = "oroblanco"; // Token issuer
    map<string> oauth2?;     // OAuth2-specific settings (e.g., client_id, client_secret)
|};

// Default auth configuration (overridden by TOML at runtime)
public AuthConfig authConfig = {
    authType: "jwt",
    secretKey: "your-secure-secret-key-here",
    tokenExpiry: 3600,
    issuer: "oroblanco"
};

// Function to initialize authentication
public function initAuth() returns error? {
    // Hypothetical TOML parsing (to be implemented in framework core)
    // authConfig = parseTomlConfig("config.toml", "auth");

    // Register auth configuration with the framework
    match authConfig.authType {
        "jwt" => {
            authFramework:JwtConfig jwtConfig = {
                secret: authConfig.secretKey,
                expiry: authConfig.tokenExpiry,
                issuer: authConfig.issuer
            };
            check authFramework.registerJwtAuth(jwtConfig);
        }
        "oauth2" => {
            if authConfig.oauth2 is () {
                return error("OAuth2 configuration missing");
            }
            authFramework:OAuth2Config oauthConfig = check authConfig.oauth2.cloneWithType();
            check authFramework.registerOAuth2Auth(oauthConfig);
        }
        _ => {
            return error("Unsupported auth type: " + authConfig.authType);
        }
    }
}