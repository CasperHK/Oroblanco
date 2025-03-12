// src/framework/views/renderer.bal
import ballerina/http;
import ballerina/io;
import src.framework.http.response_utils as httpUtils;
import src.framework.utils.logger as logger;
import src.framework.views.template_utils as templateUtils;

public type ViewData map<anydata>;

// Configuration for the view renderer
public type ViewConfig record {|
    string templateDir = "src/resources/views/"; // Default directory for template files
    string extension = ".html";                  // Template file extension
|};

// Global view configuration (could be loaded from TOML)
public ViewConfig viewConfig = {};

// Render a template file and send it as an HTTP response
public function render(http:Caller caller, string templateName, ViewData data = {}, http:ResponseOptions options = {}) returns error? {
    string templatePath = viewConfig.templateDir + templateName + viewConfig.extension;
    string|error templateContent = io:fileReadString(templatePath);

    if templateContent is error {
        logger:logger.error("Failed to load template: " + templatePath + " - " + templateContent.message());
        check httpUtils:sendError(caller, "Template not found: " + templateName, 500);
        return;
    }

    string renderedContent = check templateUtils:processTemplate(templateContent, data);
    http:Response response = new;
    response.setHtmlPayload(renderedContent);
    response.statusCode = options.statusCode;
    response.setContentType("text/html");

    foreach var [key, value] in options.headers.entries() {
        response.setHeader(key, value);
    }

    logger:logger.debug("Rendered template: " + templateName);
    check caller->respond(response);
}

// Render a template string (for inline use or testing)
public function renderString(string templateContent, ViewData data = {}) returns string|error {
    string rendered = check templateUtils:processTemplate(templateContent, data);
    logger:logger.debug("Rendered inline template");
    return rendered;
}