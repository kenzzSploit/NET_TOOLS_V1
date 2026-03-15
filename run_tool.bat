@echo off
:: ============================================================
::  Network Toolkit - Windows Launcher
::  Jalankan file ini untuk memulai Network Toolkit di Windows
:: ============================================================

title Network Toolkit - Python + Ruby Edition

:: Cek apakah Python tersedia
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python tidak ditemukan!
    echo Silakan install Python dari: https://www.python.org/downloads/
    echo Pastikan centang "Add Python to PATH" saat install.
    pause
    exit /b 1
)

:: Cek apakah Ruby tersedia
ruby --version >nul 2>&1
if errorlevel 1 (
    echo [PERINGATAN] Ruby tidak ditemukan!
    echo Fitur Ruby ^(11-20^) tidak akan bisa digunakan.
    echo Install Ruby dari: https://rubyinstaller.org/
    echo.
    echo Tekan Enter untuk lanjut dengan fitur Python saja...
    pause >nul
)

:: Pindah ke direktori script
cd /d "%~dp0"

:: Jalankan main.py
python main.py

:: Jika error, tampilkan pesan
if errorlevel 1 (
    echo.
    echo [ERROR] Terjadi kesalahan saat menjalankan program.
    pause
)
