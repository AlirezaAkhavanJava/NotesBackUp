

JWT stands for **JSON Web Token**. It's an open standard (RFC 7519) for securely transmitting information between parties as a JSON object.

### How JWT Works (Structure)
A JWT consists of three parts separated by dots (`.`):

```
header.payload.signature
```

1. **Header** (Base64Url encoded JSON)
   Typically contains:
   - `alg`: the signing algorithm (e.g., HS256, RS256, none)
   - `typ`: usually "JWT"

   Example:
   ```json
   {
     "alg": "HS256",
     "typ": "JWT"
   }
   ```

2. **Payload** (Base64Url encoded JSON)
   Contains claims (statements about the user and metadata):
   - **Registered claims** (recommended):
     - `iss` (issuer)
     - `sub` (subject)
     - `aud` (audience)
     - `exp` (expiration time) – Unix timestamp
     - `nbf` (not before)
     - `iat` (issued at)
     - `jti` (JWT ID)
   - **Public claims** (defined by apps)
   - **Private claims** (custom)

   Example:
   ```json
   {
     "sub": "1234567890",
     "name": "John Doe",
     "admin": true,
     "iat": 1516239022,
     "exp": 1732839022
   }
   ```

3. **Signature**
   Created by encoding header + payload and signing with a secret/key using the algorithm specified in the header.

   Example (HS256):
   ```
   HMACSHA256(
     base64UrlEncode(header) + "." + base64UrlEncode(payload),
     secret
   )
   ```

### Common Use Cases
- Authentication (most popular): After login, server issues a JWT. Client sends it in `Authorization: Bearer <token>` header on subsequent requests.
- Information exchange: Securely transmit data between services.

### Pros
- Stateless (no session storage needed on server)
- Compact and URL-safe
- Self-contained (contains all info needed)
- Works well across domains/services

### Cons & Security Warnings
- **Never put sensitive data** (passwords, credit cards) in payload – it’s only Base64 encoded, not encrypted!
- Tokens are valid until expiry (or forever if no `exp`) → use short expiration + refresh tokens
- Cannot be revoked easily (unless using blacklist or short-lived tokens)
- Use HTTPS always
- Validate signature, `exp`, `nbf`, `iss`, `aud` on server


![[Pasted image 20251128094230.png]]
### Example Token (decoded)
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE3MzI4MzkwMjJ9.
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```






##### Tags : [[1 - Spring Security 🍌]]