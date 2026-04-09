# Security Best Practices — Overview

When this skill is invoked, review the code in the current context against **all 8**
security practices enforced in this project and report any violations found.

## Practices to check

1. **no-pii-in-logs** — No PII or sensitive data in `dev.log()` calls
2. **validate-base-url** — User-supplied base URL enforces `https://`, no path interpolation
3. **parameterized-queries-only** — `customStatement()` only for DDL with hardcoded identifiers
4. **force-https** — HTTPS enforced, no cert-bypass in release builds
5. **sensitive-fields-storage** — Auth tokens go in `flutter_secure_storage`, not `SharedPreferences`
6. **url-launcher-validation** — URLs validated before `launchUrl()` calls
7. **sanitize-error-messages** — No raw SQL, stack traces, or internal class names shown to users
8. **exhaustive-enum-switches** — All `switch` on `SyncStatus` (and any future enums) are exhaustive

## How to use

When invoked, scan the file(s) or change in context for violations of any of the above.
For each violation found, state:
- Which practice is violated
- The file and line number
- A one-line description of the problem
- The corrected code

If no violations are found, confirm that explicitly so the author knows the review passed.
