#!/usr/bin/env ruby
# encoding: utf-8
#
# Latency Checker - Ruby Module
# Mengukur latensi (response time) koneksi TCP ke sebuah host.
# Melakukan multiple pengukuran dan menghitung statistik (min/max/avg/jitter).
#

require 'socket'
require 'timeout'
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

def measure_tcp_latency(host, port, timeout_sec = 3)
  # Ukur waktu handshake TCP (SYN → SYN-ACK)
  start = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
  begin
    Timeout.timeout(timeout_sec) do
      sock = TCPSocket.new(host, port)
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - start
      sock.close
      { success: true, latency_ms: elapsed.round(2) }
    end
  rescue Timeout::Error
    { success: false, error: "Timeout (>#{timeout_sec}s)" }
  rescue Errno::ECONNREFUSED
    { success: false, error: "Connection Refused" }
  rescue SocketError => e
    { success: false, error: "DNS/Socket Error: #{e.message}" }
  rescue => e
    { success: false, error: e.message }
  end
end

def measure_http_latency(url, timeout_sec = 5)
  # Ukur round-trip time untuk HTTP HEAD request
  uri  = URI(url)
  host = uri.host
  port = uri.port

  start = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
  begin
    Timeout.timeout(timeout_sec) do
      http             = Net::HTTP.new(host, port)
      http.use_ssl     = uri.scheme == "https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE rescue nil
      http.open_timeout = timeout_sec
      http.read_timeout = timeout_sec
      resp    = http.head("/")
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - start
      { success: true, latency_ms: elapsed.round(2), status: resp.code }
    end
  rescue => e
    { success: false, error: e.message }
  end
end

def calculate_stats(latencies)
  return nil if latencies.empty?
  {
    min:    latencies.min.round(2),
    max:    latencies.max.round(2),
    avg:    (latencies.sum / latencies.length).round(2),
    jitter: (latencies.max - latencies.min).round(2),
    count:  latencies.length
  }
end

def latency_bar(ms, max_ms = 500)
  # Buat visual bar untuk latensi
  bar_width  = 30
  proportion = [ms / max_ms.to_f, 1.0].min
  filled     = (proportion * bar_width).to_i
  bar        = "█" * filled + "░" * (bar_width - filled)

  color = if ms < 50
    Color::GREEN
  elsif ms < 150
    Color::YELLOW
  else
    Color::RED
  end

  "#{color}#{bar}#{Color::RESET} #{ms} ms"
end

# ── Main Program ──────────────────────────────────────────
print "  Masukkan host/domain:\n  → "
$stdout.flush
host = gets.to_s.strip.sub(/^https?:\/\//, "").split("/").first

if host.to_s.empty?
  puts "  #{Color::RED}[!] Host tidak boleh kosong.#{Color::RESET}"
  exit 1
end

print "\n  Masukkan port [default: 80]:\n  → "
$stdout.flush
port_input = gets.to_s.strip
port = port_input.empty? ? 80 : port_input.to_i

print "\n  Jumlah pengukuran [default: 10]:\n  → "
$stdout.flush
count_input = gets.to_s.strip
count = count_input.empty? ? 10 : [count_input.to_i, 1].max

interval = 0.5  # jeda antar pengukuran (detik)

puts "\n  Host      : #{host}"
puts "  Port      : #{port}"
puts "  Pengukuran: #{count}x (interval #{interval}s)"
puts "  #{'─' * 60}"

latencies = []
errors    = 0

count.times do |i|
  result = measure_tcp_latency(host, port)

  if result[:success]
    lat = result[:latency_ms]
    latencies << lat
    bar = latency_bar(lat)
    puts "  #{Color::DIM}[#{(i+1).to_s.rjust(2)}]#{Color::RESET} #{bar}"
  else
    errors += 1
    puts "  #{Color::DIM}[#{(i+1).to_s.rjust(2)}]#{Color::RESET} #{Color::RED}✗ #{result[:error]}#{Color::RESET}"
  end

  sleep interval unless i == count - 1
end

puts "\n  #{'─' * 60}"

# Statistik
if latencies.empty?
  puts "  #{Color::RED}Tidak ada pengukuran yang berhasil.#{Color::RESET}"
else
  stats = calculate_stats(latencies)
  packet_loss = ((errors.to_f / count) * 100).round(1)

  puts "\n  #{Color::YELLOW}▸ Statistik Latensi:#{Color::RESET}"
  puts "    Minimum   : #{Color::GREEN}#{stats[:min]} ms#{Color::RESET}"
  puts "    Maximum   : #{stats[:max] > 300 ? Color::RED : Color::YELLOW}#{stats[:max]} ms#{Color::RESET}"
  puts "    Rata-rata : #{stats[:avg] < 100 ? Color::GREEN : Color::YELLOW}#{stats[:avg]} ms#{Color::RESET}"
  puts "    Jitter    : #{stats[:jitter] < 20 ? Color::GREEN : Color::YELLOW}#{stats[:jitter]} ms#{Color::RESET}"
  puts "    Sukses    : #{Color::GREEN}#{latencies.length}/#{count}#{Color::RESET}"
  puts "    Packet Loss: #{packet_loss > 0 ? Color::RED : Color::GREEN}#{packet_loss}%#{Color::RESET}"

  # Penilaian kualitas koneksi
  puts "\n  #{Color::YELLOW}▸ Penilaian Kualitas Koneksi:#{Color::RESET}"
  avg = stats[:avg]
  jitter = stats[:jitter]

  quality = if packet_loss > 10
    ["Buruk", Color::RED, "Packet loss tinggi. Koneksi tidak stabil."]
  elsif avg < 50 && jitter < 20
    ["Sangat Baik", Color::GREEN, "Latensi rendah dan stabil. Ideal untuk gaming/VoIP."]
  elsif avg < 100 && jitter < 50
    ["Baik", Color::GREEN, "Latensi normal. Cocok untuk browsing dan streaming."]
  elsif avg < 200
    ["Cukup", Color::YELLOW, "Latensi agak tinggi. Mungkin ada bottleneck."]
  else
    ["Buruk", Color::RED, "Latensi sangat tinggi. Periksa koneksi jaringan Anda."]
  end

  puts "    Rating    : #{quality[1]}#{quality[0]}#{Color::RESET}"
  puts "    Keterangan: #{quality[2]}"
end
