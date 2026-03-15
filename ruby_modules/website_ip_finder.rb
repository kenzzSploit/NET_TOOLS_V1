#!/usr/bin/env ruby
# encoding: utf-8
#
# Website IP Finder - Ruby Module
# Menemukan semua IP address yang terkait dengan sebuah domain.
# Mengecek A record, AAAA record, dan CDN detection.
#

require 'resolv'
require 'socket'
require 'net/http'
require 'uri'

module Color
  RESET  = "\e[0m"
  RED    = "\e[91m"
  GREEN  = "\e[92m"
  YELLOW = "\e[93m"
  CYAN   = "\e[96m"
  BOLD   = "\e[1m"
  DIM    = "\e[2m"
end

# CDN/Provider detection berdasarkan ASN atau hostname patterns
CDN_PATTERNS = {
  "cloudflare" => "Cloudflare CDN",
  "fastly"     => "Fastly CDN",
  "akamai"     => "Akamai CDN",
  "amazonaws"  => "Amazon AWS",
  "azure"      => "Microsoft Azure",
  "google"     => "Google Cloud/GCP",
  "incapsula"  => "Imperva/Incapsula",
  "sucuri"     => "Sucuri WAF",
}

def detect_cdn(hostname)
  hostname = hostname.to_s.downcase
  CDN_PATTERNS.each do |pattern, name|
    return name if hostname.include?(pattern)
  end
  nil
end

def get_all_ipv4(domain)
  ips = []
  begin
    resolver = Resolv::DNS.new
    resolver.each_address(domain) do |addr|
      ips << addr.to_s if addr.is_a?(Resolv::IPv4)
    end
  rescue => e
    # Fallback ke getaddresses
    begin
      Resolv.getaddresses(domain).each { |ip| ips << ip }
    rescue => e2
      # ignore
    end
  end
  ips.uniq
end

def get_all_ipv6(domain)
  ips = []
  begin
    resolver = Resolv::DNS.new
    resolver.each_address(domain) do |addr|
      ips << addr.to_s if addr.is_a?(Resolv::IPv6)
    end
  rescue => e
    # ignore
  end
  ips.uniq
end

def get_cname(domain)
  begin
    resolver = Resolv::DNS.new
    cname = resolver.getresource(domain, Resolv::DNS::Resource::IN::CNAME)
    return cname.name.to_s
  rescue Resolv::ResolvError
    nil
  rescue => e
    nil
  end
end

def reverse_lookup_ip(ip)
  begin
    Resolv.getname(ip)
  rescue
    nil
  end
end

# ── Main Program ──────────────────────────────────────────
print "  Masukkan domain (misal: github.com):\n  → "
$stdout.flush
domain = gets.to_s.strip.downcase
domain = domain.sub(/^https?:\/\//, "").split("/").first

if domain.to_s.empty?
  puts "  #{Color::RED}[!] Domain tidak boleh kosong.#{Color::RESET}"
  exit 1
end

puts "\n  Domain  : #{domain}"
puts "  #{'─' * 55}"

# ── CNAME Check ───────────────────────────────────────────
cname = get_cname(domain)
if cname
  puts "\n  #{Color::YELLOW}▸ CNAME Record:#{Color::RESET}"
  puts "    #{domain} → #{cname}"

  # Detect CDN dari CNAME
  cdn = detect_cdn(cname)
  puts "    #{Color::CYAN}Terdeteksi: #{cdn}#{Color::RESET}" if cdn
end

# ── IPv4 Addresses ────────────────────────────────────────
ipv4_list = get_all_ipv4(domain)
puts "\n  #{Color::YELLOW}▸ IPv4 Addresses (A Record):#{Color::RESET}"
if ipv4_list.empty?
  puts "    #{Color::RED}(tidak ditemukan)#{Color::RESET}"
else
  ipv4_list.each do |ip|
    hostname = reverse_lookup_ip(ip)
    cdn      = hostname ? detect_cdn(hostname) : nil

    print "    #{Color::GREEN}#{ip.ljust(18)}#{Color::RESET}"
    print " ← #{hostname}" if hostname
    print " #{Color::CYAN}[#{cdn}]#{Color::RESET}" if cdn
    puts
  end
end

# ── IPv6 Addresses ────────────────────────────────────────
ipv6_list = get_all_ipv6(domain)
puts "\n  #{Color::YELLOW}▸ IPv6 Addresses (AAAA Record):#{Color::RESET}"
if ipv6_list.empty?
  puts "    #{Color::DIM}(tidak ditemukan)#{Color::RESET}"
else
  ipv6_list.each do |ip|
    puts "    #{Color::CYAN}#{ip}#{Color::RESET}"
  end
end

# ── Ringkasan ─────────────────────────────────────────────
total = ipv4_list.length + ipv6_list.length
puts "\n  #{'─' * 55}"
puts "  Total IP ditemukan: #{Color::GREEN}#{total}#{Color::RESET} (#{ipv4_list.length} IPv4, #{ipv6_list.length} IPv6)"

if total > 1
  puts "\n  #{Color::YELLOW}Info:#{Color::RESET} Domain ini memiliki multiple IP."
  puts "  Kemungkinan menggunakan load balancing atau Anycast routing."
end
