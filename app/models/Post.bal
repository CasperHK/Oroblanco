// src/app/models/Post.bal
import ballerina/sql;
import oroblanco.framework.database as dbFramework;
import app.models.User as userModel;

// Post record type representing the database schema
public type Post record {|
    int id;          // Auto-incrementing primary key
    int userId;      // Foreign key referencing users table
    string title;    // Post title
    string content;  // Post content
    string createdAt; // Timestamp of creation
    string updatedAt; // Timestamp of last update
|};

// Post model class with ORM-like functionality and relationships
public class PostModel {
    private final string tableName = "posts";
    private final userModel:UserModel userModel = new();

    // Create a new post
    public function create(int userId, string title, string content) returns Post|error {
        string currentTime = getCurrentTimestamp();
        Post newPost = {
            id: 0, // Will be set by the database
            userId: userId,
            title: title,
            content: content,
            createdAt: currentTime,
            updatedAt: currentTime
        };
        
        sql:ParameterizedQuery query = `INSERT INTO ${self.tableName} 
            (user_id, title, content, created_at, updated_at) 
            VALUES (${userId}, ${title}, ${content}, ${currentTime}, ${currentTime})
            RETURNING *`;
        
        table<Post> result = check dbFramework.query(query);
        return result.getIterator().next() ?: error("Failed to create post");
    }

    // Find a post by ID
    public function find(int id) returns Post|error {
        sql:ParameterizedQuery query = `SELECT * FROM ${self.tableName} WHERE id = ${id}`;
        table<Post> result = check dbFramework.query(query);
        return result.getIterator().next() ?: error("Post not found");
    }

    // Get the user who authored this post (relationship)
    public function user(Post post) returns userModel:User|error {
        return self.userModel.find(post.userId);
    }

    // Get all posts by a specific user
    public function findByUser(int userId) returns Post[]|error {
        sql:ParameterizedQuery query = `SELECT * FROM ${self.tableName} WHERE user_id = ${userId}`;
        table<Post> result = check dbFramework.query(query);
        return result.toArray();
    }

    // Update a post by ID
    public function update(int id, record {| string title?; string content?; |} data) returns Post|error {
        string updatedAt = getCurrentTimestamp();
        sql:ParameterizedQuery query = `UPDATE ${self.tableName} 
            SET title = ${data.title ?: (check self.find(id)).title}, 
                content = ${data.content ?: (check self.find(id)).content}, 
                updated_at = ${updatedAt}
            WHERE id = ${id}
            RETURNING *`;
        
        table<Post> result = check dbFramework.query(query);
        return result.getIterator().next() ?: error("Failed to update post");
    }

    // Delete a post by ID
    public function delete(int id) returns error? {
        sql:ParameterizedQuery query = `DELETE FROM ${self.tableName} WHERE id = ${id}`;
        check dbFramework.execute(query);
    }

    // Get all posts
    public function all() returns Post[]|error {
        sql:ParameterizedQuery query = `SELECT * FROM ${self.tableName}`;
        table<Post> result = check dbFramework.query(query);
        return result.toArray();
    }
}

// Reuse timestamp helper from User.bal
isolated function getCurrentTimestamp() returns string {
    return "2025-03-12T00:00:00Z"; // Placeholder
}