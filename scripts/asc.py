#!/usr/bin/env python3
"""App Store Connect API helper for Earshot (LiveTranscribe).

Replaces the manual App Store Connect web flow for checking build status and
resubmitting after a rejection — no browser, no login.

Auth: signs an ES256 JWT with the App Store Connect API key. Reads the key id
and issuer id from `.env.appstoreconnect` (gitignored) and the private key from
`~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8`.

Commands:
  status                     Show the in-flight version's state + attached build,
                             and the most recent uploaded builds.
  builds [--limit N]         List recent builds with processing state.
  wait-build N [--timeout S] Poll until build N finishes processing (VALID).
  resubmit N [--yes]         Full resubmit: attach build N to the editable
                             version, cancel any blocking review submission,
                             create a fresh submission, and submit it.

Examples:
  python3 scripts/asc.py status
  python3 scripts/asc.py wait-build 34
  python3 scripts/asc.py resubmit 34 --yes
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

import jwt  # PyJWT (with cryptography) for ES256

APP_ID = "6768166317"          # Earshot (com.briankemler.LiveTranscribe)
PLATFORM = "IOS"
BASE = "https://api.appstoreconnect.apple.com"
AUDIENCE = "appstoreconnect-v1"
REPO_ROOT = Path(__file__).resolve().parent.parent


# --------------------------------------------------------------------------- #
# Auth
# --------------------------------------------------------------------------- #

def _load_env() -> tuple[str, str, Path]:
    """Return (key_id, issuer_id, p8_path) from .env.appstoreconnect + default key dir."""
    env_path = REPO_ROOT / ".env.appstoreconnect"
    if not env_path.exists():
        sys.exit(f"Missing {env_path}")
    key_id = issuer_id = None
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        if k.strip() == "ASC_KEY_ID":
            key_id = v.strip()
        elif k.strip() == "ASC_ISSUER_ID":
            issuer_id = v.strip()
    if not key_id or not issuer_id:
        sys.exit("ASC_KEY_ID / ASC_ISSUER_ID not found in .env.appstoreconnect")
    p8 = Path.home() / ".appstoreconnect" / "private_keys" / f"AuthKey_{key_id}.p8"
    if not p8.exists():
        sys.exit(f"Private key not found at {p8}")
    return key_id, issuer_id, p8


def make_token() -> str:
    key_id, issuer_id, p8 = _load_env()
    now = datetime.now(timezone.utc)
    payload = {
        "iss": issuer_id,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=15)).timestamp()),
        "aud": AUDIENCE,
    }
    return jwt.encode(
        payload,
        p8.read_text(),
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )


# --------------------------------------------------------------------------- #
# HTTP
# --------------------------------------------------------------------------- #

def api(method: str, path: str, token: str, body: dict | None = None) -> dict:
    """Call the ASC API. `path` may be a full URL or a /v1/... path with query."""
    url = path if path.startswith("http") else BASE + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")
        sys.exit(f"HTTP {e.code} {method} {url}\n{detail}")


def q(path: str, **params) -> str:
    """Build a path with URL-encoded query params (filter[x] style keys allowed)."""
    return path + "?" + urllib.parse.urlencode(params)


# --------------------------------------------------------------------------- #
# Resource helpers
# --------------------------------------------------------------------------- #

def editable_version(token: str) -> dict:
    """The in-flight (editable) app store version, or the most recent one."""
    res = api("GET", q(
        f"/v1/apps/{APP_ID}/appStoreVersions",
        **{"filter[platform]": PLATFORM, "limit": "10"},
    ), token)
    versions = res.get("data", [])
    editable_states = {
        "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
        "METADATA_REJECTED", "INVALID_BINARY", "WAITING_FOR_REVIEW",
    }
    for v in versions:
        if v["attributes"]["appStoreState"] in editable_states:
            return v
    if not versions:
        sys.exit("No app store versions found.")
    return versions[0]


def find_build(token: str, build_number: str) -> dict | None:
    res = api("GET", q(
        "/v1/builds",
        **{"filter[app]": APP_ID, "filter[version]": str(build_number), "limit": "1"},
    ), token)
    data = res.get("data", [])
    return data[0] if data else None


# --------------------------------------------------------------------------- #
# Commands
# --------------------------------------------------------------------------- #

def cmd_status(token: str, _args) -> None:
    v = editable_version(token)
    va = v["attributes"]
    print(f"Version {va['versionString']} — {va['appStoreState']}")
    # attached build
    rel = api("GET", f"/v1/appStoreVersions/{v['id']}/build", token)
    b = rel.get("data")
    if b:
        ba = api("GET", f"/v1/builds/{b['id']}", token)["data"]["attributes"]
        print(f"  attached build: {ba.get('version')} ({ba.get('processingState')})")
    else:
        print("  attached build: none")
    print("\nRecent builds:")
    cmd_builds(token, argparse.Namespace(limit=8))


def cmd_builds(token: str, args) -> None:
    res = api("GET", q(
        "/v1/builds",
        **{"filter[app]": APP_ID, "sort": "-version", "limit": str(args.limit)},
    ), token)
    for b in res.get("data", []):
        a = b["attributes"]
        print(f"  build {a.get('version'):<4} {a.get('processingState'):<11} "
              f"uploaded {a.get('uploadedDate', '?')}")


def cmd_wait_build(token: str, args) -> None:
    deadline = time.time() + args.timeout
    while True:
        b = find_build(token, args.build)
        state = b["attributes"]["processingState"] if b else "NOT_FOUND"
        print(f"build {args.build}: {state}")
        if state == "VALID":
            return
        if state in {"INVALID", "FAILED"}:
            sys.exit(f"build {args.build} processing {state}")
        if time.time() > deadline:
            sys.exit(f"timed out waiting for build {args.build} (last: {state})")
        time.sleep(20)
        token = make_token()  # refresh in case of long waits


def cmd_release(token: str, args) -> None:
    """Full new-release flow: ensure an editable appStoreVersion exists for --version,
    set its What's New text, attach the build, and submit to App Review."""
    b = find_build(token, args.build)
    if not b:
        sys.exit(f"build {args.build} not found")
    if b["attributes"]["processingState"] != "VALID":
        sys.exit(f"build {args.build} is {b['attributes']['processingState']}, not VALID")
    build_id = b["id"]

    notes = Path(args.notes_file).read_text().strip() if args.notes_file else None

    # 1. Find an editable version matching --version, or create one.
    res = api("GET", q(
        f"/v1/apps/{APP_ID}/appStoreVersions",
        **{"filter[platform]": PLATFORM, "limit": "10"},
    ), token)
    editable_states = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
                       "METADATA_REJECTED", "INVALID_BINARY"}
    version = next(
        (v for v in res.get("data", [])
         if v["attributes"]["versionString"] == args.version
         and v["attributes"]["appStoreState"] in editable_states),
        None,
    )
    if version:
        print(f"Version {args.version} already exists ({version['attributes']['appStoreState']})")
    else:
        print(f"Creating App Store version {args.version}…")
        version = api("POST", "/v1/appStoreVersions", token, {"data": {
            "type": "appStoreVersions",
            "attributes": {"platform": PLATFORM, "versionString": args.version},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }})["data"]
    version_id = version["id"]

    # 2. What's New on every localization (required for update submissions).
    if notes:
        locs = api("GET", f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations",
                   token).get("data", [])
        for loc in locs:
            print(f"  setting What's New for {loc['attributes'].get('locale')}")
            api("PATCH", f"/v1/appStoreVersionLocalizations/{loc['id']}", token, {"data": {
                "type": "appStoreVersionLocalizations", "id": loc["id"],
                "attributes": {"whatsNew": notes},
            }})

    if not args.yes:
        sys.exit("Version prepared. Re-run with --yes to attach the build and submit.")

    # 3. Attach the build.
    print(f"  attaching build {args.build}…")
    api("PATCH", f"/v1/appStoreVersions/{version_id}/relationships/build", token,
        {"data": {"type": "builds", "id": build_id}})

    # 4. Create + submit the review submission.
    print("  creating review submission…")
    sub = api("POST", "/v1/reviewSubmissions", token, {"data": {
        "type": "reviewSubmissions",
        "attributes": {"platform": PLATFORM},
        "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
    }})["data"]
    sub_id = sub["id"]
    api("POST", "/v1/reviewSubmissionItems", token, {"data": {
        "type": "reviewSubmissionItems",
        "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
        },
    }})
    print("  submitting to App Review…")
    api("PATCH", f"/v1/reviewSubmissions/{sub_id}", token, {"data": {
        "type": "reviewSubmissions", "id": sub_id,
        "attributes": {"submitted": True},
    }})
    print(f"✅ Submitted {args.version} (build {args.build}) to App Review (submission {sub_id}).")


def cmd_resubmit(token: str, args) -> None:
    # 1. Build must exist and be processed.
    b = find_build(token, args.build)
    if not b:
        sys.exit(f"build {args.build} not found")
    state = b["attributes"]["processingState"]
    if state != "VALID":
        sys.exit(f"build {args.build} is {state}, not VALID — run wait-build first")
    build_id = b["id"]

    v = editable_version(token)
    version_id = v["id"]
    print(f"Version {v['attributes']['versionString']} "
          f"({v['attributes']['appStoreState']}) → build {args.build}")

    if not args.yes:
        sys.exit("Refusing to submit without --yes. Re-run with --yes to proceed.")

    # 2. Cancel any blocking review submission that still references this version.
    subs = api("GET", q(
        "/v1/reviewSubmissions",
        **{"filter[app]": APP_ID, "filter[platform]": PLATFORM, "limit": "20"},
    ), token).get("data", [])
    blocking = {"READY_FOR_REVIEW", "WAITING_FOR_REVIEW", "WAITING_FOR_RELEASE",
                "IN_REVIEW", "UNRESOLVED_ISSUES"}
    for s in subs:
        st = s["attributes"].get("state")
        if st in blocking:
            print(f"  canceling blocking submission {s['id']} ({st})")
            api("PATCH", f"/v1/reviewSubmissions/{s['id']}", token,
                {"data": {"type": "reviewSubmissions", "id": s["id"],
                          "attributes": {"canceled": True}}})

    # 3. Attach the build to the version. After canceling a submission the version
    #    takes a moment to unlock, so retry a few times before giving up.
    print(f"  attaching build {args.build} to version…")
    for attempt in range(6):
        try:
            api("PATCH", f"/v1/appStoreVersions/{version_id}/relationships/build",
                token, {"data": {"type": "builds", "id": build_id}})
            break
        except SystemExit:
            if attempt == 5:
                raise
            time.sleep(10)
            token = make_token()

    # 4. Create a fresh review submission + item.
    print("  creating review submission…")
    sub = api("POST", "/v1/reviewSubmissions", token, {"data": {
        "type": "reviewSubmissions",
        "attributes": {"platform": PLATFORM},
        "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
    }})["data"]
    sub_id = sub["id"]
    print(f"  submission {sub_id} created; adding the version as an item…")
    api("POST", "/v1/reviewSubmissionItems", token, {"data": {
        "type": "reviewSubmissionItems",
        "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
        },
    }})

    # 5. Submit.
    print("  submitting to App Review…")
    api("PATCH", f"/v1/reviewSubmissions/{sub_id}", token, {"data": {
        "type": "reviewSubmissions", "id": sub_id,
        "attributes": {"submitted": True},
    }})
    print(f"✅ Submitted build {args.build} to App Review (submission {sub_id}).")


def main() -> None:
    p = argparse.ArgumentParser(description="App Store Connect helper for Earshot")
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("status", help="version state + attached build + recent builds")

    pb = sub.add_parser("builds", help="list recent builds")
    pb.add_argument("--limit", type=int, default=10)

    pw = sub.add_parser("wait-build", help="poll until a build finishes processing")
    pw.add_argument("build")
    pw.add_argument("--timeout", type=int, default=1800)

    pr = sub.add_parser("resubmit", help="attach build + resubmit to App Review")
    pr.add_argument("build")
    pr.add_argument("--yes", action="store_true", help="actually submit")

    pl = sub.add_parser("release", help="create version + What's New + attach build + submit")
    pl.add_argument("build")
    pl.add_argument("--version", required=True, help="marketing version, e.g. 1.0.1")
    pl.add_argument("--notes-file", help="path to the What's New text")
    pl.add_argument("--yes", action="store_true", help="actually attach + submit")

    args = p.parse_args()
    token = make_token()
    {
        "status": cmd_status,
        "builds": cmd_builds,
        "wait-build": cmd_wait_build,
        "resubmit": cmd_resubmit,
        "release": cmd_release,
    }[args.cmd](token, args)


if __name__ == "__main__":
    main()
