# Project 15 — Mapping the Spatial Cellular Architecture of the Brain

**CAJAL Neuromics 2026 (Bordeaux).** Reconstruct the spatial cellular architecture of the
brain from high-plex, image-based spatial transcriptomics: QC → cell segmentation →
cell-type annotation by label transfer from a scRNA-seq reference atlas → spatial niches →
region-specific cell–cell communication. Notebook-first, [pixi](https://pixi.sh)-managed,
runs on the IFB Core Cluster.

**Links:** [IFB docs](https://doc.cluster.france-bioinformatique.fr/) ·
[OnDemand (run notebooks)](https://ondemand.cluster.france-bioinformatique.fr) ·
[pixi](https://pixi.sh) · [scanpy](https://scanpy.readthedocs.io) ·
[squidpy](https://squidpy.readthedocs.io) · [spatialdata](https://spatialdata.scverse.org)

## 0. One-time access

- **Cluster SSH key** — generate your own on the
  [cluster manager portal](https://my.cluster.france-bioinformatique.fr/manager2/project):
  create a key, download the **private rsa key**, and save it to `~/.ssh/` (`chmod 600`).
  You'll need it for `ssh`, Claude Code, and VS Code Remote-SSH from your laptop.
- **GitHub CLI**, then log in:
  ```bash
  curl -sS https://webi.sh/gh | sh      # installs gh, no sudo
  gh auth login                          # GitHub.com -> HTTPS -> web browser
  ```
- **Fork this repo** to your own GitHub account (top-right on GitHub) — you'll push your
  own analysis there.

## 1. Get the code (in your cluster home)

```bash
mkdir -p ~/github && cd ~/github
gh repo clone <your-username>/cajal-project15-spatial-brain
cd cajal-project15-spatial-brain
```

## 2. Set up — one command

```bash
bash cluster_setup.sh
```

This registers the **`Spatial Brain (SIF)`** Jupyter kernel — the environment every notebook runs
on — and installs the git hooks. A minute or two.

> **You don't build the environment yourself.** The whole scientific stack (scanpy, squidpy,
> spatialdata, sopa, cellpose, cellmapper, …) is pre-packed into **one shared container file** on
> the project filesystem, and the `Spatial Brain (SIF)` kernel just points at it — no big install,
> and it loads in seconds. All the notebooks (Levels 0–3) use this kernel. See
> [`scripts/sif/README.md`](scripts/sif/README.md) for how the container is built.
>
> **Optional — your own pixi environment.** `cluster_setup.sh` *also* builds you a personal
> [pixi](https://pixi.sh) environment (this is the "a few minutes the first time" part). You
> **don't need it to work through the notebooks** — they all run on the SIF kernel — so you can
> ignore it unless you want to `pixi add` packages and experiment. It lives on the **project
> filesystem**, not your home directory (whose ~100,000-file quota a scientific env would blow),
> and hardlinks a shared package cache so it costs only ~17k files; `cluster_setup.sh` sets this
> up for you — don't repoint the cache at home.

## 3. Run your analysis — Open OnDemand (recommended)

Everything runs in your browser, on a compute node — no SSH key or tunnel needed.
[OnDemand](https://ondemand.cluster.france-bioinformatique.fr) → **Interactive Apps**:

- **JupyterLab** — for notebooks; once the session starts, select the
  **`Spatial Brain (SIF)`** kernel. It loads the environment from a single shared
  container file, so it starts in seconds (the older `Spatial Brain (Project 15)`
  pixi kernel still works but cold-starts slowly — it's kept for env development).
- **Visual Studio Code** — a full IDE in the browser.

Request resources (account `tp_2630_ubordeaux_neuromics_184418`, partition `fast`, a few
CPUs / 16 GB) and launch.

> Don't run heavy work on the login node.

**Using Claude Code or a desktop editor?** Connect to the cluster over SSH (with your key
from §0) for editing and git, and run notebooks / heavy compute via OnDemand or Slurm.

## 4. Daily workflow

- Course notebooks live in `analysis/levelN/`, paired as `NN_slug_student.ipynb` (your working
  copy to fill in) and `NN_slug_solution.ipynb` (the executed reference). Add any notebooks of
  your own alongside them with a short, descriptive name.
- Notebooks are committed **with** their outputs — so executed solution notebooks stay readable.
- Commit & push to **your fork**:
  ```bash
  git add -A && git commit -m "..." && git push
  ```
- Add a package **PyPI-first**: `pixi add --pypi <pkg>` (use conda only for hard-to-build
  compiled deps), then commit `pixi.toml` + `pixi.lock` so everyone stays in sync.

## 5. Data

**Staged once, read-only, shared.** The large inputs are staged for the whole course under

```
/shared/projects/tp_2630_ubordeaux_neuromics_184418/projects/C15/data/
```

Read from there, but **never write to it and never copy it into your repo** — several people run in
parallel off the same files. The notebooks already point at this location in their setup cells; the
main inputs are:

| Path (under the data root above) | Level | What it is |
|---|---|---|
| `wang2025_merfish/processed/UCSF2018-003-MFG_baseline.zarr` | L1 | one imaged tissue section (stains + transcripts + vendor cells) to segment |
| `wang2025_merfish/processed/wang2025_merfish_cells_student.h5ad` | L2 | the spatial cell cohort (reference labels stripped — you rebuild them) |
| `wang2025_multiome/processed/wang2025_multiome_rna.h5ad` | L2/L3 | the single-cell RNA reference atlas |
| `wang2025_multiome/processed/wang2025_multiome_atac.h5ad` | L3 | the matched ATAC modality (16 GB — open `backed="r"` and subset before loading) |

*(A couple more files unlock at the Level 2 reveal; the notebooks introduce them where relevant.)*

**Your outputs go in your repo.** Anything you create — processed objects, figures — goes in the
repo's git-ignored `data/` and `figures/`, addressed through the path helper so you never hard-code
paths:

```python
from spatialbrain import FilePaths

FilePaths.DATA                                     # -> <repo>/data
FilePaths.FIGURES                                  # -> <repo>/figures
FilePaths.dataset("wang2025_merfish").processed    # your per-dataset output folder (created on demand)
```

`FilePaths` resolves the repo root at runtime from your working directory, so it works whether you
run under the SIF kernel or a local checkout. To point outputs elsewhere, set the
`SPATIALBRAIN_ROOT` environment variable.

## 6. Compute

This is a **CPU-only** course — there is no GPU partition. Everything is designed to run on CPU:
segmentation parallelises across cores via Sopa, and label transfer uses CPU k-NN. Request a few
CPUs and ~16–32 GB via OnDemand or Slurm; no `gpu` environment is needed or provided.

## Reference

- **Environment:** `pixi.toml` (+ `pixi.lock` for exact, reproducible versions) —
  [pixi docs](https://pixi.sh/latest/).
- **Helper package:** `src/spatialbrain/` — `FilePaths` for project data paths.
- **Code quality:** [pre-commit](https://pre-commit.com/) hooks (set up by `cluster_setup.sh`) —
  [ruff](https://docs.astral.sh/ruff/) lint/format.
- **Science:** [scanpy](https://scanpy.readthedocs.io) · [squidpy](https://squidpy.readthedocs.io) ·
  [spatialdata](https://spatialdata.scverse.org) · [single-cell best practices](https://www.sc-best-practices.org/).
