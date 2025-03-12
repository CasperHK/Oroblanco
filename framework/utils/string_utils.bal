// src/framework/utils/string_utils.bal
import ballerina/regex;

public function toSlug(string input) returns string {
    // Convert to lowercase, replace spaces with hyphens, remove special chars
    string lower = input.toLowerAscii();
    string noSpaces = regex:replaceAll(lower, "\\s+", "-");
    return regex:replaceAll(noSpaces, "[^a-z0-9-]", "");
}

public function trimPath(string path) returns string {
    // Ensure path starts with "/" and has no trailing "/"
    string trimmed = regex:replaceAll(path, "^/+|/+$", "");
    return "/" + trimmed;
}

public function isEmpty(string input) returns boolean {
    return regex:replaceAll(input, "\\s+", "").length() == 0;
}

public function truncate(string input, int maxLength, string suffix = "...") returns string {
    if input.length() <= maxLength {
        return input;
    }
    return input.substring(0, maxLength - suffix.length()) + suffix;
}