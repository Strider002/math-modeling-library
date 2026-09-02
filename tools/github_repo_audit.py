#!/usr/bin/env python3
"""Read-only audit of public GitHub repository metadata.

Uses Python's OpenSSL-backed HTTPS stack instead of Windows Schannel.  It does
not clone repositories, execute external code, read credentials, or write files.
The caller can redirect the JSON output after reviewing it.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import ssl
import sys
import urllib.error
import urllib.request


REPOSITORY_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
API_ROOT = "https://api.github.com"


def github_json(path: str) -> tuple[dict, dict[str, str]]:
    request = urllib.request.Request(
        f"{API_ROOT}{path}",
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "math-modeling-library-readonly-audit",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        payload = json.load(response)
        headers = {key.lower(): value for key, value in response.headers.items()}
    return payload, headers


def audit_repository(repository: str) -> dict:
    if not REPOSITORY_RE.fullmatch(repository):
        raise ValueError(f"invalid repository name: {repository!r}")
    owner, name = repository.split("/", 1)
    if owner in {".", ".."} or name in {".", ".."}:
        raise ValueError(f"invalid repository name: {repository!r}")

    metadata, headers = github_json(f"/repos/{repository}")
    default_branch = metadata["default_branch"]
    commit, _ = github_json(f"/repos/{repository}/commits/{default_branch}")
    license_info = metadata.get("license") or {}

    return {
        "repository": metadata["full_name"],
        "html_url": metadata["html_url"],
        "owner_type": metadata["owner"]["type"],
        "default_branch": default_branch,
        "fixed_commit_sha": commit["sha"],
        "license_spdx_id": license_info.get("spdx_id"),
        "archived": metadata["archived"],
        "disabled": metadata["disabled"],
        "visibility": metadata["visibility"],
        "updated_at": metadata["updated_at"],
        "pushed_at": metadata["pushed_at"],
        "api_version": "2022-11-28",
        "rate_limit_remaining": headers.get("x-ratelimit-remaining"),
        "evidence_boundary": (
            "Repository identity, public metadata, license label, and the commit "
            "at the default branch were observed. Mathematical correctness, "
            "paper authorship, reproducibility, and suitability are not proven."
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit public GitHub repository metadata without cloning or executing code."
    )
    parser.add_argument("repository", nargs="+", help="Repository in owner/name form")
    args = parser.parse_args()

    result = {
        "checked_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "python": sys.version.split()[0],
        "openssl": ssl.OPENSSL_VERSION,
        "repositories": [],
    }
    try:
        result["repositories"] = [audit_repository(repo) for repo in args.repository]
    except (ValueError, KeyError, urllib.error.URLError, urllib.error.HTTPError) as exc:
        print(f"AUDIT_ERROR: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 2

    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
