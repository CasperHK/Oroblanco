// src/framework/utils/logger.bal
import ballerina/io;
import src.config.app as appConfig;

public enum LogLevel {
    DEBUG,
    INFO,
    WARN,
    ERROR
}

// Logger configuration (could be extended with file output, etc.)
public type LoggerConfig record {|
    LogLevel level = INFO; // Minimum level to log
    boolean enabled = true; // Enable/disable logging
|};

// Global logger instance (singleton for simplicity)
public class Logger {
    private LoggerConfig config;

    public function init() {
        self.config = {
            level: appConfig:appConfig.debug ? DEBUG : INFO, // Tie to app debug mode
            enabled: true
        };
    }

    // Log a message if it meets the level threshold
    public function log(LogLevel level, string message) {
        if !self.config.enabled || level < self.config.level {
            return;
        }

        string prefix = "[" + level.toString() + "] " + getTimestamp() + " - ";
        io:println(prefix + message);
    }

    // Convenience methods for each log level
    public function debug(string message) {
        self.log(DEBUG, message);
    }

    public function info(string message) {
        self.log(INFO, message);
    }

    public function warn(string message) {
        self.log(WARN, message);
    }

    public function error(string message) {
        self.log(ERROR, message);
    }

    // Update logger configuration
    public function setLevel(LogLevel level) {
        self.config.level = level;
    }

    public function enable(boolean enabled) {
        self.config.enabled = enabled;
    }
}

// Singleton logger instance
public final Logger logger = new();

// Initialize the logger (called during startup)
public function initLogger() {
    logger.init();
}

// Helper function to get a timestamp
private function getTimestamp() returns string {
    // Placeholder; use a real time library in production (e.g., ballerina/time)
    return "2025-03-12T00:00:00Z";
}