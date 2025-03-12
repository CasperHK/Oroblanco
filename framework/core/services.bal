// src/framework/core/services.bal
import ballerina/lang.value;

public type Service anydata|error;

// Service registry (singleton map)
private map<Service> services = {};

// Register a service by name
public function registerService(string name, Service service) returns error? {
    if services.hasKey(name) {
        return error("Service '" + name + "' is already registered");
    }
    services[name] = service;
    io:println("Registered service: " + name);
}

// Get a service by name
public function getService(string name) returns Service {
    return services[name] ?: error("Service '" + name + "' not found");
}

// Get a typed service (with type checking)
public function getTypedService<T>(string name) returns T|error {
    Service service = getService(name);
    if service is error {
        return service;
    }
    if service is T {
        return service;
    }
    return error("Service '" + name + "' is not of type " + value:toString(typeof T));
}

// Check if a service exists
public function hasService(string name) returns boolean {
    return services.hasKey(name);
}