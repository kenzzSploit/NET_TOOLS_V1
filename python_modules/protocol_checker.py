"""
Protocol Checker - Python Module
Memeriksa apakah sebuah website mendukung HTTP dan/atau HTTPS.
Mengecek redirect, status code, dan keamanan koneksi.
"""

import socket
import ssl
import urllib.request
import urllib.error

def check_http(host: str) -> dict:
    """Cek koneksi HTTP (port 80)."""
    result = {"supported": False, "status": None, "redirect": None, "error": None}
    try:
        req = urllib.request.Request(
            f"http://{host}",
            headers={"User-Agent": "NetworkToolkit/1.0"}
        )
        # Matikan auto-redirect agar kita bisa lihat redirect URL
        opener = urllib.request.build_opener(urllib.request.HTTPRedirectHandler())
        resp   = opener.open(req, timeout=5)
        result["supported"] = True
        result["status"]    = resp.status
    except urllib.error.HTTPError as e:
        result["supported"] = True
        result["status"]    = e.code
    except urllib.error.URLError as e:
        reason = str(e.reason)
        if "redirect" in reason.lower():
            result["supported"] = True
            result["redirect"]  = reason
        else:
            result["error"] = reason
    except Exception as e:
        result["error"] = str(e)
    return result

def check_https(host: str) -> dict:
    """Cek koneksi HTTPS (port 443) beserta info SSL."""
    result = {
        "supported": False, "status": None,
        "ssl_version": None, "cert_subject": None, "error": None
    }
    try:
        # Buat SSL context
        ctx = ssl.create_default_context()
        req = urllib.request.Request(
            f"https://{host}",
            headers={"User-Agent": "NetworkToolkit/1.0"}
        )
        resp = urllib.request.urlopen(req, timeout=5, context=ctx)
        result["supported"] = True
        result["status"]    = resp.status

        # Ambil info SSL
        try:
            raw_sock = socket.create_connection((host, 443), timeout=5)
            ssl_sock  = ctx.wrap_socket(raw_sock, server_hostname=host)
            cert      = ssl_sock.getpeercert()
            result["ssl_version"] = ssl_sock.version()
            # Ambil CN dari subject
            for field in cert.get("subject", []):
                for key, val in field:
                    if key == "commonName":
                        result["cert_subject"] = val
            ssl_sock.close()
        except Exception:
            pass

    except ssl.SSLError as e:
        result["error"] = f"SSL Error: {e}"
    except urllib.error.HTTPError as e:
        result["supported"] = True
        result["status"]    = e.code
    except urllib.error.URLError as e:
        result["error"] = str(e.reason)
    except Exception as e:
        result["error"] = str(e)
    return result

def run_protocol_checker():
    """Entry point untuk fitur Protocol Checker."""
    print("  Masukkan domain (tanpa http/https):")
    host = input("  → ").strip().replace("http://", "").replace("https://", "").split("/")[0]
    if not host:
        print("  [!] Host tidak boleh kosong.")
        return

    print(f"\n  Target : {host}")
    print(f"  {'─'*50}")

    # ── Cek HTTP ─────────────────────────────────────────
    print(f"\n  \033[93m▸ Protokol HTTP (port 80):\033[0m")
    http_res = check_http(host)
    if http_res["supported"]:
        status_str = f"Status {http_res['status']}" if http_res["status"] else "OK"
        print(f"    \033[92m✓ Supported\033[0m  →  {status_str}")
    elif http_res["error"]:
        print(f"    \033[91m✗ Tidak tersedia\033[0m  →  {http_res['error']}")
    else:
        print(f"    \033[91m✗ Tidak tersedia\033[0m")

    # ── Cek HTTPS ────────────────────────────────────────
    print(f"\n  \033[93m▸ Protokol HTTPS (port 443):\033[0m")
    https_res = check_https(host)
    if https_res["supported"]:
        status_str = f"Status {https_res['status']}" if https_res["status"] else "OK"
        print(f"    \033[92m✓ Supported\033[0m  →  {status_str}")
        if https_res["ssl_version"]:
            print(f"    SSL/TLS Version : {https_res['ssl_version']}")
        if https_res["cert_subject"]:
            print(f"    Cert Subject    : {https_res['cert_subject']}")
    elif https_res["error"]:
        print(f"    \033[91m✗ Tidak tersedia\033[0m  →  {https_res['error']}")
    else:
        print(f"    \033[91m✗ Tidak tersedia\033[0m")

    # ── Rekomendasi ──────────────────────────────────────
    print(f"\n  \033[93m▸ Rekomendasi:\033[0m")
    if https_res["supported"] and http_res["supported"]:
        print(f"    Gunakan HTTPS untuk keamanan yang lebih baik.")
    elif https_res["supported"]:
        print(f"    \033[92mSangat baik! Hanya HTTPS yang aktif.\033[0m")
    elif http_res["supported"]:
        print(f"    \033[91mPeringatan: Hanya HTTP (tidak terenkripsi).\033[0m")
    else:
        print(f"    Tidak ada protokol web yang terdeteksi.")
