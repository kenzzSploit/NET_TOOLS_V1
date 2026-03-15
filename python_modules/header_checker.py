"""
Website Header Checker - Python Module
Mengambil dan menampilkan semua HTTP response headers dari sebuah URL.
Berguna untuk debugging, keamanan, dan analisis server.
"""

import urllib.request
import urllib.error
import ssl

# Header yang dianggap penting untuk keamanan
SECURITY_HEADERS = [
    "Strict-Transport-Security",
    "Content-Security-Policy",
    "X-Frame-Options",
    "X-Content-Type-Options",
    "X-XSS-Protection",
    "Referrer-Policy",
    "Permissions-Policy",
]

def run_header_checker():
    """Entry point untuk fitur Website Header Checker."""
    print("  Masukkan URL website:")
    url = input("  → ").strip()
    if not url:
        print("  [!] URL tidak boleh kosong.")
        return

    if not url.startswith(("http://", "https://")):
        url = "https://" + url

    # SSL context tanpa verifikasi agar bisa cek situs dengan cert bermasalah
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode    = ssl.CERT_NONE

    req = urllib.request.Request(
        url,
        headers={"User-Agent": "NetworkToolkit/1.0"}
    )

    print(f"\n  Target : {url}")
    print(f"  {'─'*60}")

    try:
        resp    = urllib.request.urlopen(req, timeout=10, context=ctx)
        headers = dict(resp.headers)

        # ── Semua Headers ─────────────────────────────────
        print(f"\n  \033[93m▸ Semua Response Headers ({len(headers)} header):\033[0m")
        for key, val in sorted(headers.items()):
            print(f"    \033[96m{key:<35}\033[0m : {val}")

        # ── Security Headers Audit ────────────────────────
        print(f"\n  \033[93m▸ Security Headers Audit:\033[0m")
        for sh in SECURITY_HEADERS:
            # Cek case-insensitive
            found = next((v for k, v in headers.items() if k.lower() == sh.lower()), None)
            if found:
                print(f"    \033[92m✓\033[0m {sh:<35} : {found[:60]}")
            else:
                print(f"    \033[91m✗\033[0m {sh:<35}   \033[91m(tidak ada)\033[0m")

        # ── Info Server ───────────────────────────────────
        server = headers.get("Server") or headers.get("server") or "(tidak diketahui)"
        powered = headers.get("X-Powered-By") or headers.get("x-powered-by") or "(tidak ada)"
        print(f"\n  \033[93m▸ Info Server:\033[0m")
        print(f"    Server       : {server}")
        print(f"    X-Powered-By : {powered}")

    except urllib.error.HTTPError as e:
        print(f"\n  Status Code : {e.code}")
        headers = dict(e.headers)
        for key, val in sorted(headers.items()):
            print(f"  {key:<35} : {val}")
    except urllib.error.URLError as e:
        print(f"\n  \033[91m[ERROR] {e.reason}\033[0m")
    except Exception as e:
        print(f"\n  \033[91m[ERROR] {e}\033[0m")
