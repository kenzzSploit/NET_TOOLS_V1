#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════╗
║           NETWORK TOOLKIT - Main Entry Point             ║
║     Kombinasi Python + Ruby untuk Network Testing        ║
╚══════════════════════════════════════════════════════════╝

File ini adalah entry point utama dari Network Toolkit.
Menampilkan menu CLI dan mendelegasikan task ke Python modules
atau Ruby scripts menggunakan subprocess.
"""

import os
import sys
import subprocess
import time

# ── Import semua Python modules ──────────────────────────
from python_modules.port_scanner      import run_port_scanner
from python_modules.ping_checker      import run_ping_checker
from python_modules.traceroute        import run_traceroute
from python_modules.dns_lookup        import run_dns_lookup
from python_modules.ip_resolver       import run_ip_resolver
from python_modules.protocol_checker  import run_protocol_checker
from python_modules.website_status    import run_website_status
from python_modules.header_checker    import run_header_checker
from python_modules.subdomain_finder  import run_subdomain_finder
from python_modules.network_info      import run_network_info

# ── Warna ANSI untuk terminal ────────────────────────────
class Color:
    RED     = "\033[91m"
    GREEN   = "\033[92m"
    YELLOW  = "\033[93m"
    BLUE    = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN    = "\033[96m"
    WHITE   = "\033[97m"
    BOLD    = "\033[1m"
    RESET   = "\033[0m"
    DIM     = "\033[2m"

def clear_screen():
    """Bersihkan layar terminal."""
    os.system('cls' if os.name == 'nt' else 'clear')

def print_banner():
    """Tampilkan banner utama toolkit."""
    banner = f"""
{Color.CYAN}{Color.BOLD}
 ███╗   ██╗███████╗████████╗    ████████╗ ██████╗  ██████╗ ██╗     
 ████╗  ██║██╔════╝╚══██╔══╝    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     
 ██╔██╗ ██║█████╗     ██║          ██║   ██║   ██║██║   ██║██║     
 ██║╚██╗██║██╔══╝     ██║          ██║   ██║   ██║██║   ██║██║     
 ██║ ╚████║███████╗   ██║          ██║   ╚██████╔╝╚██████╔╝███████╗
 ╚═╝  ╚═══╝╚══════╝   ╚═╝          ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
{Color.RESET}
{Color.YELLOW}         ⚡ Network Toolkit v1.0 - Python + Ruby Edition ⚡{Color.RESET}
{Color.DIM}              For Educational & Network Testing Purposes{Color.RESET}
    """
    print(banner)

def print_menu():
    """Tampilkan menu utama dengan 20 fitur."""
    print(f"\n{Color.BOLD}{Color.WHITE}{'─'*58}{Color.RESET}")
    print(f"{Color.BOLD}{Color.CYAN}  {'MENU UTAMA':^54}{Color.RESET}")
    print(f"{Color.BOLD}{Color.WHITE}{'─'*58}{Color.RESET}")

    # ── Python Tools (1-10) ──
    print(f"\n  {Color.GREEN}{Color.BOLD}[ 🐍 PYTHON TOOLS ]{Color.RESET}")
    menu_python = [
        (" 1", "Port Scanner",             "Scan port pada host tertentu"),
        (" 2", "Ping Checker",             "Cek konektivitas via ICMP ping"),
        (" 3", "Traceroute",               "Lacak jalur paket ke tujuan"),
        (" 4", "DNS Lookup",               "Query DNS record (A, MX, TXT, dll)"),
        (" 5", "IP Resolver",              "Resolve IP dari nama domain"),
        (" 6", "Protocol Checker",         "Cek dukungan HTTP / HTTPS"),
        (" 7", "Website Status Checker",   "Cek status kode HTTP website"),
        (" 8", "Website Header Checker",   "Tampilkan HTTP response headers"),
        (" 9", "Subdomain Finder",         "Cari subdomain umum dari domain"),
        ("10", "Network Information",      "Info jaringan lokal & IP publik"),
    ]
    for num, name, desc in menu_python:
        print(f"  {Color.YELLOW}[{num}]{Color.RESET} {Color.BOLD}{name:<28}{Color.RESET}"
              f"{Color.DIM}{desc}{Color.RESET}")

    # ── Ruby Tools (11-20) ──
    print(f"\n  {Color.MAGENTA}{Color.BOLD}[ 💎 RUBY TOOLS ]{Color.RESET}")
    menu_ruby = [
        ("11", "IP Geolocation Lookup",    "Lokasi geografis dari IP address"),
        ("12", "Whois Lookup",             "Data registrasi domain/IP"),
        ("13", "TCP Port Test",            "Test koneksi TCP ke port tertentu"),
        ("14", "Reverse DNS Lookup",       "Resolve hostname dari IP address"),
        ("15", "Website IP Finder",        "Temukan semua IP dari sebuah domain"),
        ("16", "SSL Certificate Checker",  "Periksa detail sertifikat SSL/TLS"),
        ("17", "Domain Info Checker",      "Info lengkap domain (DNS + Whois)"),
        ("18", "Server Banner Grabber",    "Ambil banner/info dari server"),
        ("19", "Latency Checker",          "Ukur latensi koneksi ke host"),
        ("20", "Packet Sender",            "Kirim request ke server (uji koneksi)"),
    ]
    for num, name, desc in menu_ruby:
        print(f"  {Color.YELLOW}[{num}]{Color.RESET} {Color.BOLD}{name:<28}{Color.RESET}"
              f"{Color.DIM}{desc}{Color.RESET}")

    print(f"\n  {Color.RED}[ 0]{Color.RESET} {Color.BOLD}{'Keluar':28}{Color.RESET}"
          f"{Color.DIM}Exit program{Color.RESET}")
    print(f"\n{Color.BOLD}{Color.WHITE}{'─'*58}{Color.RESET}")

def run_ruby_module(script_name, description):
    """
    Jalankan Ruby script menggunakan subprocess.
    
    Args:
        script_name (str): Nama file Ruby (misal: 'ip_geolocation.rb')
        description (str): Deskripsi fitur untuk ditampilkan
    """
    # Path ke folder ruby_modules
    ruby_dir    = os.path.join(os.path.dirname(__file__), "ruby_modules")
    script_path = os.path.join(ruby_dir, script_name)

    print(f"\n{Color.CYAN}{'─'*58}{Color.RESET}")
    print(f"{Color.BOLD}{Color.MAGENTA}  💎 {description}{Color.RESET}")
    print(f"{Color.CYAN}{'─'*58}{Color.RESET}\n")

    # Cek apakah file Ruby ada
    if not os.path.exists(script_path):
        print(f"{Color.RED}[ERROR] File tidak ditemukan: {script_path}{Color.RESET}")
        return

    # Cek apakah Ruby terinstall
    try:
        result = subprocess.run(["ruby", "--version"],
                                capture_output=True, text=True)
        if result.returncode != 0:
            print(f"{Color.RED}[ERROR] Ruby tidak terinstall atau tidak ditemukan di PATH.{Color.RESET}")
            return
    except FileNotFoundError:
        print(f"{Color.RED}[ERROR] Ruby tidak ditemukan. Silakan install Ruby terlebih dahulu.{Color.RESET}")
        print(f"{Color.YELLOW}  → https://www.ruby-lang.org/en/downloads/{Color.RESET}")
        return

    try:
        # Jalankan Ruby script dengan subprocess
        # stdout/stderr diteruskan langsung ke terminal agar output real-time
        process = subprocess.run(
            ["ruby", script_path],
            text=True
        )
    except KeyboardInterrupt:
        print(f"\n{Color.YELLOW}[INFO] Dibatalkan oleh pengguna.{Color.RESET}")
    except Exception as e:
        print(f"{Color.RED}[ERROR] Gagal menjalankan Ruby script: {e}{Color.RESET}")

def handle_python_tool(choice):
    """
    Routing untuk Python tools (pilihan 1-10).
    
    Args:
        choice (int): Nomor pilihan menu
    """
    print(f"\n{Color.CYAN}{'─'*58}{Color.RESET}")

    tool_map = {
        1:  ("🔍 Port Scanner",           run_port_scanner),
        2:  ("📡 Ping Checker",           run_ping_checker),
        3:  ("🗺️  Traceroute",             run_traceroute),
        4:  ("🌐 DNS Lookup",             run_dns_lookup),
        5:  ("🔗 IP Resolver",            run_ip_resolver),
        6:  ("🔒 Protocol Checker",       run_protocol_checker),
        7:  ("🌍 Website Status Checker", run_website_status),
        8:  ("📋 Header Checker",         run_header_checker),
        9:  ("🔎 Subdomain Finder",       run_subdomain_finder),
        10: ("💻 Network Information",    run_network_info),
    }

    if choice in tool_map:
        label, func = tool_map[choice]
        print(f"{Color.BOLD}{Color.GREEN}  🐍 {label}{Color.RESET}")
        print(f"{Color.CYAN}{'─'*58}{Color.RESET}\n")
        try:
            func()
        except KeyboardInterrupt:
            print(f"\n{Color.YELLOW}[INFO] Dibatalkan oleh pengguna.{Color.RESET}")
        except Exception as e:
            print(f"{Color.RED}[ERROR] {e}{Color.RESET}")

def handle_ruby_tool(choice):
    """
    Routing untuk Ruby tools (pilihan 11-20).
    
    Args:
        choice (int): Nomor pilihan menu
    """
    ruby_map = {
        11: ("ip_geolocation.rb",   "IP Geolocation Lookup"),
        12: ("whois_lookup.rb",     "Whois Lookup"),
        13: ("tcp_port_test.rb",    "TCP Port Test"),
        14: ("dns_reverse_lookup.rb","Reverse DNS Lookup"),
        15: ("website_ip_finder.rb","Website IP Finder"),
        16: ("ssl_checker.rb",      "SSL Certificate Checker"),
        17: ("domain_info.rb",      "Domain Info Checker"),
        18: ("server_banner.rb",    "Server Banner Grabber"),
        19: ("latency_checker.rb",  "Latency Checker"),
        20: ("packet_sender.rb",    "Packet Sender"),
    }

    if choice in ruby_map:
        script, desc = ruby_map[choice]
        run_ruby_module(script, desc)

def main():
    """Fungsi utama: loop menu CLI."""
    clear_screen()
    print_banner()

    while True:
        print_menu()

        try:
            raw = input(f"\n{Color.BOLD}{Color.WHITE}  Pilih menu [0-20]: {Color.RESET}")
        except (KeyboardInterrupt, EOFError):
            print(f"\n\n{Color.YELLOW}  Terima kasih telah menggunakan Network Toolkit!{Color.RESET}\n")
            sys.exit(0)

        # Validasi input
        if not raw.strip().isdigit():
            print(f"{Color.RED}  [!] Input tidak valid. Masukkan angka 0-20.{Color.RESET}")
            time.sleep(1)
            continue

        choice = int(raw.strip())

        if choice == 0:
            print(f"\n{Color.YELLOW}  Terima kasih telah menggunakan Network Toolkit!{Color.RESET}\n")
            sys.exit(0)
        elif 1 <= choice <= 10:
            handle_python_tool(choice)
        elif 11 <= choice <= 20:
            handle_ruby_tool(choice)
        else:
            print(f"{Color.RED}  [!] Pilihan tidak tersedia. Masukkan angka 0-20.{Color.RESET}")
            time.sleep(1)
            continue

        # Jeda sebelum kembali ke menu
        input(f"\n{Color.DIM}  Tekan Enter untuk kembali ke menu...{Color.RESET}")
        clear_screen()
        print_banner()

if __name__ == "__main__":
    main()
