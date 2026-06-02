# SWAP & RAM Memory Optimizer

A lightweight, automated Bash script designed to safely flush SWAP memory back into physical RAM. Unlike naive execution scripts, this tool calculates the real available system memory (including recoverable caches and buffers) beforehand. It ensures your system has enough overhead to absorb the SWAP payload without triggering the Out-of-Memory (OOM) Killer or causing system instability.

## Features

* **Safety Checks First:** Verifies root privileges and automatically checks if your system's RAM can safely absorb the currently used SWAP.
* **Pre-emptive Cache Cleaning:** Drops `pagecache`, `dentries`, and `inodes` (`drop_caches=3`) only if necessary, maximizing available RAM right before the flush.
* **Data Integrity:** Runs `sync` prior to cache manipulation to force dirty pages to disk and avoid any data loss.
* **Interactive Mode:** Prompts the user for confirmation before taking action, but only if the operation is deemed viable by the system check.
* **Visual Output:** Implements structured ANSI color codes for readable terminal feedback.

---

## Prerequisites

* Linux-based operating system with `bash`.
* Root privileges (`sudo`).
* Standard utilities: `free`, `awk`, `sync`, `swapoff`, `swapon`.

---

## Usage

### Option 1: Standard Execution (Local Machine)

1. Clone or download the script:
   ```bash
   wget [https://raw.githubusercontent.com/majz1/swap-optimizer/main/swap-optimizer.sh]
