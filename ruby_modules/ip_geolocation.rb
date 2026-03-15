#!/usr/bin/env ruby
# encoding: utf-8
#
# IP Geolocation Lookup - Ruby Module
# Mencari lokasi geografis dari sebuah IP address menggunakan API publik.
# API yang digunakan: ip-api.com (gratis, tanpa API key)
#

require 'net/http'
require 'json'
require 'uri'
require 'socket'

# ── Warna ANSI ────────────────────────────────────────────
module Color
  RESET   = "\e[0m"
  RED     = "\e[91m"
  GREEN   = "\e[92m"
  YELLOW  = "\e[93m"
  CYAN    = "\e[96m"
  BOLD    = "\e[1m"
  DIM     = "\e[2m"
end

def print_separator
  puts "  #{'─' * 55}"
end

def get_geolocation(ip_or_domain)
  # Gunakan API ip-api.com untuk mendapatkan data geolokasi
  url = URI("http://ip-api.com/json/#{ip_or_domain}?fields=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,query")

  begin
    response = Net::HTTP.get_response(url)
    data     = JSON.parse(response.body)
    data
  rescue => e
    { "status" => "fail", "message" => e.message }
  end
end

# ── Main Program ──────────────────────────────────────────
print "  Masukkan IP address atau domain:\n  → "
$stdout.flush
target = gets.to_s.strip

if target.empty?
  puts "  #{Color::RED}[!] Input tidak boleh kosong.#{Color::RESET}"
  exit 1
end

puts "\n  Target  : #{target}"
print_separator

puts "\n  Mengambil data geolokasi..."
data = get_geolocation(target)

if data["status"] == "success"
  puts "\n  #{Color::YELLOW}▸ Informasi IP:#{Color::RESET}"
  puts "    IP Address    : #{Color::GREEN}#{data['query']}#{Color::RESET}"
  puts "    ISP           : #{data['isp']}"
  puts "    Organisasi    : #{data['org']}"
  puts "    AS Number     : #{data['as']}"

  puts "\n  #{Color::YELLOW}▸ Lokasi Geografis:#{Color::RESET}"
  puts "    Negara        : #{data['country']} (#{data['countryCode']})"
  puts "    Provinsi      : #{data['regionName']} (#{data['region']})"
  puts "    Kota          : #{data['city']}"
  puts "    Kode Pos      : #{data['zip']}"
  puts "    Koordinat     : #{data['lat']}, #{data['lon']}"
  puts "    Timezone      : #{data['timezone']}"

  # Buat link Google Maps
  gmaps = "https://maps.google.com/?q=#{data['lat']},#{data['lon']}"
  puts "\n  #{Color::YELLOW}▸ Google Maps:#{Color::RESET}"
  puts "    #{Color::CYAN}#{gmaps}#{Color::RESET}"

elsif data["status"] == "fail"
  puts "\n  #{Color::RED}[ERROR] #{data['message']}#{Color::RESET}"
  puts "  Pastikan IP address valid dan koneksi internet tersedia."
else
  puts "\n  #{Color::RED}[ERROR] Response tidak dikenali.#{Color::RESET}"
end
