#!/bin/bash
#
# Title:        swap-optimizer.sh
# Description:  Safely flushes SWAP memory into RAM by clearing pagecache,
#               dentries, and inodes first, preventing OOM situations.
# Author:       Mario JB / majz1
#

# --- Colors Definition (ANSI Escape Codes) ---
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[1;36m'
COLOR_RESET='\033[0m'

# --- Root Privilege Verification ---
if [ "$EUID" -ne 0 ]; then
  echo -e "${COLOR_RED}[-][ERROR] This script must be run with root privileges (sudo).${COLOR_RESET}"
  exit 1
fi

echo -e "${COLOR_CYAN}=================================================="
echo "         SWAP & RAM Memory Optimization           "
echo -e "==================================================${COLOR_RESET}"

# --- Memory Metrics Gathering (Megabytes) ---
RAM_FREE=$(free -m | awk '/^Mem:/ {print $4}')
RAM_CACHE=$(free -m | awk '/^Mem:/ {print $6}')
SWAP_USED=$(free -m | awk '/^Swap:/ {print $3}')

# Total memory that can potentially be reclaimed (Free + Buffers/Cache)
RAM_TOTAL_AVAILABLE=$((RAM_FREE + RAM_CACHE))

echo -e "${COLOR_MAGENTA}[+] Current SWAP usage:${COLOR_RESET} ${SWAP_USED} MB"
echo -e "${COLOR_BLUE}[+] Unused physical RAM:${COLOR_RESET} ${RAM_FREE} MB"
echo -e "${COLOR_BLUE}[+] RAM allocated in Cache/Buffers:${COLOR_RESET} ${RAM_CACHE} MB"
echo -e "${COLOR_GREEN}[+] Total available RAM for allocation:${COLOR_RESET} ${RAM_TOTAL_AVAILABLE} MB"
echo -e "${COLOR_CYAN}--------------------------------------------------${COLOR_RESET}"

# --- Pre-execution Safety Checks ---

# Check 1: Verify if SWAP usage is already zero
if [ "$SWAP_USED" -eq 0 ]; then
  echo -e "${COLOR_GREEN}[*] SWAP space is empty. No action required.${COLOR_RESET}"
  exit 0
fi

# Check 2: Evaluate if RAM can absorb SWAP safely (100MB safety margin included)
if [ "$RAM_TOTAL_AVAILABLE" -le "$((SWAP_USED + 100))" ]; then
  echo -e "${COLOR_RED}[-][CRITICAL] Aborting: Insufficient RAM to absorb SWAP data.${COLOR_RESET}"
  echo -e "${COLOR_YELLOW}    Proceeding risks system instability or triggering the OOM Killer.${COLOR_RESET}"
  exit 1
fi

# --- Interactive Confirmation Prompt ---
echo -e "${COLOR_GREEN}[+] System resources are adequate for optimization.${COLOR_RESET}"
echo -e -n "${COLOR_YELLOW}Do you want to clear the cache and flush SWAP now? [y/N]: ${COLOR_RESET}"
read -r response

# Normalize response to lowercase and validate
case " ${response,,} " in
  " y " | " yes " | " s " | " si ")
    echo -e "${COLOR_CYAN}--------------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_BLUE}[!] Configuration approved. Starting optimization procedure...${COLOR_RESET}"
    ;;
  *)
    echo -e "${COLOR_YELLOW}[-] Operation canceled by the user.${COLOR_RESET}"
    exit 0
    ;;
esac

# --- Optimization Procedure ---

# 1. Synchronize data blocks to storage to avoid data loss
echo -e "${COLOR_BLUE}[+] Synchronizing cached data to disk (sync)...${COLOR_RESET}"
sync

# 2. Release PageCache, dentries, and inodes
echo -e "${COLOR_BLUE}[+] Reclaiming memory from pagecache, dentries and inodes (drop_caches)...${COLOR_RESET}"
echo 3 > /proc/sys/vm/drop_caches

# Short pause for kernel memory rebalancing
sleep 2

# 3. Disable and re-enable SWAP to force reallocation into RAM
echo -e "${COLOR_BLUE}[+] Flushing SWAP memory back to physical RAM (this may take a moment)...${COLOR_RESET}"
swapoff -a && swapon -a

# --- Final Status Report ---
if [ $? -eq 0 ]; then
  echo -e "${COLOR_GREEN}[+] Optimization completed successfully.${COLOR_RESET}"
  echo -e "${COLOR_CYAN}--------------------------------------------------${COLOR_RESET}"
  echo -e "${COLOR_GREEN}[+] Post-optimization memory status:${COLOR_RESET}"
  free -m
else
  echo -e "${COLOR_RED}[-][ERROR] Failed to re-enable SWAP allocation.${COLOR_RESET}"
fi
