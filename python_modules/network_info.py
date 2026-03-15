"""
Network Information - Python Module
Menampilkan informasi jaringan lokal komputer:
- IP lokal, subnet, gateway
- Interface aktif
- IP publik (dengan query ke API eksternal)
- Info hostname & OS
"""

import socket
import platform
import subprocess
import urllib.request
import json

def get_public_ip() -> str:
    """Ambil IP publik dari layanan API eksternal."""
    apis = [
        "https://api.ipify.org?format=json",
        "https://ifconfig.me/all.json",
        "https://httpbin.org/ip",
    ]
    for api in apis:
        try:
            req  = urllib.request.Request(api, headers={"User-Agent": "NetworkToolkit/1.0"})
            resp = urllib.request.urlopen(req, timeout=5)
            data = json.loads(resp.read().decode())
            # Setiap API punya format berbeda
            ip = data.get("ip") or data.get("origin") or data.get("ip_addr")
            if ip:
                return ip.strip()
        except Exception:
            continue
    return "(tidak dapat mengambil IP publik)"

def get_local_ip() -> str:
    """Ambil IP lokal dengan membuka koneksi dummy."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return socket.gethostbyname(socket.gethostname())

def get_network_interfaces() -> list:
    """Ambil daftar interface jaringan dan IP-nya."""
    interfaces = []
    try:
        hostname = socket.gethostname()
        infos    = socket.getaddrinfo(hostname, None)
        ips      = set()
        for info in infos:
            addr = info[4][0]
            if not addr.startswith("::") and addr != "127.0.0.1":
                ips.add((info[0], addr))

        for family, addr in sorted(ips):
            fam_name = "IPv4" if family == socket.AF_INET else "IPv6"
            interfaces.append({"family": fam_name, "address": addr})
    except Exception:
        pass
    return interfaces

def run_network_info():
    """Entry point untuk fitur Network Information."""
    print(f"  Mengumpulkan informasi jaringan...\n")
    print(f"  {'─'*55}")

    # ── Info Sistem ───────────────────────────────────────
    hostname   = socket.gethostname()
    os_name    = platform.system()
    os_version = platform.version()
    arch       = platform.machine()

    print(f"\n  \033[93m▸ Info Sistem:\033[0m")
    print(f"    Hostname   : {hostname}")
    print(f"    OS         : {os_name} {platform.release()}")
    print(f"    Arsitektur : {arch}")

    # ── IP Lokal ──────────────────────────────────────────
    local_ip = get_local_ip()
    print(f"\n  \033[93m▸ IP Address Lokal:\033[0m")
    print(f"    IP Lokal   : \033[92m{local_ip}\033[0m")
    print(f"    Loopback   : 127.0.0.1")

    # ── Interfaces ────────────────────────────────────────
    interfaces = get_network_interfaces()
    if interfaces:
        print(f"\n  \033[93m▸ Network Interfaces:\033[0m")
        for iface in interfaces:
            print(f"    {iface['family']:<6} : {iface['address']}")

    # ── DNS Servers ───────────────────────────────────────
    print(f"\n  \033[93m▸ DNS Server (resolv.conf / system):\033[0m")
    dns_servers = []
    try:
        if platform.system().lower() != "windows":
            with open("/etc/resolv.conf") as f:
                for line in f:
                    if line.startswith("nameserver"):
                        dns_servers.append(line.split()[1])
        else:
            # Windows: gunakan ipconfig /all
            proc = subprocess.run(["ipconfig", "/all"], capture_output=True, text=True)
            for line in proc.stdout.splitlines():
                if "DNS Servers" in line or "DNS Server" in line:
                    parts = line.split(":")
                    if len(parts) > 1:
                        dns_servers.append(parts[-1].strip())
    except Exception:
        dns_servers = ["(tidak dapat dibaca)"]

    for dns in dns_servers[:3]:
        print(f"    {dns}")
    if not dns_servers:
        print(f"    (tidak dapat membaca DNS server)")

    # ── IP Publik ─────────────────────────────────────────
    print(f"\n  \033[93m▸ IP Publik (Internet):\033[0m")
    print(f"    Mengambil IP publik...", end="", flush=True)
    public_ip = get_public_ip()
    print(f"\r    IP Publik  : \033[92m{public_ip}\033[0m" + " " * 20)

    # ── Konektivitas Internet ─────────────────────────────
    print(f"\n  \033[93m▸ Test Konektivitas Internet:\033[0m")
    test_hosts = [
        ("8.8.8.8",        "Google DNS"),
        ("1.1.1.1",        "Cloudflare DNS"),
        ("google.com",     "Google"),
    ]
    for host, label in test_hosts:
        try:
            socket.setdefaulttimeout(3)
            socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect((host, 53 if "DNS" in label else 80))
            status = "\033[92m✓ Terhubung\033[0m"
        except Exception:
            status = "\033[91m✗ Tidak terhubung\033[0m"
        print(f"    {label:<20} : {status}")
