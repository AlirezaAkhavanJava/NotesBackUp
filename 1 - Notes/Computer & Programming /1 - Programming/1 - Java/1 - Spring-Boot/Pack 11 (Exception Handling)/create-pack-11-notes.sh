
#!/usr/bin/env bash
set -euo pipefail

notes=(
    "Exception Hierarchy in Java"
    "Checked vs Unchecked Exceptions"
    "Exception Propagation and Stack Unwinding"
    "Custom Exceptions in Spring Boot"
    "Exception Chaining and Root Causes"
    "Global Exception Handling Internals"
    "ExceptionHandlerExceptionResolver"
    "HandlerExceptionResolver Architecture"
    "Spring MVC Exception Resolution Flow"
    "Exception Handling in Filters"
    "Exception Handling in Spring Security"
    "AuthenticationException and AccessDeniedException"
    "Handling Validation Errors with BindingResult"
    "FieldError and ObjectError"
    "MethodArgumentNotValidException Internals"
    "ConstraintViolationException"
    "MethodValidationException"
    "TypeMismatchException"
    "HttpMessageNotReadableException"
    "HttpMediaTypeNotSupportedException"
    "NoHandlerFoundException and ResourceNotFoundException"
    "ResponseStatusException"
    "ProblemDetail and RFC 9457"
    "ErrorResponse Interface in Spring"
    "ErrorResponseException"
    "Custom ErrorResponse Implementations"
    "Customizing Error Attributes"
    "Spring Boot ErrorController"
    "BasicErrorController Internals"
    "ErrorPageRegistrar and ErrorPage"
    "Error Handling in REST APIs"
    "Consistent API Error Response Design"
    "Logging Exceptions Without Exposing Sensitive Data"
    "Exception Handling and Transaction Rollback"
    "RollbackFor and NoRollbackFor"
    "Exception Handling in Asynchronous Methods"
    "Exception Handling in CompletableFuture"
    "Exception Handling in Scheduled Tasks"
    "Testing Global Exception Handlers"
    "Testing ProblemDetail Responses"
    "Common Exception Handling Design Mistakes"
)

# Find the highest existing numbered Markdown note.
max_number=-1

while IFS= read -r -d '' file; do
    filename="${file#./}"

    if [[ "$filename" =~ ^([0-9]+)\ -\ .*\.md$ ]]; then
        number=$((10#${BASH_REMATCH[1]}))

        if (( number > max_number )); then
            max_number=$number
        fi
    fi
done < <(find . -maxdepth 1 -type f -name '*.md' -print0)

next=$((max_number + 1))
created=0
skipped=0

for title in "${notes[@]}"; do
    # Replace filename-unsafe characters.
    safe_title="${title//\// - }"
    safe_title="${safe_title//:/ -}"

    printf -v filename "%02d - %s.md" "$next" "$safe_title"

    if [[ -e "$filename" ]]; then
        printf 'SKIP: %s\n' "$filename"
        ((skipped+=1))
    else
        printf '[[Spring Framework]]\n' > "$filename"
        printf 'CREATED: %s\n' "$filename"
        ((created+=1))
    fi

    ((next+=1))
done

printf '\nFinished.\nCreated: %d\nSkipped: %d\n' "$created" "$skipped"
