"""Remove token folders whose identifier no longer exists on-chain.

Usage: python3 .github/cleanup.py [--dry-run]

Folders are looked up in batches; any the batches don't return are removed only
if both /tokens/<id> and /collections/<id> answer 404. A failed batch, or a run
that would remove over 5% of an environment's folders, aborts without deleting.
"""

import json, os, re, shutil, sys, time
import urllib.error, urllib.request

ENVIRONMENTS = [
    ("tokens", "https://api.multiversx.com"),
    ("testnet/tokens", "https://testnet-api.multiversx.com"),
    ("devnet/tokens", "https://devnet-api.multiversx.com"),
]
MAX_DELETE_RATIO = 0.05
HEADERS = {"User-Agent": "mx-assets-cleanup"}
# The API rejects a whole batch (400) if any identifier in it is malformed.
VALID_IDENTIFIER = re.compile(r"^[A-Z0-9]{3,10}-[0-9a-f]{6}$")


def request(url, method="GET"):
    """Return (status, body); retries 429/5xx honoring Retry-After. (None, None) if never answered."""
    for attempt in range(5):
        time.sleep(0.5)  # stay under the public API's rate limit
        wait = 2 ** attempt
        try:
            with urllib.request.urlopen(urllib.request.Request(url, method=method, headers=HEADERS), timeout=30) as response:
                return response.status, response.read()
        except urllib.error.HTTPError as error:
            if error.code != 429 and error.code < 500:
                return error.code, None
            wait = int(error.headers.get("Retry-After", wait)) + 1
        except (urllib.error.URLError, TimeoutError):
            pass
        time.sleep(wait)
    return None, None


def find_missing(api_url, tokens):
    found = set()
    for start in range(0, len(tokens), 50):
        batch = ",".join(tokens[start:start + 50])
        for endpoint, field, extra in (("tokens", "identifier", "&includeMetaESDT=true"), ("collections", "collection", "")):
            status, body = request(f"{api_url}/{endpoint}?identifiers={batch}&fields={field}&size=50{extra}")
            if status != 200:
                sys.exit(f"Aborting: {endpoint} batch lookup on {api_url} answered {status}. Nothing was removed.")
            found.update(item[field] for item in json.loads(body))
    return [t for t in tokens if t not in found
            and all(request(f"{api_url}/{e}/{t}", "HEAD")[0] == 404 for e in ("tokens", "collections"))]


plans = []
for directory, api_url in ENVIRONMENTS:
    folders = sorted(f for f in os.listdir(directory) if os.path.isdir(os.path.join(directory, f)))
    missing = find_missing(api_url, [f for f in folders if VALID_IDENTIFIER.match(f)])
    print(f"{directory}: {len(missing)} of {len(folders)} folders not found on {api_url}")
    print("".join(f"  {directory}/{token}\n" for token in missing), end="")
    malformed = [f for f in folders if not VALID_IDENTIFIER.match(f)]
    if malformed:
        print(f"  kept, not valid identifiers (review manually): {', '.join(malformed)}")
    if folders and len(missing) / len(folders) > MAX_DELETE_RATIO:
        sys.exit(f"Aborting: refusing to remove over {MAX_DELETE_RATIO:.0%} of {directory}. Nothing was removed.")
    plans.append((directory, missing))

for directory, missing in plans:
    for token in missing:
        if "--dry-run" not in sys.argv:
            shutil.rmtree(os.path.join(directory, token))
            print(f"Removed {directory}/{token}")
if "--dry-run" in sys.argv:
    print("Dry run: nothing removed.")
