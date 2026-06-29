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

- **Cluster login** (SSH key) — sent to you separately by the organisers.
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

## 2. Set up the environment — one command

```bash
bash cluster_setup.sh
```

Installs pixi (if needed) and builds the project environment. **Why a script?** The cluster
home directory has a 100,000-*file* quota that a scientific environment would blow, so the
script puts the environment and caches on the large **project filesystem**, then registers a
Jupyter kernel and the git hooks. A few minutes the first time.

## 3. Run your analysis — Open OnDemand JupyterLab (recommended)

1. [ondemand.cluster.france-bioinformatique.fr](https://ondemand.cluster.france-bioinformatique.fr)
   → Interactive Apps → **JupyterLab**.
2. Request resources (account `tp_2630_ubordeaux_neuromics_184418`, partition `fast`, a few
   CPUs / 16 GB) and launch.
3. Open a notebook → select the **"Spatial Brain (Project 15)"** kernel.

> Don't run `jupyter lab` on the login node. (VS Code on a compute node is also possible —
> ask Marius.)

## 4. Daily workflow

- Notebooks live in `analysis/`, named `INITIALS-YYYY-MM-DD_description.ipynb`.
- Notebook outputs are auto-stripped from git (nbstripout) — rendered locally, clean in git.
- Commit & push to **your fork**:
  ```bash
  git add -A && git commit -m "..." && git push
  ```
- Add a package: `pixi add <pkg>` (conda-forge) or `pixi add --pypi <pkg>`, then commit
  `pixi.toml` + `pixi.lock` so everyone stays in sync.

## 5. Data

Raw data is staged once in a shared location (not copied per student); your repo's `data/`
holds smaller processed outputs. Paths are exposed via `from spatialbrain import FilePaths`.
*(Specifics to be added.)*

## 6. GPU

Once the GPU partition is enabled for the course: `pixi install -e gpu` (CUDA build of JAX +
rapids-singlecell).

## Reference

- **Environment:** `pixi.toml` (+ `pixi.lock` for exact, reproducible versions).
- **Helper package:** `src/spatialbrain/` — `FilePaths` for project data paths.
- Single-cell best practices: <https://www.sc-best-practices.org/>
refix.

### Step 5: Verify your setup

```bash
pixi run test                  # should pass (tests your package imports correctly)
pixi run lab                   # opens Jupyter Lab
```

In Jupyter Lab, check that your kernel appears (look for the name you set in `pixi.toml`).

### Step 6: Make your first commit

```bash
git add -A
git commit -m "Initial project setup"
git push
```

💡 Pre-commit hooks will run and may reformat some files. If so, just `git add -A && git commit -m "Initial project setup"` again.

🎉 **You're ready to start analyzing!**

---

## 📊 Start Your Analysis

- **Demo notebook**: Check out `analysis/ML-2026-01-27_demo_scRNA_workflow.ipynb` for a complete scRNA-seq workflow example using scanpy's PBMC 3k dataset.
- **New notebooks**: Copy `analysis/XX-2026-01-27_sample_notebook.ipynb` as a starting point. Follow the naming convention: `[INITIALS]-[YYYY]-[MM]-[DD]_description.ipynb`.
- **Add your data**: Create folders under `data/` and register paths in `src/<your-package>/_constants.py`.
- **Replace this README** with your project documentation once you're set up.

---

## ☕ Daily Workflow

```bash
cd your-project
pixi shell                     # activate environment
jupyter lab                    # work in notebooks, or start via jupyter-hub
# ... do your analysis ...
exit                           # leave pixi shell when done
```

Or run commands directly without entering the shell:

```bash
pixi run lab                   # start Jupyter Lab
pixi run python script.py      # run a script
```

---

## 📚 Reference

<details>
<summary><strong>📦 What is pixi?</strong></summary>

[Pixi](https://pixi.sh) is a modern package manager that handles both **conda** and **PyPI** packages in one tool:

- 🔒 Creates **isolated environments** per project
- 🔀 Installs from **conda-forge AND PyPI** together
- 📌 Locks exact versions for **reproducibility** (`pixi.lock`)
- 💻 Works **cross-platform** (macOS, Linux, Windows)

**You don't need conda or pip installed** — pixi handles everything!

</details>

<details>
<summary><strong>➕ Adding packages</strong></summary>

All dependencies live in `pixi.toml`. To add a new package:

```bash
# From conda-forge (preferred for scientific packages)
pixi add numpy
pixi add "scanpy>=1.10"

# From PyPI (when not on conda-forge)
pixi add --pypi some-package
```

Or edit `pixi.toml` directly and run `pixi install`.

💡 **Tip**: Prefer PyPI packages when available — mixing conda and pip can cause dependency conflicts.

👉 See [pixi documentation](https://pixi.sh/latest/) for more details.

</details>

<details>
<summary><strong>📓 Data and notebook conventions</strong></summary>

- **Notebook naming**: `[INITIALS]-[YYYY]-[MM]-[DD]_description.ipynb`
- **Data layout** (one folder per dataset):
    - `data/<dataset>/raw/` — original data files
    - `data/<dataset>/processed/` — preprocessed data
    - `data/<dataset>/resources/` — reference data, annotations
    - `data/<dataset>/results/` — analysis outputs
- **Figures**: `figures/` or `data/<dataset>/results/`
- **Import paths** via the local package:

```python
from yourpackage import FilePaths
```

</details>

<details>
<summary><strong>🔧 Pre-commit & code quality</strong></summary>

This template uses **pre-commit hooks** to automatically check your code before each commit:

| Tool | What it does |
|------|--------------|
| [Ruff](https://docs.astral.sh/ruff/) | Lints and formats Python code + notebooks |
| [Biome](https://biomejs.dev/) | Formats JSON/JSONC files |
| [pyproject-fmt](https://github.com/tox-dev/pyproject-fmt) | Formats `pyproject.toml` |

**Notebook outputs** are handled separately by an [nbstripout](https://github.com/kynan/nbstripout)
git *filter* (not a pre-commit hook), set up by `pixi run install-hooks`. The filter
strips outputs from the committed copy while leaving them in your working tree, so
your notebooks stay rendered locally but git history stays clean. CI fails the build
if a notebook with outputs ever lands in the repo (a clone that skipped
`install-hooks`), via `nbstripout --verify`.

Hooks run automatically on `git commit`. To run manually:

```bash
pre-commit run --all-files
```

💡 If a check reformats your code, just `git add` the changes and commit again.

</details>

<details>
<summary><strong>🖥️ GPU notes</strong></summary>

The **default** environment is CPU-only on every platform (on macOS, PyTorch
still uses MPS automatically). This is what `pixi install` and CI use.

GPU acceleration lives in a separate **`gpu`** environment that you opt into
explicitly on a Linux/CUDA machine (e.g. ETH Euler):

```bash
pixi install -e gpu            # CUDA 12 build of JAX + rapids-singlecell
pixi run -e gpu install-kernel # register a kernel for the gpu env
pixi shell -e gpu              # or activate it interactively
```

| Environment | PyTorch | JAX | rapids-singlecell |
|-------------|---------|-----|-------------------|
| `default` (all platforms) | ✅ (MPS on macOS) | CPU | ❌ |
| `gpu` (Linux + NVIDIA only) | ✅ CUDA | ✅ CUDA 12 | ✅ |

> Keeping the GPU stack out of the default environment means CI and CPU-only
> machines don't try to resolve unusable CUDA wheels. See
> [rapids-singlecell](https://rapids-singlecell.readthedocs.io/).

</details>

<details>
<summary><strong>🔑 Secrets & environment variables</strong></summary>

Store API keys and other secrets in a `.env` file at the repo root. It is
**gitignored** and must never be committed.

```bash
cp .env.example .env   # then fill in your real values
```

`.env.example` (tracked, placeholder values only) documents which variables the
project expects. Load them in a notebook or script with, e.g.,
[python-dotenv](https://github.com/theskumar/python-dotenv):

```python
from dotenv import load_dotenv
load_dotenv()
```

If you ever paste a real key into a tracked file, rotate it immediately in the
provider's dashboard — git history is hard to scrub.

</details>

<details>
<summary><strong>🖧 Cluster usage</strong></summary>

For cluster usage (e.g., ETH Euler):

- 📚 General docs: https://docs.hpc.ethz.ch/
- 🚀 Notebooks via JupyterHub: https://jupyter.euler.hpc.ethz.ch/hub/

</details>
