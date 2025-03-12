// src/framework/middleware/validation_middleware.bal
import ballerina/http;
import src.framework.http.response_utils as httpUtils;
import src.framework.utils.logger as logger;

public type ValidationRule record {|
    string field; // Field name in the payload (e.g., "email")
    string rule;  // Rule type (e.g., "required", "email", "min:5")
|};

// Validation middleware factory
public function validationMiddleware(ValidationRule[] rules) 
    returns function(http:Caller, http:Request, map<string>, function () returns error?) returns error? {
    return function(http:Caller caller, http:Request req, map<string> params, function () returns error? next) returns error? {
        json|error payload = req.getJsonPayload();
        if payload is error {
            logger:logger.warn("Invalid JSON payload in request");
            check httpUtils:sendError(caller, "Bad Request: Invalid JSON payload", 400);
            return;
        }

        map<anydata> data = <map<anydata>>payload;
        map<string> errors = {};

        foreach var rule in rules {
            string field = rule.field;
            string ruleType = rule.rule;
            anydata value = data[field];

            match ruleType {
                "required" => {
                    if value is () || (value is string && value.trim().length() == 0) {
                        errors[field] = "The " + field + " field is required";
                    }
                }
                "email" => {
                    if value is string {
                        if !regex:matches(value, "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$") {
                            errors[field] = "The " + field + " must be a valid email address";
                        }
                    } else if value !is () {
                        errors[field] = "The " + field + " must be a string";
                    }
                }
                string s if s.startsWith("min:") => {
                    int minLength = check int:fromString(s.substring(4));
                    if value is string && value.length() < minLength {
                        errors[field] = "The " + field + " must be at least " + minLength.toString() + " characters";
                    }
                }
                _ => {
                    logger:logger.warn("Unknown validation rule: " + ruleType);
                }
            }
        }

        if errors.length() > 0 {
            logger:logger.warn("Validation failed for request: " + errors.toString());
            check httpUtils:sendJson(caller, { "status": "error", "errors": errors }, { statusCode: 422 });
            return;
        }

        logger:logger.debug("Request payload validated successfully");
        check next();
    };
}