#!/usr/bin/env ruby
# encoding: utf-8
#
# Whois Lookup - Ruby Module
# Mengambil data registrasi domain atau IP menggunakan protokol WHOIS (port 43).
# Menghubungi WHOIS server secara langsung menggunakan TCP socket.
#

require 'socket'
require 'timeout'

module Color
  RESET   = "\e[0m"
  RED     = "\e[91m"
  GREEN   = "\e[92m"
  YELLOW  = "\e[93m"
  CYAN    = "\e[96m"
  BOLD    = "\e[1m"
  DIM     = "\e[2m"
end

# WHOIS server berdasarkan TLD domain
WHOIS_SERVERS = {
  "com"  => "whois.verisign-grs.com",
  "net"  => "whois.verisign-grs.com",
  "org"  => "whois.pir.org",
  "io"   => "whois.nic.io",
  "id"   => "whois.id",
  "uk"   => "whois.nic.uk",
  "de"   => "whois.denic.de",
  "nl"   => "whois.sidn.nl",
  "info" => "whois.afilias.net",
  "biz"  => "whois.neulevel.biz",
  "edu"  => "whois.educause.edu",
  "gov"  => "whois.dotgov.gov",
}
DEFAULT_WHOIS = "whois.iana.org"

def get_whois_server(domain)
  # Ambil TLD dari domain
  tld = domain.split(".").last.to_s.downcase
  WHOIS_SERVERS[tld] || DEFAULT_WHOIS
end

def query_whois(query, server, port = 43)
  # Kirim query ke WHOIS server via TCP socket
  result = ""
  begin
    Timeout.timeout(10) do
      sock = TCPSocket.new(server, port)
      sock.puts("#{query}\r\n")
      result = sock.read
      sock.close
    end
  rescue Timeout::Error
    result = "[TIMEOUT] WHOIS server tidak merespons dalam 10 detik."
  rescue Errno::ECONNREFUSED
    result = "[ERROR] Koneksi ditolak oleh WHOIS server: #{server}"
  rescue SocketError => e
    result = "[ERROR] Socket error: #{e.message}"
  rescue => e
    result = "[ERROR] #{e.message}"
  end
  result
end

def highlight_field(line)
  # Highlight field penting dalam output WHOIS
  important = [
    "Registrar", "Registrant", "Name Server", "DNSSEC",
    "Creation Date", "Updated Date", "Registry Expiry",
    "Domain Status", "Registrar URL", "Registrar IANA ID",
    "Admin", "Tech", "Billing", "Country", "State",
    "Organisation", "NetRange", "CIDR", "OrgName"
  ]
  important.each do |field|
    if line.downcase.start_with?(field.downcase) || line.include?("#{field}:")
      return "#{Color::YELLOW}#{line}#{Color::RESET}"
    end
  end
  line
end

# ── Main Program ──────────────────────────────────────────
print "  Masukkan domain atau IP untuk WHOIS lookup:\n  → "
$stdout.flush
target = gets.to_s.strip

if target.empty?
  puts "  #{Color::RED}[!] Input tidak boleh kosong.#{Color::RESET}"
  exit 1
end

puts "\n  Target       : #{target}"

whois_server = get_whois_server(target)
puts "  WHOIS Server : #{whois_server}"
puts "  #{'─' * 55}"
puts "\n  Mengambil data WHOIS..."

result = query_whois(target, whois_server)

if result.start_with?("[ERROR]") || result.start_with?("[TIMEOUT]")
  puts "\n  #{Color::RED}#{result}#{Color::RESET}"
else
  puts "\n  #{Color::YELLOW}▸ Hasil WHOIS:#{Color::RESET}"

  # Filter dan tampilkan baris yang relevan
  lines_shown = 0
  result.each_line do |line|
    line = line.chomp
    next if line.strip.empty? && lines_shown == 0  # skip empty lines di awal
    next if line.start_with?("%") || line.start_with?("#")  # skip komentar

    puts "    #{highlight_field(line)}"
    lines_shown += 1
    break if lines_shown > 80  # Batasi output agar tidak terlalu panjang
  end

  puts "\n  #{Color::DIM}(Tampilkan maksimal 80 baris. Gunakan 'whois #{target}' untuk output lengkap.)#{Color::RESET}"
end
