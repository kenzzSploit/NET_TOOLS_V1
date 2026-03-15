"""
Ping Checker - Python Module
Mengirim ICMP ping ke host dan mengukur response time.
Menggunakan subprocess untuk menjalankan perintah ping OS.
"""

import subprocess
import platform
import re
import time

def run_ping_checker():
    """Entry point untuk fitur Ping Checker."""
    print("  Masukkan host/IP yang ingin di-ping:")
    host = input("  → ").strip()
    if not host:
        print("  [!] Host tidak boleh kosong.")
        return

    try:
        count = int(input("  Jumlah ping [default: 4]: ").strip() or "4")
    except ValueError:
        count = 4

    print(f"\n  Target : {host}")
    print(f"  Count  : {count}x")
    print(f"  {'─'*50}")

    # Perintah ping berbeda di Windows vs Linux/Mac
    os_name = platform.system().lower()
    if os_name == "windows":
        cmd = ["ping", "-n", str(count), host]
    else:
        cmd = ["ping", "-c", str(count), host]

    try:
        # Jalankan ping dan tangkap output secara real-time
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        latencies = []
        for line in process.stdout:
            line = line.rstrip()
            print(f"  {line}")

            # Ekstrak nilai latensi dari output ping
            match = re.search(r"time[=<](\d+\.?\d*)\s*ms", line, re.IGNORECASE)
            if match:
                latencies.append(float(match.group(1)))

        process.wait()

        # Tampilkan ringkasan latensi
        if latencies:
            print(f"\n  {'─'*50}")
            print(f"  Statistik Latensi:")
            print(f"  Min : {min(latencies):.1f} ms")
            print(f"  Max : {max(latencies):.1f} ms")
            print(f"  Avg : {sum(latencies)/len(latencies):.1f} ms")

        if process.returncode == 0:
            print(f"\n  \033[92m✓ Host {host} dapat dijangkau\033[0m")
        else:
            print(f"\n  \033[91m✗ Host {host} tidak dapat dijangkau\033[0m")

    except FileNotFoundError:
        print(f"  [ERROR] Perintah 'ping' tidak ditemukan.")
    except KeyboardInterrupt:
        print(f"\n  [INFO] Ping dihentikan.")
