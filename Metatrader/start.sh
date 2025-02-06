#!/bin/bash

# Configuration variables
mt4file='/config/.wine/drive_c/Program Files (x86)/MetaTrader 4/terminal.exe'
WINEPREFIX='/config/.wine'
wine_executable="wine"
metatrader_version="4.0.2"
mt4server_port="8001"
mono_url="https://dl.winehq.org/wine/wine-mono/8.0.0/wine-mono-8.0.0-x86.msi"
python_url="https://www.python.org/ftp/python/3.9.0/python-3.9.0.exe"
mt4setup_url="https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4oldsetup.exe"

# Function to display a graphical message
show_message() {
    echo $1
}

# Function to check if a dependency is installed
check_dependency() {
    if ! command -v $1 &> /dev/null; then
        echo "$1 is not installed. Please install it to continue."
        exit 1
    fi
}

# Function to check if a Python package is installed
is_python_package_installed() {
    python3 -c "import pkg_resources; exit(not pkg_resources.require('$1'))" 2>/dev/null
    return $?
}

# Function to check if a Python package is installed in Wine
is_wine_python_package_installed() {
    $wine_executable python -c "import pkg_resources; exit(not pkg_resources.require('$1'))" 2>/dev/null
    return $?
}

# Check for necessary dependencies
check_dependency "curl"
check_dependency "$wine_executable"

# Install Mono if not present
if [ ! -e "/config/.wine/drive_c/windows/mono" ]; then
    show_message "[1/7] Downloading and installing Mono..."
    curl -o /config/.wine/drive_c/mono.msi $mono_url
    WINEDLLOVERRIDES=mscoree=d $wine_executable msiexec /i /config/.wine/drive_c/mono.msi /qn
    rm /config/.wine/drive_c/mono.msi
    show_message "[1/7] Mono installed."
else
    show_message "[1/7] Mono is already installed."
fi

# Prima di installare MT4, rimuovi eventuali chiavi di registro di MetaTrader5
show_message "[0/7] Rimuovendo eventuali chiavi MT5 dal registro Wine..."
$wine_executable reg delete "HKEY_CURRENT_USER\\Software\\MetaQuotes" /f 2>/dev/null

# Check if MetaTrader 4 is already installed
if [ -e "$mt4file" ]; then
    show_message "[2/7] File $mt4file already exists."
else
    show_message "[2/7] File $mt4file is not installed. Installing via mt4oldsetup.exe..."
    curl -o /config/.wine/drive_c/mt4oldsetup.exe $mt4setup_url
    show_message "[3/7] Installing MetaTrader 4..."
    $wine_executable "/config/.wine/drive_c/mt4oldsetup.exe" "/auto" &
    wait
    # ...opzionale: mantenere o rimuovere l'installer...
    # rm -f /config/.wine/drive_c/mt4oldsetup.exe
fi

# Recheck if MetaTrader 4 is installed
if [ -e "$mt4file" ]; then
    show_message "[4/7] File $mt4file is installed. Running MT4..."
    # Applica fix registri per MT4
    show_message "[4.1/7] Aggiornando registri per MT4..."
    $wine_executable reg add "HKEY_CURRENT_USER\\Software\\MetaQuotes\\Terminal" /v ProductName /t REG_SZ /d "MetaTrader 4" /f
    $wine_executable reg add "HKEY_CURRENT_USER\\Software\\MetaQuotes\\Terminal" /v Version /t REG_SZ /d "$metatrader_version" /f
    $wine_executable "$mt4file" &
else
    show_message "[4/7] File $mt4file is not installed. MT4 cannot be run."
fi

# Install Python in Wine if not present
if ! $wine_executable python --version 2>/dev/null; then
    show_message "[5/7] Installing Python in Wine..."
    curl -L $python_url -o /tmp/python-installer.exe
    $wine_executable /tmp/python-installer.exe /quiet InstallAllUsers=1 PrependPath=1
    rm /tmp/python-installer.exe
    show_message "[5/7] Python installed in Wine."
else
    show_message "[5/7] Python is already installed in Wine."
fi

# Upgrade pip and install required packages
show_message "[6/7] Installing Python libraries"
$wine_executable python -m pip install --upgrade --no-cache-dir pip
# Install MetaTrader4 library in Windows if not installed
show_message "[6/7] Installing MetaTrader4 library in Windows"
if ! is_wine_python_package_installed "MetaTrader4==$metatrader_version"; then
    $wine_executable python -m pip install --no-cache-dir MetaTrader4==$metatrader_version
fi
# Install mt5linux library in Windows if not installed
show_message "[6/7] Checking and installing mt5linux library in Windows if necessary"
if ! is_wine_python_package_installed "mt5linux"; then
    $wine_executable python -m pip install --no-cache-dir mt5linux
fi

# Install mt5linux library in Linux if not installed
show_message "[6/7] Checking and installing mt5linux library in Linux if necessary"
if ! is_python_package_installed "mt5linux"; then
    pip install --upgrade --no-cache-dir mt5linux
fi

# Install pyxdg library in Linux if not installed
show_message "[6/7] Checking and installing pyxdg library in Linux if necessary"
if ! is_python_package_installed "pyxdg"; then
    pip install --upgrade --no-cache-dir pyxdg
fi

# Start the MT4 server on Linux
show_message "[7/7] Starting the mt4linux server..."
python3 -m mt5linux --host 0.0.0.0 -p $mt4server_port -w $wine_executable python.exe &

# Give the server some time to start
sleep 5

# Check if the server is running
if ss -tuln | grep ":$mt4server_port" > /dev/null; then
    show_message "[7/7] The mt4linux server is running on port $mt4server_port."
else
    show_message "[7/7] Failed to start the mt4linux server on port $mt4server_port."
fi