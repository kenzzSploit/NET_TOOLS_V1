# 🌐 Network Toolkit

**Toolkit jaringan berbasis CLI** yang dibangun dengan kombinasi **Python** dan **Ruby**.  
Dirancang untuk keperluan **edukasi** dan **testing jaringan** — bukan untuk aktivitas ilegal.

---

## 📋 Daftar Fitur (20 Tools)

| No | Nama Tool | Bahasa | Fungsi |
|----|-----------|--------|--------|
| 1  | Port Scanner | Python | Scan port TCP pada host |
| 2  | Ping Checker | Python | ICMP ping untuk cek konektivitas |
| 3  | Traceroute | Python | Lacak jalur paket ke tujuan |
| 4  | DNS Lookup | Python | Query A, MX, NS, TXT, CNAME records |
| 5  | IP Resolver | Python | Resolve domain ke IP (IPv4 & IPv6) |
| 6  | Protocol Checker | Python | Cek dukungan HTTP / HTTPS |
| 7  | Website Status | Python | Cek HTTP status code & response time |
| 8  | Header Checker | Python | Tampilkan HTTP response headers |
| 9  | Subdomain Finder | Python | Brute-force subdomain umum |
| 10 | Network Info | Python | Info IP lokal, publik, & interface |
| 11 | IP Geolocation | Ruby | Lokasi geografis IP via ip-api.com |
| 12 | Whois Lookup | Ruby | Data registrasi domain via protokol WHOIS |
| 13 | TCP Port Test | Ruby | Test koneksi TCP + ukur latensi |
| 14 | Reverse DNS | Ruby | Resolve hostname dari IP (PTR record) |
| 15 | Website IP Finder | Ruby | Temukan semua IP dari domain |
| 16 | SSL Checker | Ruby | Periksa detail sertifikat SSL/TLS |
| 17 | Domain Info | Ruby | Rangkuman lengkap info domain |
| 18 | Server Banner | Ruby | Grab banner dari berbagai port |
| 19 | Latency Checker | Ruby | Ukur latensi TCP + statistik |
| 20 | Packet Sender | Ruby | Kirim HTTP/TCP/UDP ke server |

---

## 🏗️ Struktur Project

```
network_toolkit/
│
├── main.py               ← Entry point (menu CLI utama - Python)
├── requirements.txt      ← Daftar dependency
├── run_tool.bat          ← Launcher untuk Windows
├── run_tool.sh           ← Launcher untuk Linux/macOS
├── README.md             ← Dokumentasi ini
│
├── python_modules/       ← Modul-modul Python (fitur 1-10)
│   ├── __init__.py
│   ├── port_scanner.py
│   ├── ping_checker.py
│   ├── traceroute.py
│   ├── dns_lookup.py
│   ├── ip_resolver.py
│   ├── protocol_checker.py
│   ├── website_status.py
│   ├── header_checker.py
│   ├── subdomain_finder.py
│   └── network_info.py
│
└── ruby_modules/         ← Modul-modul Ruby (fitur 11-20)
    ├── ip_geolocation.rb
    ├── whois_lookup.rb
    ├── tcp_port_test.rb
    ├── dns_reverse_lookup.rb
    ├── website_ip_finder.rb
    ├── ssl_checker.rb
    ├── domain_info.rb
    ├── server_banner.rb
    ├── latency_checker.rb
    └── packet_sender.rb
```

---

## ⚙️ Instalasi

### 1. Install Python

Python digunakan sebagai program utama (main CLI).

**Windows:**
1. Download dari https://www.python.org/downloads/
2. Jalankan installer
3. **Centang** ✅ `Add Python to PATH`
4. Klik Install Now
5. Verifikasi: buka CMD → `python --version`

**Linux (Debian/Ubuntu):**
```bash
sudo apt update
sudo apt install python3 python3-pip
python3 --version
```

**macOS:**
```bash
# Menggunakan Homebrew
brew install python3
python3 --version
```

> **Minimum Python version:** 3.8+  
> **Dependency:** Semua modul menggunakan Python Standard Library (tidak perlu `pip install` apapun)

---

### 2. Install Ruby

Ruby digunakan untuk fitur nomor 11–20. Fitur Python (1–10) tetap berjalan tanpa Ruby.

**Windows:**
1. Download RubyInstaller dari https://rubyinstaller.org/downloads/
2. Download versi **Ruby+Devkit** (misal: `Ruby 3.2.x (x64)`)
3. Jalankan installer → centang semua opsi → klik Install
4. Di akhir instalasi, biarkan MSYS2 terinstall (diperlukan untuk gem native)
5. Verifikasi: buka CMD baru → `ruby --version`

**Linux (Debian/Ubuntu):**
```bash
sudo apt update
sudo apt install ruby ruby-dev
ruby --version
```

**macOS:**
```bash
brew install ruby
# Tambahkan ke PATH (ikuti instruksi dari brew)
ruby --version
```

> **Minimum Ruby version:** 2.7+  
> **Gems:** Semua modul hanya menggunakan Ruby Standard Library (socket, openssl, resolv, net/http, json) — tidak perlu `gem install` apapun.

---

## 🚀 Cara Menjalankan

### Windows
```bat
# Double-click file:
run_tool.bat

# Atau dari CMD:
cd network_toolkit
python main.py
```

### Linux / macOS
```bash
cd network_toolkit
chmod +x run_tool.sh
./run_tool.sh

# Atau langsung:
python3 main.py
```

---

## 📖 Cara Penggunaan

1. Jalankan program → muncul menu utama
2. Ketik nomor fitur (1-20) → tekan Enter
3. Ikuti prompt yang muncul (masukkan domain, IP, port, dll.)
4. Lihat hasil di terminal
5. Tekan Enter untuk kembali ke menu utama
6. Ketik `0` untuk keluar

**Contoh penggunaan:**
```
Pilih menu [0-20]: 1
  → Masukkan host: scanme.nmap.org
  → Pilih mode: 1 (common ports)

Pilih menu [0-20]: 16
  → Masukkan domain: github.com
  (menampilkan detail SSL certificate)
```

---

## 🔧 Cara Kerja Integrasi Python ↔ Ruby

Python memanggil Ruby scripts menggunakan `subprocess.run()`:

```python
# Di main.py
import subprocess

process = subprocess.run(
    ["ruby", "ruby_modules/ip_geolocation.rb"],
    text=True
)
```

Ruby scripts berjalan sebagai **proses terpisah** — output mereka ditampilkan langsung ke terminal. Input dari pengguna dibaca oleh Ruby menggunakan `gets`.

Alur data:
```
User → main.py (Python) → subprocess → script.rb (Ruby) → Output di Terminal
                              ↑
                        Input/Output dialirkan
                        langsung ke terminal user
```

---

## ⚠️ Disclaimer

> Tool ini dibuat **semata-mata untuk tujuan edukasi** dan memahami cara kerja protokol jaringan.
> 
> **DILARANG** menggunakan tool ini untuk:
> - Melakukan scanning atau probing terhadap sistem yang bukan milik Anda
> - Mencari kerentanan tanpa izin (unauthorized penetration testing)
> - Segala aktivitas yang melanggar hukum
>
> Pengguna bertanggung jawab penuh atas penggunaan tool ini.

---

## 🐛 Troubleshooting

| Masalah | Solusi |
|---------|--------|
| `ruby: command not found` | Install Ruby, pastikan ada di PATH |
| `python: command not found` | Gunakan `python3` di Linux/Mac |
| Port Scanner lambat | Normal – timeout per port 1 detik |
| Traceroute tidak jalan | Install: `sudo apt install traceroute` |
| SSL error di Ruby | Pastikan `ruby-dev` terinstall di Linux |
| Geolocation gagal | Cek koneksi internet; ip-api.com harus bisa diakses |

---

## 📚 Teknologi yang Digunakan

**Python Standard Library:**
- `socket` — koneksi jaringan, DNS resolve
- `subprocess` — menjalankan Ruby scripts
- `ssl` — cek SSL/TLS
- `urllib` — HTTP requests
- `concurrent.futures` — parallel port scanning
- `threading` — multi-threading

**Ruby Standard Library:**
- `socket` / `TCPSocket` — koneksi TCP/UDP
- `openssl` — SSL certificate checking
- `resolv` — DNS queries
- `net/http` — HTTP requests
- `json` — parsing API responses
- `timeout` — timeout handling

---

*Network Toolkit v1.0 — Python + Ruby Edition*
