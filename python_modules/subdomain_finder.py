"""
Subdomain Finder - Python Module
Mencari subdomain umum dari sebuah domain dengan cara brute-force
daftar subdomain yang sering digunakan.
"""

import socket
from concurrent.futures import ThreadPoolExecutor, as_completed

# Daftar subdomain umum yang sering digunakan
COMMON_SUBDOMAINS = [
    "www", "mail", "ftp", "smtp", "pop", "pop3", "imap",
    "webmail", "cpanel", "whm", "admin", "portal", "secure",
    "api", "dev", "staging", "test", "demo", "beta",
    "shop", "store", "blog", "forum", "support", "help",
    "docs", "cdn", "static", "assets", "media", "img",
    "news", "m", "mobile", "app", "dashboard", "panel",
    "vpn", "remote", "ssh", "git", "gitlab", "github",
    "jenkins", "ci", "monitor", "status", "metrics",
    "ns1", "ns2", "mx1", "mx2", "smtp1", "smtp2",
    "old", "new", "backup", "bak", "archive",
]

def check_subdomain(subdomain: str, domain: str) -> dict:
    """
    Coba resolve subdomain ke IP address.
    
    Returns:
        dict: {'subdomain': str, 'fqdn': str, 'ip': str or None}
    """
    fqdn = f"{subdomain}.{domain}"
    try:
        ip = socket.gethostbyname(fqdn)
        return {"subdomain": subdomain, "fqdn": fqdn, "ip": ip}
    except socket.gaierror:
        return {"subdomain": subdomain, "fqdn": fqdn, "ip": None}
    except Exception:
        return {"subdomain": subdomain, "fqdn": fqdn, "ip": None}

def run_subdomain_finder():
    """Entry point untuk fitur Subdomain Finder."""
    print("  Masukkan domain (misal: example.com):")
    domain = input("  → ").strip()
    if not domain:
        print("  [!] Domain tidak boleh kosong.")
        return

    # Bersihkan domain dari protokol
    domain = domain.replace("http://", "").replace("https://", "").split("/")[0]

    print(f"\n  Domain  : {domain}")
    print(f"  Testing : {len(COMMON_SUBDOMAINS)} subdomain umum")
    print(f"  {'─'*55}")
    print(f"  {'SUBDOMAIN':<30} {'IP ADDRESS'}")
    print(f"  {'─'*55}")

    found = []
    total_checked = 0

    # Gunakan thread untuk scan paralel (lebih cepat)
    with ThreadPoolExecutor(max_workers=20) as executor:
        futures = {
            executor.submit(check_subdomain, sub, domain): sub
            for sub in COMMON_SUBDOMAINS
        }

        for future in as_completed(futures):
            result = future.result()
            total_checked += 1

            if result["ip"]:
                found.append(result)
                fqdn  = result["fqdn"]
                ip    = result["ip"]
                print(f"  \033[92m{fqdn:<35}\033[0m {ip}")

    # Ringkasan
    print(f"\n  {'─'*55}")
    print(f"  Subdomain ditemukan : \033[92m{len(found)}\033[0m dari {total_checked} yang dicek")

    if found:
        print(f"\n  \033[93m▸ Daftar Subdomain Aktif:\033[0m")
        for r in sorted(found, key=lambda x: x["fqdn"]):
            print(f"    https://{r['fqdn']}")
    else:
        print(f"\n  \033[91m  Tidak ada subdomain umum yang ditemukan.\033[0m")
        print(f"  (Coba gunakan tool seperti Subfinder untuk pencarian lebih lengkap)")
