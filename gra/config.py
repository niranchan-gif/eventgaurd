"""
EventGuardAI - GRA (Grid-based Risk Analysis) Configuration
Defines spatial grid naming, capacities, smoothing factors, risk weights,
thresholds, temporal confirmation, and cooldown settings.
"""

from dataclasses import dataclass, field
from typing import Dict, List, Tuple


@dataclass
class GRAConfig:
    # 3x3 Grid Definition
    # A1 A2 A3
    # B1 B2 B3
    # C1 C2 C3
    grid_rows: int = 3
    grid_cols: int = 3
    grid_names: List[List[str]] = field(
        default_factory=lambda: [
            ["A1", "A2", "A3"],
            ["B1", "B2", "B3"],
            ["C1", "C2", "C3"],
        ]
    )

    # A. Capacity Parameter K
    # Demonstration baseline capacity per grid cell.
    # Note: Demonstration value for prototype; not a validated structural limit.
    capacity_k: float = 12.0

    # B. Congestion Parameters
    # Normalized speed threshold (fraction of frame diagonal per frame) below which a person is deemed slow/stagnant.
    # In pixel space at 640x480, diagonal is 800px; 0.0035 * 800 ~ 2.8 pixels/frame.
    slow_speed_threshold_norm: float = 0.0035

    # Trajectory history window in frames for velocity calculations
    trajectory_window: int = 5

    # C. Growth Parameter
    # Detect sudden increases between current and previous frame count.

    # D. Movement Irregularity
    # Minimum tracked movement magnitude sum to compute dispersion (avoids division by zero / noise)
    min_movement_magnitude_norm: float = 0.002

    # E. Combined Risk Weights (Sum = 1.0)
    weight_density: float = 0.40
    weight_congestion: float = 0.25
    weight_growth: float = 0.20
    weight_irregularity: float = 0.15

    # Exponential Moving Average Smoothing Factor
    # R_smooth = alpha_smooth_prev * R_prev + alpha_smooth_curr * R_curr
    alpha_smooth_prev: float = 0.70
    alpha_smooth_curr: float = 0.30

    # Risk Classification Thresholds
    threshold_safe_max: float = 29.99
    threshold_low_warning_max: float = 49.99
    threshold_high_warning_max: float = 74.99
    # 75.0 - 100.0 is CRITICAL

    # Alert Temporal Confirmation
    # Number of consecutive frames a grid must sustain HIGH_WARNING or CRITICAL before firing alert
    confirmation_frames_high: int = 4
    confirmation_frames_critical: int = 3

    # Alert Cooldown (seconds)
    # Prevents repeated alert flooding for the same grid
    alert_cooldown_seconds: float = 15.0

    # Visualization Colors (BGR for OpenCV)
    color_safe: Tuple[int, int, int] = (60, 200, 70)       # Green
    color_low_warning: Tuple[int, int, int] = (30, 215, 255) # Yellow
    color_high_warning: Tuple[int, int, int] = (20, 140, 255) # Orange
    color_critical: Tuple[int, int, int] = (40, 40, 240)    # Red

    # Model and Inference Settings
    yolo_model_path: str = "yolo11n.pt"
    confidence_threshold: float = 0.35
    input_image_size: int = 640
    bytetrack_config: str = "bytetrack.yaml"


# Global default configuration instance
DEFAULT_GRA_CONFIG = GRAConfig()
