#!/usr/bin/env ruby
# encoding: utf-8
#
# SSL Certificate Checker - Ruby Module
# Memeriksa detail sertifikat SSL/TLS dari sebuah domain.
# Menampilkan: issuer, subject, tanggal valid, cipher, dan protokol.
#

require 'openssl'
require 'socket'
require 'date'

module Color
  RESET  = "\e[0m"
  RED    = "\e[91m"
  GREEN  = "\e[92m"
  YELLOW = "\e[93m"
  CYAN   = "\e[96m"
  BOLD   = "\e[1m"
  DIM    = "\e[2m"
end

def check_ssl(host, port = 443)
  result = {}

  begin
    # Buat TCP connection
    raw_sock = TCPSocket.new(host, port)

    # Bungkus dengan SSL context
    ssl_ctx           = OpenSSL::SSL::SSLContext.new
    ssl_ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE  # Cek saja, tidak reject

    ssl_sock = OpenSSL::SSL::SSLSocket.new(raw_sock, ssl_ctx)
    ssl_sock.hostname = host  # SNI (Server Name Indication)
    ssl_sock.connect

    cert = ssl_sock.peer_cert

    # Ambil info dari sertifikat
    result[:subject]     = cert.subject.to_a.each_with_object({}) { |(k, v, _), h| h[k] = v }
    result[:issuer]      = cert.issuer.to_a.each_with_object({}) { |(k, v, _), h| h[k] = v }
    result[:serial]      = cert.serial.to_s(16).upcase
    result[:not_before]  = cert.not_before
    result[:not_after]   = cert.not_after
    result[:version]     = ssl_sock.ssl_version
    result[:cipher]      = ssl_sock.cipher[0]
    result[:bits]        = ssl_sock.cipher[2]

    # Cek SAN (Subject Alternative Names)
    san_ext = cert.extensions.find { |e| e.oid == "subjectAltName" }
    result[:san] = san_ext ? san_ext.value.split(", ").map { |s| s.sub("DNS:", "") } : []

    # Hitung sisa hari sebelum expired
    days_left = ((cert.not_after - Time.now) / 86400).to_i
    result[:days_left] = days_left
    result[:expired]   = days_left < 0

    ssl_sock.close
    raw_sock.close

    result[:error] = nil
  rescue OpenSSL::SSL::SSLError => e
    result[:error] = "SSL Error: #{e.message}"
  rescue Errno::ECONNREFUSED
    result[:error] = "Koneksi ditolak (port #{port} tertutup)"
  rescue SocketError => e
    result[:error] = "Socket Error: #{e.message}"
  rescue => e
    result[:error] = e.message
  end

  result
end

# ── Main Program ──────────────────────────────────────────
print "  Masukkan domain (misal: google.com):\n  → "
$stdout.flush
host = gets.to_s.strip.downcase.sub(/^https?:\/\//, "").split("/").first

if host.to_s.empty?
  puts "  #{Color::RED}[!] Domain tidak boleh kosong.#{Color::RESET}"
  exit 1
end

port = 443

puts "\n  Target : #{host}:#{port}"
puts "  #{'─' * 55}"
puts "  Memeriksa sertifikat SSL..."

result = check_ssl(host, port)

if result[:error]
  puts "\n  #{Color::RED}[ERROR] #{result[:error]}#{Color::RESET}"
  exit 1
end

# ── Tampilkan info sertifikat ─────────────────────────────
puts "\n  #{Color::YELLOW}▸ Informasi Subjek:#{Color::RESET}"
puts "    Common Name (CN) : #{result[:subject]['CN'] || '(tidak ada)'}"
puts "    Organisasi (O)   : #{result[:subject]['O'] || '(tidak ada)'}"
puts "    Negara (C)       : #{result[:subject]['C'] || '(tidak ada)'}"

puts "\n  #{Color::YELLOW}▸ Penerbit (Issuer):#{Color::RESET}"
puts "    Issuer CN        : #{result[:issuer]['CN'] || '(tidak ada)'}"
puts "    Issuer Org (O)   : #{result[:issuer]['O'] || '(tidak ada)'}"

puts "\n  #{Color::YELLOW}▸ Masa Berlaku:#{Color::RESET}"
puts "    Valid Dari       : #{result[:not_before].strftime('%d %b %Y %H:%M:%S UTC')}"
puts "    Valid Hingga     : #{result[:not_after].strftime('%d %b %Y %H:%M:%S UTC')}"

days = result[:days_left]
if result[:expired]
  puts "    Status           : #{Color::RED}✗ KADALUARSA (#{days.abs} hari lalu)#{Color::RESET}"
elsif days < 30
  puts "    Status           : #{Color::YELLOW}⚠ Akan kadaluarsa dalam #{days} hari#{Color::RESET}"
else
  puts "    Status           : #{Color::GREEN}✓ Valid (#{days} hari lagi)#{Color::RESET}"
end

puts "\n  #{Color::YELLOW}▸ Protokol & Enkripsi:#{Color::RESET}"
puts "    SSL/TLS Version  : #{result[:version]}"
puts "    Cipher Suite     : #{result[:cipher]}"
puts "    Key Length       : #{result[:bits]} bit"
puts "    Serial Number    : #{result[:serial]}"

# SAN (Subject Alternative Names)
if result[:san] && !result[:san].empty?
  puts "\n  #{Color::YELLOW}▸ Subject Alternative Names (SAN):#{Color::RESET}"
  result[:san].first(10).each do |san|
    puts "    #{Color::CYAN}#{san}#{Color::RESET}"
  end
  if result[:san].length > 10
    puts "    #{Color::DIM}... dan #{result[:san].length - 10} SAN lainnya#{Color::RESET}"
  end
end

# Penilaian keamanan
puts "\n  #{Color::YELLOW}▸ Penilaian Keamanan:#{Color::RESET}"
bits = result[:bits].to_i
if bits >= 256
  puts "    Key Strength     : #{Color::GREEN}✓ Sangat Kuat (#{bits} bit)#{Color::RESET}"
elsif bits >= 128
  puts "    Key Strength     : #{Color::GREEN}✓ Kuat (#{bits} bit)#{Color::RESET}"
else
  puts "    Key Strength     : #{Color::RED}✗ Lemah (#{bits} bit)#{Color::RESET}"
end

tls_ver = result[:version].to_s
if tls_ver.include?("TLSv1.3")
  puts "    TLS Version      : #{Color::GREEN}✓ TLS 1.3 (terbaik)#{Color::RESET}"
elsif tls_ver.include?("TLSv1.2")
  puts "    TLS Version      : #{Color::GREEN}✓ TLS 1.2 (baik)#{Color::RESET}"
elsif tls_ver.include?("TLSv1.1") || tls_ver.include?("TLSv1.0")
  puts "    TLS Version      : #{Color::RED}✗ #{tls_ver} (sudah usang)#{Color::RESET}"
else
  puts "    TLS Version      : #{Color::YELLOW}? #{tls_ver}#{Color::RESET}"
end
