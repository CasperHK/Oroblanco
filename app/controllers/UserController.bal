// src/app/controllers/UserController.bal
import ballerina/http;
import oroblanco.framework.http as frameworkHttp;
import app.services.UserService as userService; // Hypothetical service module

public class UserController {
    *frameworkHttp:Controller;
    private final userService:UserService service;

    // Constructor to inject the UserService dependency
    public function init() {
        self.service = new userService:UserService();
    }

    // GET /api/users - List all users
    public function list(http:Caller caller, http:Request req) returns error? {
        userService:User[] users = check self.service.getAllUsers();
        json response = { "status": "success", "data": users.toJson() };
        check caller->respond(response);
    }

    // GET /api/users/{id} - Get a single user by ID
    public function show(http:Caller caller, http:Request req, string id) returns error? {
        userService:User|error user = self.service.getUserById(id);
        if user is error {
            json errorResponse = { "status": "error", "message": "User not found" };
            check caller->respond(errorResponse, statusCode = 404);
        } else {
            json response = { "status": "success", "data": user.toJson() };
            check caller->respond(response);
        }
    }

    // POST /api/users - Create a new user
    public function create(http:Caller caller, http:Request req) returns error? {
        json|error payload = req.getJsonPayload();
        if payload is error {
            json errorResponse = { "status": "error", "message": "Invalid payload" };
            check caller->respond(errorResponse, statusCode = 400);
        } else {
            userService:User newUser = check self.service.createUser(payload);
            json response = { "status": "success", "data": newUser.toJson() };
            check caller->respond(response, statusCode = 201);
        }
    }

    // PUT /api/users/{id} - Update an existing user
    public function update(http:Caller caller, http:Request req, string id) returns error? {
        json|error payload = req.getJsonPayload();
        if payload is error {
            json errorResponse = { "status": "error", "message": "Invalid payload" };
            check caller->respond(errorResponse, statusCode = 400);
        } else {
            userService:User|error updatedUser = self.service.updateUser(id, payload);
            if updatedUser is error {
                json notFoundResponse = { "status": "error", "message": "User not found" };
                check caller->respond(notFoundResponse, statusCode = 404);
            } else {
                json response = { "status": "success", "data": updatedUser.toJson() };
                check caller->respond(response);
            }
        }
    }

    // DELETE /api/users/{id} - Delete a user
    public function delete(http:Caller caller, http:Request req, string id) returns error? {
        error? result = self.service.deleteUser(id);
        if result is error {
            json errorResponse = { "status": "error", "message": "User not found" };
            check caller->respond(errorResponse, statusCode = 404);
        } else {
            json response = { "status": "success", "message": "User deleted" };
            check caller->respond(response);
        }
    }
}

// Hypothetical User type (defined elsewhere, e.g., in src/app/models/User.bal)
public type User record {
    string id;
    string name;
    string email;
};
