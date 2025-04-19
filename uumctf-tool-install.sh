#!/bin/bash

# Script to install CTF tools on Kali Linux
# Created: April 19, 2025

echo "[+] Starting CTF tools installation script..."

# Update package lists
echo "[+] Updating package lists..."
sudo apt update

# Install exiftool
echo "[+] Installing exiftool..."
sudo apt install -y exiftool

# Install ghex (hex editor)
echo "[+] Installing ghex..."
sudo apt install -y ghex

# Install binwalk
echo "[+] Installing binwalk..."
sudo apt install -y binwalk

# Install zsteg
echo "[+] Installing zsteg..."
sudo apt install -y ruby-dev
sudo gem install zsteg

# Install steghide
echo "[+] Installing steghide..."
sudo apt install -y steghide

# Install stegsolve
echo "[+] Installing stegsolve..."
if [ ! -d "/opt/stegsolve" ]; then
    sudo mkdir -p /opt/stegsolve
fi
cd /opt/stegsolve
sudo wget -q http://www.caesum.com/handbook/Stegsolve.jar -O stegsolve.jar
sudo chmod +x stegsolve.jar
echo '#!/bin/bash' | sudo tee /usr/local/bin/stegsolve > /dev/null
echo 'java -jar /opt/stegsolve/stegsolve.jar' | sudo tee -a /usr/local/bin/stegsolve > /dev/null
sudo chmod +x /usr/local/bin/stegsolve

# Install oletools
echo "[+] Installing oletools..."
sudo pip3 install oletools

# Install PDFiD and pdf-parser.py
echo "[+] Installing PDFiD and pdf-parser.py..."
cd /tmp
sudo wget -q https://github.com/DidierStevens/DidierStevensSuite/raw/master/pdfid.py
sudo wget -q https://github.com/DidierStevens/DidierStevensSuite/raw/master/pdf-parser.py
sudo chmod +x pdfid.py pdf-parser.py
sudo mv pdfid.py pdf-parser.py /usr/local/bin/

# Install peepdf
echo "[+] Installing peepdf..."
cd /opt
sudo git clone https://github.com/jesparza/peepdf.git
cd peepdf
sudo ln -sf /opt/peepdf/peepdf.py /usr/local/bin/peepdf

# Verify installations
echo "[+] Verifying installations..."

# Check each tool
declare -A tools
tools=(
    ["exiftool"]="exiftool -ver"
    ["ghex"]="which ghex"
    ["binwalk"]="binwalk -h"
    ["zsteg"]="zsteg -h"
    ["steghide"]="steghide --version"
    ["stegsolve"]="which stegsolve"
    ["oletools"]="pip3 show oletools"
    ["pdfid.py"]="which pdfid.py"
    ["pdf-parser.py"]="which pdf-parser.py"
    ["peepdf"]="which peepdf"
)

for tool in "${!tools[@]}"; do
    if eval "${tools[$tool]}" &>/dev/null; then
        echo "[✓] $tool installed successfully!"
    else
        echo "[✗] $tool installation failed."
    fi
done

echo "[+] Installation complete!"
