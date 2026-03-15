"""
Traceroute - Python Module
Melacak rute/jalur paket dari komputer lokal ke tujuan.
Setiap hop menunjukkan router/gateway yang dilewati.
"""

import subprocess
import platform

def run_traceroute():
    """Entry point untuk fitur Traceroute."""
    print("  Masukkan host/IP tujuan:")
    host = input("  → ").strip()
    if not host:
        print("  [!] Host tidak boleh kosong.")
        return

    os_name = platform.system().lower()
    
    # Perintah traceroute berbeda di setiap OS
    if os_name == "windows":
        cmd  = ["tracert", "-d", host]   # -d = jangan resolve hostname (lebih cepat)
        tool = "tracert"
    else:
        cmd  = ["traceroute", "-n", host]  # -n = no DNS resolve
        tool = "traceroute"

    print(f"\n  Target : {host}")
    print(f"  Tool   : {tool}")
    print(f"  {'─'*55}")
    print(f"  {'HOP':<5} {'HOST/IP':<20} {'LATENCY'}")
    print(f"  {'─'*55}")

    try:
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        hop_count = 0
        for line in process.stdout:
            line = line.rstrip()
            if line:
                # Filter baris header
                if any(kw in line.lower() for kw in ["traceroute", "tracing", "over a maximum", "hops to"]):
                    continue
                print(f"  {line}")
                hop_count += 1

        process.wait()
        print(f"\n  {'─'*55}")
        print(f"  Total hop: {hop_count}")

    except FileNotFoundError:
        print(f"  [ERROR] '{tool}' tidak ditemukan. Pastikan sudah terinstall.")
        if os_name != "windows":
            print(f"  → Install: sudo apt install traceroute  (Debian/Ubuntu)")
            print(f"  → Install: brew install traceroute      (macOS)")
    except KeyboardInterrupt:
        print(f"\n  [INFO] Traceroute dihentikan.")
