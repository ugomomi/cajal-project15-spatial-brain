#!/usr/bin/env bash
# Add extra Python packages on top of the shared course container — just for you.
#
#     bash scripts/sif_pip.sh <package> [<package> ...]     # e.g. harmonypy pertpy
#     bash scripts/sif_pip.sh -r requirements.txt           # from a file
#     bash scripts/sif_pip.sh list                          # list what you've added
#
# WHY THIS EXISTS
# The course container (the "Spatial Brain (SIF)" Jupyter kernel registered by
# scripts/cluster_setup.sh) is read-only and shared by everyone — you can't, and shouldn't,
# install into it. Instead this installs into your personal user-site, ~/.local, which the
# SIF kernel already picks up: Apptainer bind-mounts your home into the container and the
# container's Python has user-site enabled. Your packages then appear in notebooks with NO
# kernel or config changes — just restart the kernel afterwards.
#
# It builds nothing and never writes to the (shared, often-full) project filesystem. The
# container is already very complete (scanpy, squidpy, numpy, scikit-learn, torch, …), so most
# packages just reuse what's there and cost almost nothing. AVOID packages that re-pull a whole
# compiled stack (jax, tensorflow) — those are large and slow, and usually unnecessary.
set -euo pipefail

SIF=/shared/projects/tp_2630_ubordeaux_neuromics_184418/containers/marius/spatialbrain.sif

usage() {
  cat <<'EOF'
Add extra Python packages on top of the shared course container — just for you.

  bash scripts/sif_pip.sh <package> [<package> ...]     e.g. harmonypy pertpy
  bash scripts/sif_pip.sh -r requirements.txt           from a file
  bash scripts/sif_pip.sh list                          list what you've added

Installs into your personal ~/.local, which the "Spatial Brain (SIF)" kernel already sees —
restart the kernel afterwards. Builds nothing; never touches the project filesystem.
EOF
}

case "${1:-}" in
  ""|-h|--help) usage; exit 0 ;;
esac

[ -e "$SIF" ] || { echo "ERROR: course container not found at $SIF — tell the instructor."; exit 1; }
command -v apptainer >/dev/null 2>&1 || {
  echo "ERROR: apptainer not found — run this on the cluster (login node, or an OnDemand/Slurm session)."; exit 1; }

# Run a command inside the read-only container, with your home + /shared visible.
insif() { apptainer exec --bind /shared "$SIF" "$@"; }

# The container ships without pip; bootstrap it into ~/.local once (idempotent).
if ! insif python -m pip --version >/dev/null 2>&1; then
  echo ">> first run: bootstrapping pip into ~/.local (one-time)…"
  insif python -m ensurepip --user >/dev/null
fi

if [ "$1" = "list" ]; then
  insif python -m pip list --user --disable-pip-version-check
  exit 0
fi

echo ">> installing into your ~/.local (the SIF kernel will see these): $*"
# --no-warn-script-location / --disable-pip-version-check just quiet cosmetic pip banners;
# imports resolve via user-site regardless of whether ~/.local/bin is on PATH.
insif python -m pip install --user --no-cache-dir \
  --no-warn-script-location --disable-pip-version-check "$@"
echo ">> done — restart your Jupyter kernel to pick up the new package(s)."
