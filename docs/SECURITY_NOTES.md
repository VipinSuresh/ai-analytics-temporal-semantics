# Security notes

The public repository intentionally omits:

- Snowflake usernames
- Programmatic access tokens (PATs)
- `SHOW USER PROGRAMMATIC ACCESS TOKENS ...`
- `ALTER USER ... ADD PROGRAMMATIC ACCESS TOKEN ...`
- account-specific identifiers

Use your own Snowflake account, user, role, and authentication setup locally.

Never commit a live token or secret to Git.
