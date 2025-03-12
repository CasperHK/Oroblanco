import app.controllers.HomeController;
import app.controllers.UserController;

public function initRoutes() {
    HomeController home = new();
    routing.get("/", home.index);
    routing.post("/submit", home.submit);

    UserController users = new();
    routing.get("/api/users", users.list);
    routing.get("/api/users/{id}", users.show);
    routing.post("/api/users", users.create);
    routing.put("/api/users/{id}", users.update);
    routing.delete("/api/users/{id}", users.delete);
}