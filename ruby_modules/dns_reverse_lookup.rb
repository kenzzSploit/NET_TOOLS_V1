#!/usr/bin/env ruby
# encoding: utf-8
#
# DNS Reverse Lookup - Ruby Module
# Meresolve IP address menjadi hostname (PTR record).
# Juga mendukung bulk lookup untuk multiple IP sekaligus.
#

require 'resolv'
require 'socket'

module Color
  RESET  = "\e[0m"
  RED    = "\e[91m"
  GREEN  = "\e[92m"
  YELLOW = "\e[93m"
  CYAN   = "\e[96m"
  BOLD   = "\e[1m"
end

def reverse_lookup(ip)
  # Method 1: Gunakan Resolv (Ruby built-in DNS resolver)
  begin
    hostname = Resolv.getname(ip)
    return { ip: ip, hostname: hostname, method: "Resolv PTR", success: true }
  rescue Resolv::ResolvError
    # Method 2: Fallback ke Socket.gethostbyaddr
    begin
      hostname = Socket.gethostbyaddr(ip.split(".").map(&:to_i).pack("C4")).first
      return { ip: ip, hostname: hostname, method: "Socket", success: true }
    rescue SocketError => e
      return { ip: ip, hostname: nil, error: "No PTR record found", success: false }
    end
  rescue => e
    return { ip: ip, hostname: nil, error: e.message, success: false }
  end
end

def validate_ip(ip)
  # Validasi format IPv4 sederhana
  parts = ip.split(".")
  return false unless parts.length == 4
  parts.all? { |p| p.match?(/^\d+$/) && p.to_i.between?(0, 255) }
end

# ── Main Program ──────────────────────────────────────────
puts "  #{Color::YELLOW}Pilih mode:#{Color::RESET}"
puts "  [1] Single IP lookup"
puts "  [2] Bulk lookup (multiple IP)"
print "  → "
$stdout.flush
mode = gets.to_s.strip

ips = []

if mode == "1"
  print "\n  Masukkan IP address:\n  → "
  $stdout.flush
  ip = gets.to_s.strip
  ips = [ip] unless ip.empty?

elsif mode == "2"
  puts "\n  Masukkan IP addresses (satu per baris, kosongkan untuk selesai):"
  loop do
    print "  → "
    $stdout.flush
    ip = gets.to_s.strip
    break if ip.empty?
    ips << ip
  end

else
  puts "  #{Color::RED}[!] Pilihan tidak valid.#{Color::RESET}"
  exit 1
end

if ips.empty?
  puts "  #{Color::RED}[!] Tidak ada IP yang dimasukkan.#{Color::RESET}"
  exit 1
end

puts "\n  Total IP : #{ips.length}"
puts "  #{'─' * 55}"
puts "  #{'IP ADDRESS':<20} #{'HOSTNAME'}"
puts "  #{'─' * 55}"

found   = 0
notfound = 0

ips.each do |ip|
  ip = ip.strip

  # Validasi format IP
  unless validate_ip(ip)
    puts "  #{Color::RED}#{ip.ljust(20)}#{Color::RESET} #{Color::RED}[!] Format IP tidak valid#{Color::RESET}"
    next
  end

  result = reverse_lookup(ip)

  if result[:success]
    puts "  #{Color::CYAN}#{ip.ljust(20)}#{Color::RESET} #{Color::GREEN}#{result[:hostname]}#{Color::RESET}"
    puts "    #{Color::DIM}(via #{result[:method]})#{Color::RESET}" if ips.length == 1
    found += 1
  else
    puts "  #{Color::CYAN}#{ip.ljust(20)}#{Color::RESET} #{Color::RED}(#{result[:error]})#{Color::RESET}"
    notfound += 1
  end
end

puts "\n  #{'─' * 55}"
puts "  #{Color::GREEN}Ditemukan: #{found}#{Color::RESET}   #{Color::RED}Tidak ada PTR: #{notfound}#{Color::RESET}"

# Penjelasan singkat
if notfound > 0
  puts "\n  #{Color::YELLOW}Info:#{Color::RESET} Tidak semua IP memiliki PTR record."
  puts "  PTR record harus dikonfigurasi oleh pemilik blok IP (ISP/hoster)."
end
