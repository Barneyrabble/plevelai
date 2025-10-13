"""Utilities for loading and applying the pixel->ground homography."""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Tuple

import numpy as np

DEFAULT_H_PATH = Path(__file__).resolve().parent / "H_img_to_ground.npy"


class HomographyNotFound(RuntimeError):
    """Raised when the expected homography calibration file is missing."""


@dataclass
class Homography:
    """Thin wrapper around a 3x3 homography matrix."""

    matrix: np.ndarray

    @classmethod
    def load(cls, path: Path | str | None = None) -> "Homography":
        p = Path(path) if path is not None else DEFAULT_H_PATH
        if not p.exists():
            raise HomographyNotFound(
                f"Homography file not found at {p}. Follow docs/CALIBRATION_GUIDE.md to create it."  # noqa: E501
            )
        data = np.load(p)
        if data.shape != (3, 3):
            raise ValueError(f"Expected 3x3 homography matrix, got shape {data.shape}")
        return cls(matrix=data.astype(float))

    def image_to_ground(self, u: float, v: float) -> Tuple[float, float]:
        """Map image coordinates (pixels) to ground XY (meters)."""
        vec = np.array([u, v, 1.0], dtype=float)
        warped = self.matrix @ vec
        if abs(warped[2]) < 1e-9:
            raise ValueError("Invalid homography result: w component close to zero")
        return warped[0] / warped[2], warped[1] / warped[2]

    def batch_image_to_ground(self, uvs: Iterable[Tuple[float, float]]) -> np.ndarray:
        pts = np.array([[u, v, 1.0] for u, v in uvs], dtype=float).T
        warped = self.matrix @ pts
        warped /= warped[2, :]
        return warped[:2, :].T


__all__ = ["Homography", "HomographyNotFound", "DEFAULT_H_PATH"]
