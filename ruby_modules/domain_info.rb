#!/usr/bin/env ruby
# encoding: utf-8
#
# Domain Info Checker - Ruby Module
# Mengumpulkan informasi lengkap tentang sebuah domain:
# DNS records (A, MX, NS, TXT), SSL info, dan WHOIS ringkasan.
#

require 'resolv'
require 'socket'
require 'timeout'
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

def section(title)
  puts "\n  #{Color::YELLOW}▸ #{title}:#{Color::RESET}"
end

def safe_resolve(domain, type)
  records = []
  begin
    resolver = Resolv::DNS.new
    case type
    when :A
      resolver.each_resource(domain, Resolv::DNS::Resource::IN::A) { |r| records << r.address.to_s }
    when :AAAA
      resolver.each_resource(domain, Resolv::DNS::Resource::IN::AAAA) { |r| records << r.address.to_s }
    when :MX
      resolver.each_resource(domain, Resolv::DNS::Resource::IN::MX) { |r| records << "#{r.preference} #{r.exchange}" }
    when :NS
      resolver.each_resource(domain, Resolv::DNS::Resource::IN::NS) { |r| records << r.name.to_s }
    when :TXT
      resolver.each_resource(domain, Resolv::DNS::Resource::IN::TXT) { |r| records << r.strings.join(" ") }
    when :CNAME
      resolver.each_resource(domain, Resolv::DNS::Resource::IN::CNAME) { |r| records << r.name.to_s }
    end
  rescue Resolv::ResolvError
    # Tidak ada record untuk tipe ini
  rescue => e
    records << "[Error: #{e.message}]"
  end
  records
end

def check_https(domain)
  begin
    Timeout.timeout(5) do
      raw_sock = TCPSocket.new(domain, 443)
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
      ssl  = OpenSSL::SSL::SSLSocket.new(raw_sock, ctx)
      ssl.hostname = domain
      ssl.connect
      cert     = ssl.peer_cert
      version  = ssl.ssl_version
      days_rem = ((cert.not_after - Time.now) / 86400).to_i
      ssl.close; raw_sock.close
      { ok: true, version: version, days: days_rem,
        cn: cert.subject.to_a.find { |k,_,_| k == "CN" }&.at(1) }
    end
  rescue => e
    { ok: false, error: e.message }
  end
end

# ── Main Program ──────────────────────────────────────────
print "  Masukkan domain:\n  → "
$stdout.flush
domain = gets.to_s.strip.downcase.sub(/^https?:\/\//, "").split("/").first

if domain.to_s.empty?
  puts "  #{Color::RED}[!] Domain tidak boleh kosong.#{Color::RESET}"
  exit 1
end

puts "\n  #{Color::BOLD}Domain  : #{domain}#{Color::RESET}"
puts "  #{'═' * 55}"

# ── A Record (IPv4) ───────────────────────────────────────
section "A Records (IPv4)"
a_records = safe_resolve(domain, :A)
a_records.empty? ? puts("    (tidak ada)") : a_records.each { |r| puts "    #{Color::GREEN}#{r}#{Color::RESET}" }

# ── AAAA Record (IPv6) ────────────────────────────────────
section "AAAA Records (IPv6)"
aaaa_records = safe_resolve(domain, :AAAA)
aaaa_records.empty? ? puts("    (tidak ada)") : aaaa_records.each { |r| puts "    #{Color::CYAN}#{r}#{Color::RESET}" }

# ── CNAME Record ─────────────────────────────────────────
section "CNAME Record"
cname_records = safe_resolve(domain, :CNAME)
cname_records.empty? ? puts("    (tidak ada)") : cname_records.each { |r| puts "    #{r}" }

# ── MX Record ────────────────────────────────────────────
section "MX Records (Mail Server)"
mx_records = safe_resolve(domain, :MX)
if mx_records.empty?
  puts "    (tidak ada – domain ini mungkin tidak menerima email)"
else
  mx_records.sort_by { |r| r.split.first.to_i }.each { |r| puts "    #{r}" }
end

# ── NS Record ────────────────────────────────────────────
section "NS Records (Name Servers)"
ns_records = safe_resolve(domain, :NS)
ns_records.empty? ? puts("    (tidak ada)") : ns_records.each { |r| puts "    #{r}" }

# ── TXT Record ───────────────────────────────────────────
section "TXT Records"
txt_records = safe_resolve(domain, :TXT)
if txt_records.empty?
  puts "    (tidak ada)"
else
  txt_records.each do |r|
    # Highlight record penting
    if r.include?("v=spf1")
      puts "    #{Color::CYAN}[SPF]#{Color::RESET} #{r}"
    elsif r.include?("v=DMARC1")
      puts "    #{Color::CYAN}[DMARC]#{Color::RESET} #{r}"
    elsif r.include?("v=DKIM1")
      puts "    #{Color::CYAN}[DKIM]#{Color::RESET} #{r[0..80]}..."
    elsif r.include?("google-site-verification")
      puts "    #{Color::DIM}[Google Verify]#{Color::RESET} #{r}"
    else
      puts "    #{r}"
    end
  end
end

# ── HTTPS / SSL Check ─────────────────────────────────────
section "HTTPS / SSL Status"
ssl_info = check_https(domain)
if ssl_info[:ok]
  puts "    Status   : #{Color::GREEN}✓ HTTPS tersedia#{Color::RESET}"
  puts "    Protokol : #{ssl_info[:version]}"
  puts "    Cert CN  : #{ssl_info[:cn]}"
  days = ssl_info[:days]
  if days < 0
    puts "    SSL Exp  : #{Color::RED}✗ KADALUARSA#{Color::RESET}"
  elsif days < 30
    puts "    SSL Exp  : #{Color::YELLOW}⚠ #{days} hari lagi#{Color::RESET}"
  else
    puts "    SSL Exp  : #{Color::GREEN}✓ #{days} hari lagi#{Color::RESET}"
  end
else
  puts "    Status   : #{Color::RED}✗ HTTPS tidak tersedia (#{ssl_info[:error]})#{Color::RESET}"
end

# ── Ringkasan ─────────────────────────────────────────────
puts "\n  #{'─' * 55}"
puts "  #{Color::BOLD}Ringkasan:#{Color::RESET}"
puts "  A Records    : #{a_records.length}"
puts "  MX Records   : #{mx_records.length}"
puts "  NS Records   : #{ns_records.length}"
puts "  TXT Records  : #{txt_records.length}"
puts "  HTTPS        : #{ssl_info[:ok] ? "#{Color::GREEN}✓#{Color::RESET}" : "#{Color::RED}✗#{Color::RESET}"}"
