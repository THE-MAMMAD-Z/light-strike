#!/usr/bin/env bash

# Exit if no domain is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 example.com"
    exit 1
fi

DOMAIN="$1"
OUTPUT_DIR="./${DOMAIN}"

# Create output directory
mkdir -p "${OUTPUT_DIR}"
echo "[+] Output directory created: ${OUTPUT_DIR}"
cd "${OUTPUT_DIR}" || exit 1

echo "=========================================="
echo " Starting Parallel Enumeration for: ${DOMAIN}"
echo "=========================================="

# 1. Subfinder
(
    if command -v subfinder &> /dev/null; then
        echo "[*] Running Subfinder..."
        subfinder -d "${DOMAIN}" -o "subfinder_${DOMAIN}.txt"
    else
        echo "[-] Subfinder not found in PATH, skipping."
    fi
) &

# 2. Sublist3r
(
    SUBLIST3R_PATH="/home/kali/Projects/Sublist3r/sublist3r.py"
    if [ -f "${SUBLIST3R_PATH}" ]; then
        echo "[*] Running Sublist3r..."
        python3 "${SUBLIST3R_PATH}" -d "${DOMAIN}" -o "sublist3r_${DOMAIN}.txt"
    elif command -v sublist3r &> /dev/null; then
        echo "[*] Running Sublist3r..."
        sublist3r -d "${DOMAIN}" -o "sublist3r_${DOMAIN}.txt"
    else
        echo "[-] Sublist3r not found, skipping."
    fi
) &

# 3. Amass
(
    if command -v amass &> /dev/null; then
        echo "[*] Running Amass..."
        amass enum -d "${DOMAIN}" > "amass_${DOMAIN}.txt"
    else
        echo "[-] Amass not found in PATH, skipping."
    fi
) &

# 4. Assetfinder
(
    if command -v assetfinder &> /dev/null; then
        echo "[*] Running Assetfinder..."
        assetfinder "${DOMAIN}" > "assetfinder_${DOMAIN}.txt"
    else
        echo "[-] Assetfinder not found in PATH, skipping."
    fi
) &

# 5. Knockpy
(
    if command -v knockpy &> /dev/null; then
        echo "[*] Running Knockpy..."
        knockpy -d "${DOMAIN}" --silent --recon > "knockpy_${DOMAIN}.txt"
    elif [ -f "knockpy.py" ]; then
        echo "[*] Running Knockpy script..."
        python3 knockpy.py -d "${DOMAIN}" --silent --recon > "knockpy_${DOMAIN}.txt"
    else
        echo "[-] Knockpy not found, skipping."
    fi
) &

# Wait for all background tasks to complete
wait

echo "=========================================="
echo "[+] Enumeration complete. Files saved in ${OUTPUT_DIR}/"
echo "=========================================="