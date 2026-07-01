"""Project-wide path constants for notebooks and scripts."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

# Files that mark the repository root, searched for upward from a start directory.
_ROOT_MARKERS = ("pixi.toml", ".git")


def _search_up(base: Path) -> Path | None:
    """Return the nearest ancestor of ``base`` (inclusive) holding a root marker."""
    for parent in (base, *base.parents):
        if any((parent / marker).exists() for marker in _ROOT_MARKERS):
            return parent
    return None


def _find_root(start: Path) -> Path:
    """Locate the repo root, resolving it at runtime rather than from install path.

    Order of resolution:

    1. ``$SPATIALBRAIN_ROOT`` if set — an explicit override.
    2. Marker search upward from the **current working directory** — this is what
       makes it correct when the package is baked into a read-only container (an
       Apptainer SIF): ``start`` then points inside the image, but the notebook's
       cwd is the real repo, so ``FilePaths.DATA`` lands in the writable ``data/``.
    3. Marker search upward from this module (``start``) — editable/dev installs.
    4. Fallback to the fixed ``src/<package>/`` layout (three levels up).
    """
    override = os.environ.get("SPATIALBRAIN_ROOT")
    if override:
        return Path(override).expanduser().resolve()
    return _search_up(Path.cwd()) or _search_up(start) or start.parents[2]


@dataclass(frozen=True)
class DatasetPaths:
    """Standard subfolders for a single dataset (``data/<name>/``)."""

    root: Path

    @property
    def raw(self) -> Path:
        """Original, unmodified input data."""
        return self.root / "raw"

    @property
    def processed(self) -> Path:
        """Preprocessed / intermediate data."""
        return self.root / "processed"

    @property
    def resources(self) -> Path:
        """Reference data, gene sets, annotations."""
        return self.root / "resources"

    @property
    def results(self) -> Path:
        """Analysis outputs (tables, exported objects)."""
        return self.root / "results"

    def create(self) -> DatasetPaths:
        """Create all standard subfolders (idempotent). Returns ``self``."""
        for path in (self.raw, self.processed, self.resources, self.results):
            path.mkdir(parents=True, exist_ok=True)
        return self


class FilePaths:
    """Project-wide paths for notebooks and scripts."""

    ROOT = _find_root(Path(__file__).resolve())

    DATA = ROOT / "data"
    FIGURES = ROOT / "figures"

    # The bundled example dataset; customize / add your own via `dataset()`.
    EXAMPLE_DATASET = DATA / "example_dataset"

    @classmethod
    def dataset(cls, name: str) -> DatasetPaths:
        """Return the standard raw/processed/resources/results paths for a dataset.

        Examples
        --------
        >>> paths = FilePaths.dataset("pbmc3k").create()
        >>> paths.processed / "adata.h5ad"  # doctest: +SKIP
        """
        return DatasetPaths(cls.DATA / name)
