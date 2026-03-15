"""
Website Status Checker - Python Module
Mengecek status HTTP dari sebuah website.
Menampilkan status code, response time, dan deskripsi status.
"""

import urllib.request
import urllib.error
import time
import ssl

# Deskripsi status code HTTP yang umum
HTTP_STATUS = {
    200: ("OK", "green"),
    201: ("Created", "green"),
    204: ("No Content", "green"),
    301: ("Moved Permanently", "yellow"),
    302: ("Found (Redirect)", "yellow"),
    304: ("Not Modified", "yellow"),
    400: ("Bad Request", "red"),
    401: ("Unauthorized", "red"),
    403: ("Forbidden", "red"),
    404: ("Not Found", "red"),
    405: ("Method Not Allowed", "red"),
    429: ("Too Many Requests", "red"),
    500: ("Internal Server Error", "red"),
    502: ("Bad Gateway", "red"),
    503: ("Service Unavailable", "red"),
    504: ("Gateway Timeout", "red"),
}

COLOR_MAP = {
    "green":  "\033[92m",
    "yellow": "\033[93m",
    "red":    "\033[91m",
    "reset":  "\033[0m",
}

def check_url(url: str) -> dict:
    """
    Kirim GET request ke URL dan kembalikan info response.
    
    Returns:
        dict dengan keys: status_code, response_time_ms, headers, error
    """
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode    = ssl.CERT_NONE

    req = urllib.request.Request(
        url,
        headers={"User-Agent": "NetworkToolkit/1.0"}
    )

    result = {
        "status_code": None,
        "response_time_ms": None,
        "headers": {},
        "error": None,
        "final_url": url,
    }

    try:
        start = time.time()
        resp  = urllib.request.urlopen(req, timeout=10, context=ctx)
        elapsed = (time.time() - start) * 1000

        result["status_code"]      = resp.status
        result["response_time_ms"] = round(elapsed, 1)
        result["headers"]          = dict(resp.headers)
        result["final_url"]        = resp.url

    except urllib.error.HTTPError as e:
        elapsed = (time.time() - start) * 1000
        result["status_code"]      = e.code
        result["response_time_ms"] = round(elapsed, 1)
    except urllib.error.URLError as e:
        result["error"] = str(e.reason)
    except Exception as e:
        result["error"] = str(e)

    return result

def run_website_status():
    """Entry point untuk fitur Website Status Checker."""
    print("  Masukkan URL website (misal: https://google.com):")
    url = input("  → ").strip()
    if not url:
        print("  [!] URL tidak boleh kosong.")
        return

    # Tambahkan https:// jika tidak ada protokol
    if not url.startswith(("http://", "https://")):
        url = "https://" + url

    print(f"\n  Mengecek: {url}")
    print(f"  {'─'*50}")

    result = check_url(url)

    if result["error"]:
        print(f"\n  \033[91m✗ ERROR: {result['error']}\033[0m")
        return

    # Warna berdasarkan status code
    code = result["status_code"]
    desc, color_key = HTTP_STATUS.get(code, ("Unknown", "yellow"))
    color = COLOR_MAP.get(color_key, "")
    reset = COLOR_MAP["reset"]

    print(f"\n  Status Code    : {color}{code} {desc}{reset}")
    print(f"  Response Time  : {result['response_time_ms']} ms")

    if result["final_url"] != url:
        print(f"  Final URL      : {result['final_url']}")

    # Tampilkan beberapa header penting
    important_headers = [
        "Content-Type", "Server", "X-Powered-By",
        "Content-Length", "Cache-Control", "Strict-Transport-Security"
    ]
    print(f"\n  \033[93m▸ Header Penting:\033[0m")
    found = False
    for h in important_headers:
        val = result["headers"].get(h)
        if val:
            print(f"    {h:<30} : {val}")
            found = True
    if not found:
        print(f"    (tidak ada header penting)")

    # Penilaian kecepatan
    rt = result["response_time_ms"]
    print(f"\n  \033[93m▸ Penilaian Response Time:\033[0m")
    if rt < 200:
        print(f"    \033[92m✓ Sangat cepat ({rt} ms)\033[0m")
    elif rt < 500:
        print(f"    \033[92m✓ Normal ({rt} ms)\033[0m")
    elif rt < 1000:
        print(f"    \033[93m⚠ Agak lambat ({rt} ms)\033[0m")
    else:
        print(f"    \033[91m✗ Lambat ({rt} ms)\033[0m")
