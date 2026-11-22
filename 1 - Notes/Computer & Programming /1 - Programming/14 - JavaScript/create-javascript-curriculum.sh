
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(pwd)"

create_pack() {
    local pack="$1"
    shift

    local pack_dir="$ROOT/$pack"
    mkdir -p "$pack_dir"

    local index=0
    local note

    for note in "$@"; do
        local filename
        printf -v filename "%02d - %s.md" "$index" "$note"

        local filepath="$pack_dir/$filename"

        if [[ ! -e "$filepath" ]]; then
            printf '[[JavaScript]]\n' > "$filepath"
            echo "[CREATED] $pack/$filename"
        else
            echo "[SKIPPED] $pack/$filename"
        fi

        ((index += 1))
    done
}

# ==================================================
# PACK 1 - JAVASCRIPT FUNDAMENTALS
# ==================================================

create_pack "Pack 1 (JavaScript Fundamentals)" \
    "Introduction to JavaScript" \
    "JavaScript and ECMAScript" \
    "JavaScript Runtime Environments" \
    "JavaScript Execution Model" \
    "JavaScript Syntax and Statements" \
    "Comments" \
    "Variables" \
    "var" \
    "let" \
    "const" \
    "Primitive Data Types" \
    "Dynamic Typing" \
    "typeof Operator" \
    "Type Coercion" \
    "Truthy and Falsy Values" \
    "Operators" \
    "Arithmetic Operators" \
    "Comparison Operators" \
    "Logical Operators" \
    "Assignment Operators" \
    "Strict Equality" \
    "Null and Undefined" \
    "NaN and Infinity" \
    "Template Literals"

# ==================================================
# PACK 2 - CONTROL FLOW AND FUNCTIONS
# ==================================================

create_pack "Pack 2 (Control Flow and Functions)" \
    "Conditional Statements" \
    "if and else" \
    "else if" \
    "switch Statement" \
    "Ternary Operator" \
    "Loops" \
    "for Loop" \
    "while Loop" \
    "do while Loop" \
    "for of Loop" \
    "for in Loop" \
    "break and continue" \
    "Functions" \
    "Function Declarations" \
    "Function Expressions" \
    "Arrow Functions" \
    "Function Parameters and Arguments" \
    "Default Parameters" \
    "Rest Parameters" \
    "Return Statement" \
    "Callback Functions" \
    "Scope" \
    "Global Scope" \
    "Function Scope" \
    "Block Scope" \
    "Lexical Scope" \
    "Closures" \
    "Hoisting"

# ==================================================
# PACK 3 - OBJECTS AND DATA STRUCTURES
# ==================================================

create_pack "Pack 3 (Objects and Data Structures)" \
    "Objects" \
    "Object Properties" \
    "Object Methods" \
    "Property Access" \
    "Object Destructuring" \
    "Object Shorthand Properties" \
    "Computed Property Names" \
    "Spread Syntax with Objects" \
    "Object.assign" \
    "Object.keys and Object.values" \
    "Object.entries" \
    "Optional Chaining" \
    "Nullish Coalescing" \
    "Arrays" \
    "Array Indexing" \
    "Array Destructuring" \
    "Array Spread Syntax" \
    "Array push and pop" \
    "Array shift and unshift" \
    "Array slice and splice" \
    "Array map" \
    "Array filter" \
    "Array reduce" \
    "Array find and findIndex" \
    "Array some and every" \
    "Array includes" \
    "Array sort" \
    "Array forEach" \
    "Multidimensional Arrays" \
    "Map Data Structure" \
    "Set Data Structure" \
    "WeakMap and WeakSet"

# ==================================================
# PACK 4 - MODERN JAVASCRIPT AND ES MODULES
# ==================================================

create_pack "Pack 4 (Modern JavaScript and ES Modules)" \
    "ECMAScript 2015 ES6" \
    "Modern JavaScript Features" \
    "Destructuring Assignment" \
    "Spread and Rest Syntax" \
    "Enhanced Object Literals" \
    "Arrow Functions in Practice" \
    "Default Parameters" \
    "Optional Chaining" \
    "Nullish Coalescing Operator" \
    "String Methods" \
    "Number and Math Methods" \
    "Modules" \
    "JavaScript Module System" \
    "Named Exports" \
    "Default Exports" \
    "Named Imports" \
    "Module Aliases" \
    "Module Scope" \
    "ES Modules vs CommonJS" \
    "Module Dependency Management"

# ==================================================
# PACK 5 - ADVANCED JAVASCRIPT
# ==================================================

create_pack "Pack 5 (Advanced JavaScript)" \
    "The this Keyword" \
    "this in Global Context" \
    "this in Regular Functions" \
    "this in Arrow Functions" \
    "call apply and bind" \
    "JavaScript Prototypes" \
    "Prototype Chain" \
    "Object.create" \
    "Constructor Functions" \
    "JavaScript Classes" \
    "Class Constructors" \
    "Instance Methods" \
    "Static Methods" \
    "Getters and Setters" \
    "Class Inheritance" \
    "super Keyword" \
    "Private Class Fields" \
    "Encapsulation in JavaScript" \
    "Property Descriptors" \
    "Object Immutability" \
    "Shallow Copy and Deep Copy" \
    "Structured Clone" \
    "Garbage Collection Basics"

# ==================================================
# PACK 6 - ASYNCHRONOUS JAVASCRIPT
# ==================================================

create_pack "Pack 6 (Asynchronous JavaScript)" \
    "Synchronous and Asynchronous Execution" \
    "JavaScript Call Stack" \
    "JavaScript Event Loop" \
    "Task Queue" \
    "Microtask Queue" \
    "Macrotasks and Microtasks" \
    "setTimeout" \
    "setInterval" \
    "Callbacks" \
    "Callback Hell" \
    "Promises" \
    "Promise States" \
    "Promise Chaining" \
    "Promise then catch and finally" \
    "Promise.all" \
    "Promise.allSettled" \
    "Promise.race" \
    "Promise.any" \
    "async and await" \
    "Error Handling with Async Await" \
    "Sequential and Parallel Requests" \
    "Promise Cancellation with AbortController" \
    "AbortSignal and Request Timeouts"

# ==================================================
# PACK 7 - JSON AND DATA SERIALIZATION
# ==================================================

create_pack "Pack 7 (JSON and Data Serialization)" \
    "Introduction to JSON" \
    "JSON Data Types" \
    "JSON Objects and Arrays" \
    "JSON.stringify" \
    "JSON.parse" \
    "JSON Serialization" \
    "JSON Deserialization" \
    "Handling Invalid JSON" \
    "JavaScript Objects vs JSON" \
    "Date Serialization" \
    "Number Precision and JSON" \
    "JSON and Java DTO Compatibility" \
    "Mapping JSON to Java DTOs" \
    "Handling Null and Missing Properties" \
    "JSON Error Response Structures"

# ==================================================
# PACK 8 - BROWSER FUNDAMENTALS
# ==================================================

create_pack "Pack 8 (Browser Fundamentals)" \
    "Browser JavaScript Environment" \
    "Window Object" \
    "Document Object" \
    "DOM Fundamentals" \
    "Selecting DOM Elements" \
    "Modifying DOM Elements" \
    "Creating and Removing Elements" \
    "DOM Attributes and Properties" \
    "Event Handling" \
    "Event Listeners" \
    "Event Object" \
    "Event Bubbling" \
    "Event Capturing" \
    "Event Delegation" \
    "preventDefault and stopPropagation" \
    "HTML Forms" \
    "Form Submission" \
    "FormData API" \
    "Client-Side Form Validation" \
    "Input Events" \
    "Browser Storage" \
    "localStorage" \
    "sessionStorage" \
    "Cookies" \
    "URL and URLSearchParams APIs" \
    "Browser History API" \
    "JavaScript Modules in Browsers"

# ==================================================
# PACK 9 - HTTP AND REST API COMMUNICATION
# ==================================================

create_pack "Pack 9 (HTTP and REST API Communication)" \
    "HTTP Fundamentals for JavaScript Developers" \
    "HTTP Request Structure" \
    "HTTP Response Structure" \
    "HTTP Methods" \
    "HTTP Status Codes" \
    "HTTP Headers" \
    "Content-Type Header" \
    "Accept Header" \
    "Authorization Header" \
    "HTTP Request Body" \
    "Query Parameters" \
    "Path Parameters" \
    "REST API Fundamentals" \
    "REST Resource Representation" \
    "JSON REST APIs" \
    "Fetch API" \
    "fetch GET Requests" \
    "fetch POST Requests" \
    "fetch PUT and PATCH Requests" \
    "fetch DELETE Requests" \
    "Handling HTTP Responses" \
    "Handling HTTP Errors" \
    "Request Headers with Fetch" \
    "Sending JSON with Fetch" \
    "Handling Response JSON" \
    "Handling Network Errors" \
    "Request Timeouts" \
    "AbortController" \
    "CORS Fundamentals" \
    "Preflight Requests" \
    "Credentials and Cross-Origin Requests"

# ==================================================
# PACK 10 - SPRING BOOT API INTEGRATION
# ==================================================

create_pack "Pack 10 (Spring Boot API Integration)" \
    "JavaScript and Spring Boot Architecture" \
    "Frontend and Backend Communication" \
    "Spring Boot REST Controller Integration" \
    "Consuming Spring Boot REST Endpoints" \
    "Java DTOs and JavaScript Objects" \
    "Request DTO Mapping" \
    "Response DTO Mapping" \
    "Spring Boot Validation Error Handling" \
    "Spring Boot Global Exception Responses" \
    "CRUD Operations with Fetch" \
    "Creating Resources with POST" \
    "Reading Resources with GET" \
    "Updating Resources with PUT" \
    "Partially Updating Resources with PATCH" \
    "Deleting Resources with DELETE" \
    "Pagination and Page Requests" \
    "Sorting and Filtering API Requests" \
    "Search Endpoints and Query Parameters" \
    "Handling Empty API Responses" \
    "Handling 204 No Content Responses" \
    "Handling 400 Bad Request Responses" \
    "Handling 401 Unauthorized Responses" \
    "Handling 403 Forbidden Responses" \
    "Handling 404 Not Found Responses" \
    "Handling 409 Conflict Responses" \
    "Handling 500 Internal Server Errors" \
    "Reusable API Client Architecture" \
    "Centralized API Configuration" \
    "API Request and Response Helpers" \
    "Environment-Based API URLs" \
    "Loading and Error States" \
    "Optimistic UI Updates" \
    "Preventing Duplicate Requests"

# ==================================================
# PACK 11 - AUTHENTICATION AND SECURITY
# ==================================================

create_pack "Pack 11 (Authentication and Security)" \
    "Web Authentication Fundamentals" \
    "Authentication vs Authorization" \
    "Session-Based Authentication" \
    "Cookie-Based Authentication" \
    "Token-Based Authentication" \
    "JWT Fundamentals" \
    "JWT Structure" \
    "Access Tokens and Refresh Tokens" \
    "JWT Authentication with Spring Security" \
    "Sending JWT in Authorization Headers" \
    "Handling Expired Access Tokens" \
    "Refresh Token Workflow" \
    "Secure Token Storage" \
    "HttpOnly Cookies" \
    "SameSite Cookie Attribute" \
    "Secure Cookie Attribute" \
    "Session Management" \
    "CSRF Fundamentals" \
    "CSRF Protection with Spring Security" \
    "CORS Configuration in Spring Boot" \
    "Same-Origin Policy" \
    "Cross-Site Scripting XSS" \
    "Preventing XSS Attacks" \
    "Content Security Policy" \
    "Clickjacking and Frame Protection" \
    "Input Validation and Sanitization" \
    "Secure Handling of API Errors" \
    "Authentication State Management" \
    "Logout and Token Invalidation"

# ==================================================
# PACK 12 - JAVASCRIPT TOOLING AND TESTING
# ==================================================

create_pack "Pack 12 (JavaScript Tooling and Testing)" \
    "Node.js Fundamentals" \
    "Node.js vs Browser JavaScript" \
    "Node.js Runtime" \
    "npm Fundamentals" \
    "package.json" \
    "package-lock.json" \
    "npm Install and Update" \
    "npm Scripts" \
    "Dependency Management" \
    "Development Dependencies" \
    "Semantic Versioning" \
    "Vite Fundamentals" \
    "Vite Development Server" \
    "Vite Production Build" \
    "Environment Variables in Vite" \
    "ESLint" \
    "JavaScript Debugging" \
    "Browser Developer Tools" \
    "Network Panel and API Debugging" \
    "Unit Testing Fundamentals" \
    "JavaScript Testing with Vitest" \
    "Mocking API Requests" \
    "Testing Asynchronous Code" \
    "API Integration Testing" \
    "Frontend and Backend Integration Testing"

# ==================================================
# PACK 13 - PRODUCTION AND DEPLOYMENT
# ==================================================

create_pack "Pack 13 (Production and Deployment)" \
    "JavaScript Development and Production Environments" \
    "Environment Configuration" \
    "Vite Environment Modes" \
    "Production Build Process" \
    "Static Asset Optimization" \
    "Minification and Bundling" \
    "Source Maps" \
    "JavaScript Performance Optimization" \
    "Lazy Loading" \
    "Code Splitting" \
    "Browser Caching" \
    "HTTP Cache Headers" \
    "Reverse Proxy and Frontend Backend Communication" \
    "Nginx Static Frontend Hosting" \
    "Nginx Reverse Proxy for Spring Boot" \
    "HTTPS and TLS Fundamentals" \
    "Production API URL Configuration" \
    "Dockerized Frontend and Spring Boot Integration" \
    "Frontend Deployment with Docker" \
    "Production Debugging and Monitoring"

echo
echo "============================================"
echo " JavaScript curriculum created successfully"
echo "============================================"
echo "Location: $ROOT"
echo
echo "Total packs: 13"
