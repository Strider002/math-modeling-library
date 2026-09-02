# Pull Request Checklist

## Purpose

- [ ] The problem and intended outcome are stated.
- [ ] The change is limited to the requested scope.

## Evidence and boundaries

- [ ] Important claims include source, location, version, conditions, and verification status.
- [ ] No third-party full text, private data, credentials, or unlicensed code was added.
- [ ] Limitations and unresolved items are explicit.

## Validation

- [ ] `tools/validate_library.ps1` passed.
- [ ] `tools/validate_github_release.ps1` passed.
- [ ] Routing generation and golden tests were run when routing or entry protocols changed.
- [ ] `CHANGELOG.md` was updated.
