#!/usr/bin/env ruby
# encoding: utf-8
#
# Packet Sender - Ruby Module
# Mengirim request ke server untuk menguji koneksi dan respons.
# Mendukung: TCP raw, HTTP GET, HTTP POST, UDP.
# PENTING: Hanya untuk tujuan edukasi dan testing server milik sendiri.
#

require 'socket'
require 'timeout'
require 'net/http'
require 'net/https'
require 'uri'
require 'openssl'
require 'json'

module Color
  RESET  = "\e[0m"
  RED    = "\e[91m"
  GREEN  = "\e[92m"
  YELLOW = "\e[93m"
  CYAN   = "\e[96m"
  BOLD   = "\e[1m"
  DIM    = "\e[2m"
end

def send_tcp_packet(host, port, message, timeout_sec = 5)
  result = { sent: false, received: nil, error: nil, latency_ms: nil }
  begin
    Timeout.timeout(timeout_sec) do
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
      sock  = TCPSocket.new(host, port)
      sock.print(message)

      response = ""
      begin
        while (chunk = sock.read_nonblock(1024))
          response += chunk
          break if response.length > 4096
        end
      rescue IO::WaitReadable
        IO.select([sock], nil, nil, 2)
        retry if response.empty?
      rescue EOFError
        # Normal
      end

      elapsed            = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - start
      result[:sent]      = true
      result[:received]  = response.strip unless response.strip.empty?
      result[:latency_ms]= elapsed.round(2)
      sock.close
    end
  rescue Timeout::Error
    result[:error] = "Timeout"
  rescue Errno::ECONNREFUSED
    result[:error] = "Connection Refused (port tertutup)"
  rescue SocketError => e
    result[:error] = "Error: #{e.message}"
  rescue => e
    result[:error] = e.message
  end
  result
end

def send_http_request(url, method = "GET", headers = {}, body = nil, count = 1)
  results = []
  uri     = URI(url)

  count.times do |i|
    result = { success: false, status: nil, latency_ms: nil, body_preview: nil, error: nil }
    start  = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)

    begin
      Timeout.timeout(10) do
        http = Net::HTTP.new(uri.host, uri.port)
        if uri.scheme == "https"
          http.use_ssl     = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        http.open_timeout = 5
        http.read_timeout = 5

        # Default headers
        default_headers = {
          "User-Agent"   => "NetworkToolkit-PacketSender/1.0",
          "Accept"       => "*/*",
          "Connection"   => "close",
        }
        all_headers = default_headers.merge(headers)

        resp = case method.upcase
               when "GET"    then http.get(uri.request_uri, all_headers)
               when "POST"   then http.post(uri.request_uri, body.to_s, all_headers)
               when "HEAD"   then http.head(uri.request_uri, all_headers)
               when "DELETE" then http.delete(uri.request_uri, all_headers)
               else http.get(uri.request_uri, all_headers)
               end

        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - start

        result[:success]      = true
        result[:status]       = resp.code.to_i
        result[:latency_ms]   = elapsed.round(2)
        result[:body_preview] = resp.body.to_s[0..200] unless method == "HEAD"
        result[:headers]      = resp.each_header.to_h
      end
    rescue => e
      result[:error] = e.message
    end

    results << result
    sleep 0.3 if i < count - 1
  end
  results
end

def send_udp_packet(host, port, message, timeout_sec = 3)
  result = { sent: false, received: nil, error: nil }
  begin
    sock = UDPSocket.new
    sock.send(message, 0, host, port)
    result[:sent] = true

    # Coba terima response (UDP tidak menjamin balasan)
    begin
      Timeout.timeout(timeout_sec) do
        data, _ = sock.recvfrom(1024)
        result[:received] = data.strip unless data.strip.empty?
      end
    rescue Timeout::Error
      result[:received] = "(tidak ada response – normal untuk UDP)"
    end

    sock.close
  rescue SocketError => e
    result[:error] = e.message
  rescue => e
    result[:error] = e.message
  end
  result
end

# ── Main Program ──────────────────────────────────────────
puts "  #{Color::YELLOW}Pilih mode pengiriman:#{Color::RESET}"
puts "  [1] HTTP GET Request"
puts "  [2] HTTP POST Request"
puts "  [3] HTTP HEAD Request"
puts "  [4] TCP Raw Packet"
puts "  [5] UDP Packet"
print "  → "
$stdout.flush
mode = gets.to_s.strip

puts ""

if ["1", "2", "3"].include?(mode)
  # ── HTTP Modes ─────────────────────────────────────────
  print "  Masukkan URL (misal: https://httpbin.org/get):\n  → "
  $stdout.flush
  url = gets.to_s.strip
  url = "https://#{url}" unless url.start_with?("http")

  print "\n  Jumlah request [default: 1, max: 10]:\n  → "
  $stdout.flush
  count_str = gets.to_s.strip
  count     = count_str.empty? ? 1 : [[count_str.to_i, 1].max, 10].min

  body    = nil
  headers = {}

  if mode == "2"
    print "\n  Masukkan body (JSON format, misal: {\"key\":\"value\"}):\n  → "
    $stdout.flush
    body = gets.to_s.strip
    headers["Content-Type"] = "application/json" if body.start_with?("{")
  end

  method_map = { "1" => "GET", "2" => "POST", "3" => "HEAD" }
  method     = method_map[mode]

  puts "\n  Target  : #{url}"
  puts "  Method  : #{method}"
  puts "  Count   : #{count}x"
  puts "  #{'─' * 60}"

  results     = send_http_request(url, method, headers, body, count)
  latencies   = []
  success_cnt = 0

  results.each_with_index do |r, i|
    puts "\n  #{Color::DIM}[Request #{i+1}]#{Color::RESET}"
    if r[:success]
      success_cnt += 1
      latencies   << r[:latency_ms]
      code        = r[:status]
      code_color  = code < 300 ? Color::GREEN : code < 400 ? Color::YELLOW : Color::RED
      puts "    Status      : #{code_color}#{code}#{Color::RESET}"
      puts "    Latency     : #{r[:latency_ms]} ms"

      # Tampilkan beberapa header penting
      imp_h = %w[server content-type x-powered-by content-length]
      imp_h.each do |h|
        val = r[:headers][h]
        puts "    #{h.capitalize.ljust(14)}: #{val}" if val
      end

      # Preview body
      if r[:body_preview] && !r[:body_preview].empty?
        puts "    Body Preview: #{Color::DIM}#{r[:body_preview][0..100].gsub(/\s+/, ' ')}#{Color::RESET}"
      end
    else
      puts "    #{Color::RED}✗ Error: #{r[:error]}#{Color::RESET}"
    end
  end

  # Statistik
  if latencies.length > 1
    puts "\n  #{'─' * 60}"
    puts "  #{Color::YELLOW}▸ Statistik:#{Color::RESET}"
    puts "    Sukses    : #{success_cnt}/#{count}"
    puts "    Min       : #{latencies.min} ms"
    puts "    Max       : #{latencies.max} ms"
    puts "    Avg       : #{(latencies.sum / latencies.length).round(2)} ms"
  end

elsif mode == "4"
  # ── TCP Raw ────────────────────────────────────────────
  print "  Host:\n  → "
  $stdout.flush
  host = gets.to_s.strip

  print "  Port:\n  → "
  $stdout.flush
  port = gets.to_s.strip.to_i

  print "  Pesan yang dikirim [default: 'HELLO\\r\\n']:\n  → "
  $stdout.flush
  msg_input = gets.to_s.strip
  message   = msg_input.empty? ? "HELLO\r\n" : msg_input + "\r\n"

  puts "\n  Host    : #{host}:#{port}"
  puts "  Payload : #{message.inspect}"
  puts "  #{'─' * 60}"

  result = send_tcp_packet(host, port, message)
  if result[:sent]
    puts "\n  #{Color::GREEN}✓ Packet berhasil dikirim#{Color::RESET}"
    puts "    Latency : #{result[:latency_ms]} ms"
    if result[:received]
      puts "\n  #{Color::YELLOW}▸ Response dari server:#{Color::RESET}"
      result[:received].each_line { |l| puts "    #{l.chomp}" }
    else
      puts "    Server tidak mengirim response."
    end
  else
    puts "\n  #{Color::RED}✗ Gagal: #{result[:error]}#{Color::RESET}"
  end

elsif mode == "5"
  # ── UDP ────────────────────────────────────────────────
  print "  Host:\n  → "
  $stdout.flush
  host = gets.to_s.strip

  print "  Port:\n  → "
  $stdout.flush
  port = gets.to_s.strip.to_i

  print "  Pesan:\n  → "
  $stdout.flush
  message = gets.to_s.strip

  puts "\n  Host    : #{host}:#{port}"
  puts "  Payload : #{message}"
  puts "  #{'─' * 60}"

  result = send_udp_packet(host, port, message)
  if result[:sent]
    puts "\n  #{Color::GREEN}✓ UDP Packet dikirim#{Color::RESET}"
    puts "    Response: #{result[:received]}"
  else
    puts "\n  #{Color::RED}✗ Gagal: #{result[:error]}#{Color::RESET}"
  end

else
  puts "  #{Color::RED}[!] Pilihan tidak valid.#{Color::RESET}"
  exit 1
end
