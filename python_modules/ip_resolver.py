"""
IP Resolver - Python Module
Meresolve nama domain menjadi IP address menggunakan socket.
Menampilkan semua IP jika domain memiliki multiple A record.
"""

import socket

def run_ip_resolver():
    """Entry point untuk fitur IP Resolver."""
    print("  Masukkan nama domain:")
    domain = input("  → ").strip()
    if not domain:
        print("  [!] Domain tidak boleh kosong.")
        return

    print(f"\n  Domain : {domain}")
    print(f"  {'─'*45}")

    try:
        # getaddrinfo mengembalikan semua IP (IPv4 & IPv6)
        infos = socket.getaddrinfo(domain, None)

        ipv4_list = set()
        ipv6_list = set()

        for info in infos:
            family = info[0]
            addr   = info[4][0]
            if family == socket.AF_INET:
                ipv4_list.add(addr)
            elif family == socket.AF_INET6:
                ipv6_list.add(addr)

        # Tampilkan IPv4
        print(f"\n  \033[93m▸ IPv4 Address:\033[0m")
        if ipv4_list:
            for ip in sorted(ipv4_list):
                print(f"    \033[92m{ip}\033[0m")
        else:
            print(f"    (tidak ditemukan)")

        # Tampilkan IPv6
        print(f"\n  \033[93m▸ IPv6 Address:\033[0m")
        if ipv6_list:
            for ip in sorted(ipv6_list):
                print(f"    \033[96m{ip}\033[0m")
        else:
            print(f"    (tidak ditemukan)")

        # Reverse lookup untuk IP utama
        primary_ip = socket.gethostbyname(domain)
        print(f"\n  \033[93m▸ Primary IP (A Record):\033[0m")
        print(f"    {primary_ip}")

        try:
            hostname = socket.gethostbyaddr(primary_ip)[0]
            print(f"\n  \033[93m▸ Reverse Hostname:\033[0m")
            print(f"    {hostname}")
        except socket.herror:
            pass

    except socket.gaierror as e:
        print(f"\n  \033[91m[ERROR] Tidak dapat resolve domain: {e}\033[0m")
    except Exception as e:
        print(f"\n  \033[91m[ERROR] {e}\033[0m")
