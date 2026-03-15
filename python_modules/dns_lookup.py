"""
DNS Lookup - Python Module
Melakukan query DNS record untuk berbagai tipe record.
Mendukung: A, AAAA, MX, TXT, NS, CNAME, SOA.
"""

import subprocess
import platform

def query_dns(domain: str, record_type: str) -> list:
    """
    Query DNS menggunakan nslookup atau dig.
    
    Returns:
        list: Baris-baris output dari DNS query
    """
    os_name = platform.system().lower()
    results = []

    try:
        if os_name == "windows":
            # Windows menggunakan nslookup
            cmd = ["nslookup", f"-type={record_type}", domain]
        else:
            # Linux/Mac menggunakan dig
            cmd = ["dig", "+short", record_type, domain]

        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        output = proc.stdout.strip()
        if output:
            results = output.splitlines()
    except FileNotFoundError:
        # Fallback: coba nslookup jika dig tidak ada
        try:
            cmd = ["nslookup", f"-type={record_type}", domain]
            proc = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            results = proc.stdout.strip().splitlines()
        except Exception:
            results = ["[ERROR] Tool DNS tidak ditemukan (dig/nslookup)"]
    except subprocess.TimeoutExpired:
        results = ["[TIMEOUT] Query DNS timeout"]
    except Exception as e:
        results = [f"[ERROR] {e}"]

    return results

def run_dns_lookup():
    """Entry point untuk fitur DNS Lookup."""
    print("  Masukkan domain (misal: google.com):")
    domain = input("  → ").strip()
    if not domain:
        print("  [!] Domain tidak boleh kosong.")
        return

    print("\n  Pilih tipe DNS record:")
    record_types = ["A", "AAAA", "MX", "TXT", "NS", "CNAME", "SOA"]
    for i, rt in enumerate(record_types, 1):
        print(f"  [{i}] {rt}")
    print(f"  [8] Semua record")

    choice = input("  → ").strip()

    print(f"\n  Domain : {domain}")
    print(f"  {'─'*50}")

    # Tentukan record types yang akan di-query
    if choice == "8":
        types_to_query = record_types
    elif choice.isdigit() and 1 <= int(choice) <= 7:
        types_to_query = [record_types[int(choice) - 1]]
    else:
        print("  [!] Pilihan tidak valid.")
        return

    # Query setiap tipe record
    for rtype in types_to_query:
        print(f"\n  \033[93m▸ {rtype} Record:\033[0m")
        results = query_dns(domain, rtype)
        if results:
            for line in results:
                if line.strip():
                    print(f"    {line}")
        else:
            print(f"    (tidak ada record {rtype})")
