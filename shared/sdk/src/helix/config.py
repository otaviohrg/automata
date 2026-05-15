"""Experiment configuration loading."""

from pathlib import Path
import yaml


def load_config(path: str | Path) -> dict:
    """
    Load a YAML experiment config.

    Usage:
        config = load_config("configs/experiment.yaml")
        n_episodes = config["n_episodes"]
    """
    with open(path) as f:
        return yaml.safe_load(f)


def save_config(config: dict, path: str | Path) -> None:
    """Save a config dict to YAML."""
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w") as f:
        yaml.dump(config, f, default_flow_style=False)
