#!/usr/bin/env bash

# Exit if no domain is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 example.com"
    exit 1
fi

DOMAIN="$1"
OUTPUT_DIR="./${DOMAIN}"

# ==============================
# Paths
# ==============================

SUBLIST3R_PATH="/home/kali/Projects/Sublist3r/sublist3r.py"
KNOCKPY_PATH="/home/kali/Projects/knockpy/knockpy.py"
CRTSH_PATH="/home/kali/Projects/crt.sh_3.0.3_linux_amd64/crt.sh"

# ==============================
# Create output directory
# ==============================

mkdir -p "${OUTPUT_DIR}" || exit 1

echo "[+] Output directory created: ${OUTPUT_DIR}"

cd "${OUTPUT_DIR}" || exit 1

echo "=========================================="
echo " Starting Parallel Enumeration for: ${DOMAIN}"
echo "=========================================="

# ==============================
# 1. Subfinder
# ==============================

(
    if command -v subfinder >/dev/null 2>&1; then
        echo "[*] Running Subfinder..."

        subfinder \
            -d "${DOMAIN}" \
            -o "subfinder_${DOMAIN}.txt"

        if [ $? -eq 0 ]; then
            echo "[+] Subfinder completed."
        else
            echo "[-] Subfinder failed."
        fi
    else
        echo "[-] Subfinder not found in PATH, skipping."
    fi
) &

# ==============================
# 2. Sublist3r
# ==============================

(
    if [ -f "${SUBLIST3R_PATH}" ]; then
        echo "[*] Running Sublist3r..."

        python3 "${SUBLIST3R_PATH}" \
            -d "${DOMAIN}" \
            -o "sublist3r_${DOMAIN}.txt"

        if [ $? -eq 0 ]; then
            echo "[+] Sublist3r completed."
        else
            echo "[-] Sublist3r finished with errors."
        fi
    else
        echo "[-] Sublist3r not found: ${SUBLIST3R_PATH}"
    fi
) &

# ==============================
# 3. Amass
# ==============================

(
    if command -v amass >/dev/null 2>&1; then
        echo "[*] Running Amass..."

        amass enum \
            -d "${DOMAIN}" \
            > "amass_${DOMAIN}.txt" 2>&1

        if [ $? -eq 0 ]; then
            echo "[+] Amass completed."
        else
            echo "[-] Amass failed."
        fi
    else
        echo "[-] Amass not found in PATH, skipping."
    fi
) &

# ==============================
# 4. Assetfinder
# ==============================

(
    if command -v assetfinder >/dev/null 2>&1; then
        echo "[*] Running Assetfinder..."

        assetfinder "${DOMAIN}" \
            > "assetfinder_${DOMAIN}.txt" 2>&1

        if [ $? -eq 0 ]; then
            echo "[+] Assetfinder completed."
        else
            echo "[-] Assetfinder failed."
        fi
    else
        echo "[-] Assetfinder not found in PATH, skipping."
    fi
) &

# ==============================
# 5. Knockpy
# ==============================

(
    if [ -f "${KNOCKPY_PATH}" ]; then
        echo "[*] Running Knockpy..."

        python3 "${KNOCKPY_PATH}" \
            -d "${DOMAIN}" \
            --silent \
            --recon \
            > "knockpy_${DOMAIN}.txt" 2>&1

        if [ $? -eq 0 ]; then
            echo "[+] Knockpy completed."
        else
            echo "[-] Knockpy failed."
        fi
    else
        echo "[-] Knockpy not found: ${KNOCKPY_PATH}"
    fi
) &

# ==============================
# 6. crt.sh
# ==============================

(
    if [ -x "${CRTSH_PATH}" ]; then
        echo "[*] Running crt.sh..."

        "${CRTSH_PATH}" \
            -d "${DOMAIN}" \
            -o "crt_${DOMAIN}.txt"

        if [ $? -eq 0 ]; then
            echo "[+] crt.sh completed."
        else
            echo "[-] crt.sh failed."
        fi

    elif [ -f "${CRTSH_PATH}" ]; then
        echo "[-] crt.sh exists but is not executable."
        echo "[*] Run: chmod +x ${CRTSH_PATH}"
    else
        echo "[-] crt.sh not found: ${CRTSH_PATH}"
    fi
) &

# ==============================
# 7. Findomain via Docker
# ==============================

(
    if command -v docker >/dev/null 2>&1; then

        if docker info >/dev/null 2>&1; then

            echo "[*] Running Findomain via Docker..."

            docker run --rm \
                -v "$(pwd):/output" \
                edu4rdshl/findomain:latest \
                -t "${DOMAIN}" \
                -u "/output/findomain_${DOMAIN}.txt"

            if [ $? -eq 0 ]; then
                echo "[+] Findomain completed."
            else
                echo "[-] Findomain failed."
            fi

        else
            echo "[-] Docker is installed but current user cannot access Docker daemon."
            echo "    Try: sudo usermod -aG docker \$USER"
            echo "    Then log out and log back in."
        fi

    else
        echo "[-] Docker not found, skipping Findomain."
    fi
) &

# ==============================
# Wait for all tools
# ==============================

echo
echo "[*] Waiting for all enumeration tools..."
wait

# ==============================
# Clean Amass output
# ==============================

if [ -f "amass_${DOMAIN}.txt" ]; then
    echo "[*] Cleaning Amass output..."

    # Remove Amass banner/header lines.
    # Only do this if the file actually has content.
    sed -i '1,4d' "amass_${DOMAIN}.txt"
fi

# ==============================
# Combine results
# ==============================

echo "[*] Combining results..."

cat *_${DOMAIN}.txt 2>/dev/null \
    | sed 's/\r//g' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
    | grep -E '^[A-Za-z0-9*._-]+\.[A-Za-z]{2,}$' \
    | sort -u \
    > "all_${DOMAIN}.txt"

# ==============================
# Results
# ==============================

echo
echo "=========================================="
echo "[+] Enumeration complete."
echo "=========================================="

echo
echo "[+] Result files:"

ls -lh *_${DOMAIN}.txt 2>/dev/null

echo
echo "[+] Unique subdomains found:"

wc -l < "all_${DOMAIN}.txt"

echo
echo "[+] Final file:"
echo "    ${OUTPUT_DIR}/all_${DOMAIN}.txt"

echo "=========================================="