#!/usr/bin/env bash
set -euo pipefail

fail=0
pass(){ printf '[PASS] %s\n' "$1"; }
warn(){ printf '[WARN] %s\n' "$1"; }
failmsg(){ printf '[FAIL] %s\n' "$1"; fail=1; }

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  [[ "${ID:-}" == "ubuntu" && "${VERSION_ID:-}" == "24.04" ]] && pass "Ubuntu 24.04" || warn "Expected Ubuntu 24.04; found ${PRETTY_NAME:-unknown}"
else failmsg "/etc/os-release unavailable"; fi

arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
[[ "$arch" == "amd64" || "$arch" == "x86_64" ]] && pass "Architecture: $arch" || failmsg "Beacon scripts are pinned for amd64; found $arch"

cpu=$(nproc)
(( cpu >= 4 )) && pass "CPU: ${cpu} vCPU" || failmsg "Need at least 4 vCPU; found ${cpu}"

mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_gb=$((mem_kb/1024/1024))
(( mem_gb >= 10 )) && pass "RAM: ~${mem_gb} GiB" || failmsg "Need at least ~10 GiB RAM; found ~${mem_gb} GiB"

avail_kb=$(df -Pk / | awk 'NR==2 {print $4}')
avail_gb=$((avail_kb/1024/1024))
(( avail_gb >= 40 )) && pass "Free disk on /: ~${avail_gb} GiB" || failmsg "Need at least 40 GiB free; found ~${avail_gb} GiB"

for host in download.jetbrains.com download.docker.com github.com dl.k8s.io mcr.microsoft.com registry-1.docker.io; do
  getent hosts "$host" >/dev/null && pass "DNS: $host" || failmsg "DNS failed: $host"
done
curl -fsSI --max-time 10 https://download.jetbrains.com >/dev/null && pass "HTTPS outbound" || failmsg "HTTPS outbound failed"

timedatectl show -p NTPSynchronized --value 2>/dev/null | grep -qi true && pass "NTP synchronized" || warn "NTP not confirmed; check timedatectl"

for p in 5111 6550 8111 1322; do
  if ss -ltn "sport = :$p" | tail -n +2 | grep -q .; then failmsg "Port $p already in use"; else pass "Port $p free"; fi
done

if (( fail )); then echo 'BEACON PREFLIGHT: FAIL'; exit 1; fi
echo 'BEACON PREFLIGHT: PASS'
