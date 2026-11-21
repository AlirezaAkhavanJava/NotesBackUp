

**What this lesson covers:** An authentication entity stores the records that keep a user signed in between requests. The `AppUser` from the security lesson answers "who is this person?" but says nothing about whether a particular login session is still valid. The most important authentication entity in a modern API is the **refresh token**, a long-lived credential that lets a client get a new short-lived access token without asking for the password again. Below are the fields it needs and the reason for each.

## Why a separate entity?

Our earlier `httpBasic` setup sends the username and password with every request. That's fine for learning, but in production the common pattern is:

- A **short-lived access token** (often 5 to 15 minutes) that goes with each API request.
- A **refresh token** (days or weeks) that is stored on the server and used only to obtain a new access token.

Access tokens are usually self-contained and not stored, so you can't revoke them instantly. Refresh tokens are stored, so the server can revoke one when a user logs out, changes a password, or reports a stolen device. That stored record is the entity we need.

## The RefreshToken fields

|Field|Type|Required|Why it exists|
|---|---|---|---|
|`id`|`Long`|yes|Primary key|
|`user`|`AppUser` (many-to-one)|yes|Whose session this is. Stored as `user_id`|
|`tokenHash`|`String` (unique)|yes|A SHA-256 hash of the token. The raw token is sent to the client once and never stored|
|`familyId`|`UUID`|yes|Groups every token created from one login, so a reused token can revoke the whole family|
|`issuedAt`|`Instant`|yes|When the token was created|
|`expiresAt`|`Instant`|yes|When the token stops being valid, even if never revoked|
|`lastUsedAt`|`Instant`|no|Last time it was exchanged for an access token. Helps show "active sessions" to the user|
|`revokedAt`|`Instant`|no|Set when the token is invalidated. Null means it is still usable|
|`revokedReason`|`String`|no|Why it was revoked, such as `LOGOUT`, `PASSWORD_CHANGED`, or `REUSE_DETECTED`. Helps with auditing|
|`replacedBy`|`RefreshToken` (self-reference)|no|The token that replaced this one during rotation|
|`userAgent`|`String`|no|The browser or app that logged in, so users can recognize their sessions|
|`ipAddress`|`String`|no|Where the login came from. Store it only if your privacy policy allows it|

Three of these deserve more attention.

**`tokenHash` instead of the token.** If the database leaks, stored raw tokens could be used directly to impersonate users. A hash can't be reversed. Unlike passwords, refresh tokens are long random strings, not guessable human choices, so a fast hash like SHA-256 is appropriate here. This is a good contrast with the BCrypt lesson: BCrypt protects guessable passwords, while SHA-256 protects high-entropy random tokens.

**`familyId` and `replacedBy` (rotation).** Each time a refresh token is used, the server issues a new one and marks the old one as replaced. If someone presents an old token that was already replaced, that's a sign it was stolen. The server then revokes every token in the same family, which logs out both the attacker and the real user. Without `familyId`, the server can't tell which tokens belong together.

**`expiresAt` is checked even when `revokedAt` is null.** A token past its expiry must be rejected, just as with the grant lesson. Most databases don't remove expired rows automatically, so a scheduled cleanup job should delete old rows later.

## A Java sketch

```java
@Entity
@Table(name = "refresh_tokens")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RefreshToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser user;

    @Column(name = "token_hash", nullable = false, unique = true, length = 64)
    private String tokenHash;                 // Hex-encoded SHA-256 is always 64 characters

    @Column(name = "family_id", nullable = false)
    private UUID familyId;

    @Column(name = "issued_at", nullable = false, updatable = false)
    private Instant issuedAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "last_used_at")
    private Instant lastUsedAt;

    @Column(name = "revoked_at")
    private Instant revokedAt;

    @Column(name = "revoked_reason", length = 40)
    private String revokedReason;

    @OneToOne
    @JoinColumn(name = "replaced_by_id")
    private RefreshToken replacedBy;

    @Column(name = "user_agent", length = 255)
    private String userAgent;

    @Column(name = "ip_address", length = 45)  // Long enough for an IPv6 address
    private String ipAddress;

    public RefreshToken(AppUser user, String tokenHash, UUID familyId,
                        Instant expiresAt, String userAgent, String ipAddress) {
        this.user = user;
        this.tokenHash = tokenHash;
        this.familyId = familyId;
        this.expiresAt = expiresAt;
        this.userAgent = userAgent;
        this.ipAddress = ipAddress;
        this.issuedAt = Instant.now();
    }

    public boolean isUsable(Instant now) {
        return revokedAt == null && expiresAt.isAfter(now);
    }

    public void revoke(String reason) {
        this.revokedAt = Instant.now();
        this.revokedReason = reason;
    }
}
```

- `@OneToOne` on `replacedBy` links each token to the one that replaced it. It's a self-reference, so it points to the same entity type.
- `length = 64` on `tokenHash` matches the 64 hex characters that SHA-256 produces. A mismatch here would fail at insert.
- `isUsable` puts the validity rule in one place, so the login check and the refresh check can't disagree.

## Other authentication entities you'll likely need

|Entity|Key fields|Purpose|
|---|---|---|
|`PasswordResetToken`|`user`, `tokenHash`, `expiresAt`, `usedAt`|One-time link for resetting a forgotten password. Mark it used so it can't be reused|
|`EmailVerificationToken`|`user`, `tokenHash`, `expiresAt`, `verifiedAt`|Confirms the user owns the email address|
|`LoginAttempt`|`username`, `ipAddress`, `succeeded`, `attemptedAt`|Records failed logins to detect brute force and trigger temporary lockouts|

These follow the same pattern as `RefreshToken`: store a hash, record an expiry, and record when the token was used or revoked.

## Common mistakes

1. **Storing the raw refresh token.** Store only its hash, and send the raw value to the client once.
2. **Deleting tokens on logout.** Set `revokedAt` instead, so reuse detection still works.
3. **Forgetting `expiresAt` in the check.** An unrevoked but expired token must still be rejected.
4. **Using BCrypt for refresh tokens.** BCrypt is slow by design and unnecessary for random, high-entropy tokens. SHA-256 is the right fit here.
5. **Logging the raw token.** Treat it like a password in logs, error messages, and tracing.

## Try it yourself

1. Write the `refresh_tokens` migration for the fields above. Add a unique index on `token_hash`, and a regular index on `user_id` so you can list a user's active sessions quickly.
2. Write a method that takes a raw token, hashes it with SHA-256, and finds the matching row. Explain why the lookup works even though the database never stores the raw token.
3. Simulate reuse detection: rotate a token once, then present the old token again, and describe which rows you would revoke and why.



[[Spring Framework]]