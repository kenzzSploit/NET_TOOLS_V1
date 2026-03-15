"""
Port Scanner - Python Module
Melakukan scanning port pada host yang ditentukan.
Menggunakan socket untuk mencoba koneksi TCP ke setiap port.
"""

import socket
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed

# Mapping port umum ke nama layanan
COMMON_PORTS = {
    21: "FTP", 22: "SSH", 23: "Telnet", 25: "SMTP",
    53: "DNS", 80: "HTTP", 110: "POP3", 143: "IMAP",
    443: "HTTPS", 445: "SMB", 3306: "MySQL", 3389: "RDP",
    5432: "PostgreSQL", 6379: "Redis", 8080: "HTTP-Alt",
    8443: "HTTPS-Alt", 27017: "MongoDB", 5900: "VNC",
    587: "SMTP-TLS", 993: "IMAP-SSL", 995: "POP3-SSL",
}

def scan_port(host: str, port: int, timeout: float = 1.0) -> dict:
    """
    Coba koneksi TCP ke satu port.
    
    Returns:
        dict: {'port': int, 'open': bool, 'service': str}
    """
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((host, port))
        sock.close()
        is_open = (result == 0)
    except Exception:
        is_open = False

    service = COMMON_PORTS.get(port, "Unknown")
    return {"port": port, "open": is_open, "service": service}

def run_port_scanner():
    """Entry point untuk fitur Port Scanner."""
    print("  Masukkan host (domain/IP):")
    host = input("  → ").strip()
    if not host:
        print("  [!] Host tidak boleh kosong.")
        return

    print("\n  Pilih mode scan:")
    print("  [1] Common ports (20 port umum)")
    print("  [2] Range port (custom)")
    mode = input("  → ").strip()

    if mode == "1":
        ports = sorted(COMMON_PORTS.keys())
    elif mode == "2":
        try:
            start = int(input("  Port awal: ").strip())
            end   = int(input("  Port akhir: ").strip())
            ports = range(start, end + 1)
        except ValueError:
            print("  [!] Input tidak valid.")
            return
    else:
        print("  [!] Pilihan tidak valid.")
        return

    # Resolve hostname ke IP
    try:
        ip = socket.gethostbyname(host)
        print(f"\n  Target : {host} ({ip})")
        print(f"  Mode   : {'Common Ports' if mode == '1' else 'Custom Range'}")
        print(f"  {'─'*48}")
        print(f"  {'PORT':<8} {'STATUS':<10} {'LAYANAN'}")
        print(f"  {'─'*48}")
    except socket.gaierror:
        print(f"  [ERROR] Tidak dapat resolve host: {host}")
        return

    open_count = 0
    # Gunakan ThreadPoolExecutor untuk scan paralel (lebih cepat)
    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = {executor.submit(scan_port, ip, p): p for p in ports}
        results = []
        for future in as_completed(futures):
            results.append(future.result())

    # Urutkan berdasarkan nomor port
    results.sort(key=lambda x: x["port"])

    for r in results:
        if r["open"]:
            status = "\033[92mOPEN  \033[0m"
            open_count += 1
            print(f"  {r['port']:<8} {status:<10} {r['service']}")
        # Hanya tampilkan open ports

    print(f"\n  {'─'*48}")
    print(f"  Total port terbuka: {open_count} dari {len(list(ports))} port")
