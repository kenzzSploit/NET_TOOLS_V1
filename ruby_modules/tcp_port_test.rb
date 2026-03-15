#!/usr/bin/env ruby
# encoding: utf-8
#
# TCP Port Test - Ruby Module
# Menguji koneksi TCP ke host:port tertentu.
# Mengukur berapa lama koneksi berhasil atau gagal.
#

require 'socket'
require 'timeout'

module Color
  RESET  = "\e[0m"
  RED    = "\e[91m"
  GREEN  = "\e[92m"
  YELLOW = "\e[93m"
  CYAN   = "\e[96m"
  BOLD   = "\e[1m"
end

# Nama layanan umum berdasarkan port
SERVICE_NAMES = {
  21 => "FTP", 22 => "SSH", 23 => "Telnet", 25 => "SMTP",
  53 => "DNS", 80 => "HTTP", 110 => "POP3", 143 => "IMAP",
  443 => "HTTPS", 445 => "SMB", 587 => "SMTP-TLS",
  3306 => "MySQL", 3389 => "RDP", 5432 => "PostgreSQL",
  5900 => "VNC", 6379 => "Redis", 8080 => "HTTP-Alt",
  8443 => "HTTPS-Alt", 27017 => "MongoDB"
}

def test_tcp_connection(host, port, timeout_sec = 5)
  # Coba buat koneksi TCP dan ukur waktu
  result = {
    host: host, port: port, open: false,
    latency_ms: nil, error: nil, banner: nil
  }

  start_time = Time.now
  begin
    Timeout.timeout(timeout_sec) do
      sock = TCPSocket.new(host, port)

      elapsed = ((Time.now - start_time) * 1000).round(1)
      result[:open]       = true
      result[:latency_ms] = elapsed

      # Coba baca banner (beberapa server mengirim welcome banner)
      sock.read_nonblock(1024) rescue nil
      begin
        sock.read_nonblock(512)
      rescue IO::WaitReadable
        # Tidak ada banner tersedia
      rescue => e
        # ignore
      end

      sock.close
    end
  rescue Timeout::Error
    result[:error] = "Timeout (#{timeout_sec}s)"
  rescue Errno::ECONNREFUSED
    result[:error] = "Connection Refused (port tertutup)"
  rescue Errno::EHOSTUNREACH
    result[:error] = "Host tidak dapat dijangkau"
  rescue SocketError => e
    result[:error] = "Socket Error: #{e.message}"
  rescue => e
    result[:error] = e.message
  end

  result
end

# ── Main Program ──────────────────────────────────────────
print "  Masukkan host (domain/IP):\n  → "
$stdout.flush
host = gets.to_s.strip

if host.empty?
  puts "  #{Color::RED}[!] Host tidak boleh kosong.#{Color::RESET}"
  exit 1
end

print "\n  Masukkan port (misal: 80 atau 80,443,22 atau 80-90):\n  → "
$stdout.flush
port_input = gets.to_s.strip

# Parse port input: bisa single, comma-separated, atau range
ports = []
port_input.split(",").each do |part|
  if part.include?("-")
    range = part.split("-").map(&:to_i)
    ports += (range[0]..range[1]).to_a if range.length == 2
  elsif part.strip.match?(/^\d+$/)
    ports << part.strip.to_i
  end
end

if ports.empty?
  puts "  #{Color::RED}[!] Format port tidak valid.#{Color::RESET}"
  exit 1
end

puts "\n  Host    : #{host}"
puts "  Ports   : #{ports.join(', ')}"
puts "  #{'─' * 55}"
puts "  #{'PORT':<10} #{'STATUS':<15} #{'LAYANAN':<15} #{'LATENCY'}"
puts "  #{'─' * 55}"

open_count   = 0
closed_count = 0

ports.each do |port|
  service = SERVICE_NAMES[port] || "Unknown"
  result  = test_tcp_connection(host, port, 3)

  if result[:open]
    status_str = "#{Color::GREEN}OPEN#{Color::RESET}"
    latency    = "#{result[:latency_ms]} ms"
    open_count += 1
  else
    status_str = "#{Color::RED}CLOSED#{Color::RESET}"
    latency    = result[:error] || "N/A"
    closed_count += 1
  end

  # Format output
  puts "  #{port.to_s.ljust(10)} #{status_str.ljust(22)} #{service.ljust(15)} #{latency}"
end

puts "\n  #{'─' * 55}"
puts "  #{Color::GREEN}Open: #{open_count}#{Color::RESET}   #{Color::RED}Closed/Filtered: #{closed_count}#{Color::RESET}"

# Ringkasan
if open_count > 0
  puts "\n  #{Color::GREEN}✓ Host dapat dijangkau via TCP.#{Color::RESET}"
else
  puts "\n  #{Color::RED}✗ Tidak ada port yang terbuka. Host mungkin memblokir koneksi.#{Color::RESET}"
end
