#!/usr/bin/env ruby
# encoding: utf-8
#
# Server Banner Grabber - Ruby Module
# Mengambil banner/informasi yang dikirim server saat pertama kali terhubung.
# Berguna untuk mengidentifikasi software & versi yang digunakan server.
# PENTING: Hanya untuk tujuan edukasi & testing server milik sendiri.
#

require 'socket'
require 'timeout'
require 'net/http'
require 'uri'
require 'openssl'

module Color
  RESET  = "\e[0m"
  RED    = "\e[91m"
  GREEN  = "\e[92m"
  YELLOW = "\e[93m"
  CYAN   = "\e[96m"
  BOLD   = "\e[1m"
  DIM    = "\e[2m"
end

# Probe string per protokol untuk memancing server mengirim banner
PROBES = {
  21   => { name: "FTP",    probe: nil },                        # FTP langsung kirim banner
  22   => { name: "SSH",    probe: nil },                        # SSH langsung kirim banner
  25   => { name: "SMTP",   probe: nil },                        # SMTP langsung kirim banner
  80   => { name: "HTTP",   probe: "HEAD / HTTP/1.0\r\nHost: TARGET\r\n\r\n" },
  443  => { name: "HTTPS",  probe: "HEAD / HTTP/1.0\r\nHost: TARGET\r\n\r\n", ssl: true },
  110  => { name: "POP3",   probe: nil },
  143  => { name: "IMAP",   probe: nil },
  3306 => { name: "MySQL",  probe: nil },
  5432 => { name: "PostgreSQL", probe: nil },
  6379 => { name: "Redis",  probe: "PING\r\n" },
  8080 => { name: "HTTP-Alt", probe: "HEAD / HTTP/1.0\r\nHost: TARGET\r\n\r\n" },
}

def grab_banner(host, port, timeout_sec = 5)
  probe_info = PROBES[port] || { name: "Unknown", probe: nil }
  result     = { port: port, service: probe_info[:name], banner: nil, error: nil }

  begin
    Timeout.timeout(timeout_sec) do
      if probe_info[:ssl]
        # Koneksi SSL (untuk HTTPS)
        raw = TCPSocket.new(host, port)
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
        sock = OpenSSL::SSL::SSLSocket.new(raw, ctx)
        sock.hostname = host
        sock.connect
      else
        sock = TCPSocket.new(host, port)
      end

      # Kirim probe jika ada
      if probe_info[:probe]
        probe = probe_info[:probe].gsub("TARGET", host)
        sock.print(probe)
      end

      # Baca banner (max 2048 byte)
      banner = ""
      begin
        while (chunk = sock.read_nonblock(512))
          banner += chunk
          break if banner.length > 2048
        end
      rescue IO::WaitReadable
        IO.select([sock], nil, nil, 1)
        retry if banner.empty?
      rescue EOFError
        # Normal, server menutup koneksi setelah banner
      end

      sock.close
      result[:banner] = banner.strip unless banner.strip.empty?
    end
  rescue Timeout::Error
    result[:error] = "Timeout"
  rescue Errno::ECONNREFUSED
    result[:error] = "Port tertutup"
  rescue OpenSSL::SSL::SSLError => e
    result[:error] = "SSL Error: #{e.message.split("\n").first}"
  rescue SocketError => e
    result[:error] = "Socket Error: #{e.message}"
  rescue => e
    result[:error] = e.message
  end

  result
end

def grab_http_headers(host, port = 80, use_ssl = false)
  # Ambil HTTP headers menggunakan Net::HTTP
  headers = {}
  begin
    uri  = URI("#{use_ssl ? 'https' : 'http'}://#{host}:#{port}/")
    http = Net::HTTP.new(uri.host, uri.port)
    if use_ssl
      http.use_ssl     = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    http.open_timeout = 5
    http.read_timeout = 5
    resp    = http.head("/")
    headers = resp.each_header.to_h
  rescue => e
    # Ignore
  end
  headers
end

# ── Main Program ──────────────────────────────────────────
print "  Masukkan host (domain/IP):\n  → "
$stdout.flush
host = gets.to_s.strip

if host.empty?
  puts "  #{Color::RED}[!] Host tidak boleh kosong.#{Color::RESET}"
  exit 1
end

puts "\n  Pilih mode:"
puts "  [1] Grab banner dari port umum (otomatis)"
puts "  [2] Grab banner dari port spesifik"
print "  → "
$stdout.flush
mode = gets.to_s.strip

ports_to_scan = []

if mode == "1"
  ports_to_scan = PROBES.keys
elsif mode == "2"
  print "\n  Masukkan port (misal: 22 atau 80,443,22):\n  → "
  $stdout.flush
  port_str = gets.to_s.strip
  ports_to_scan = port_str.split(",").map { |p| p.strip.to_i }.select { |p| p > 0 }
else
  puts "  #{Color::RED}[!] Pilihan tidak valid.#{Color::RESET}"
  exit 1
end

puts "\n  Host   : #{host}"
puts "  Ports  : #{ports_to_scan.join(', ')}"
puts "  #{'─' * 60}"

banners_found = 0

ports_to_scan.each do |port|
  service = PROBES.dig(port, :name) || "Port #{port}"
  print "  Grabbing #{service} (port #{port})..."
  $stdout.flush

  result = grab_banner(host, port)

  if result[:banner]
    banners_found += 1
    puts "\r  #{Color::GREEN}✓ #{service} (port #{port})#{Color::RESET}" + " " * 10
    # Tampilkan banner, bersihkan karakter kontrol
    banner_clean = result[:banner].gsub(/[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]/, "")
    banner_clean.each_line do |line|
      puts "    #{Color::CYAN}#{line.chomp}#{Color::RESET}"
    end
  elsif result[:error] == "Port tertutup"
    puts "\r  #{Color::DIM}✗ #{service} (port #{port}) – tertutup#{Color::RESET}" + " " * 10
  else
    puts "\r  #{Color::YELLOW}? #{service} (port #{port}) – #{result[:error]}#{Color::RESET}" + " " * 10
  end
end

# ── HTTP Headers ──────────────────────────────────────────
if ports_to_scan.include?(80) || ports_to_scan.include?(443)
  puts "\n  #{Color::YELLOW}▸ HTTP Response Headers:#{Color::RESET}"

  [[80, false], [443, true]].each do |port, ssl|
    next unless ports_to_scan.include?(port)
    headers = grab_http_headers(host, port, ssl)
    next if headers.empty?

    puts "    #{Color::BOLD}[#{ssl ? 'HTTPS' : 'HTTP'} port #{port}]#{Color::RESET}"
    important = %w[Server X-Powered-By X-Generator Via X-Forwarded-For
                   X-AspNet-Version X-Runtime X-Frame-Options]
    important.each do |h|
      val = headers[h.downcase] || headers[h]
      puts "    #{h.ljust(22)} : #{Color::GREEN}#{val}#{Color::RESET}" if val
    end
  end
end

puts "\n  #{'─' * 60}"
puts "  Banner berhasil di-grab: #{Color::GREEN}#{banners_found}#{Color::RESET} dari #{ports_to_scan.length} port"
