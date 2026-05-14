"""Shared evaluation utilities."""

import json
import time
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import Any


@dataclass
class ExperimentResult:
    """Standard result format for all portfolio experiments."""

    experiment_name: str
    timestamp: str
    metrics: dict[str, float]
    config: dict[str, Any]
    notes: str = ""

    def save(self, path: str | Path) -> None:
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as f:
            json.dump(asdict(self), f, indent=2)

    @classmethod
    def load(cls, path: str | Path) -> "ExperimentResult":
        with open(path) as f:
            return cls(**json.load(f))


def save_result(
    experiment_name: str,
    metrics: dict[str, float],
    config: dict[str, Any],
    output_dir: str = "results",
    notes: str = "",
) -> Path:
    """
    Save experiment result in standard format.

    Usage:
        result_path = save_result(
            experiment_name="vickrey_baseline",
            metrics={"mean_deviation": 0.12, "auroc": 0.87},
            config=config,
        )
    """
    timestamp = time.strftime("%Y%m%d_%H%M%S")
    result = ExperimentResult(
        experiment_name=experiment_name,
        timestamp=timestamp,
        metrics=metrics,
        config=config,
        notes=notes,
    )
    path = Path(output_dir) / f"{experiment_name}_{timestamp}.json"
    result.save(path)
    return path
