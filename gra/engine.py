"""
EventGuardAI - GRA (Grid-based Risk Analysis) Engine
Implements spatial grid cell partitioning, metric estimation (Density, Congestion,
Growth, Movement Irregularity), EMA smoothing, temporal confirmation, and cooldown.
"""

import math
import time
import uuid
from collections import deque
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple, Any

from .config import GRAConfig, DEFAULT_GRA_CONFIG


@dataclass
class DetectionItem:
    """Represents a tracked person in a frame."""
    track_id: int
    bbox: Tuple[float, float, float, float]  # [x1, y1, x2, y2]
    confidence: float
    ground_point: Tuple[float, float] = (0.0, 0.0)  # (bottom_center_x, bottom_center_y)
    grid_name: str = ""

    def __post_init__(self):
        x1, y1, x2, y2 = self.bbox
        self.ground_point = ((x1 + x2) / 2.0, float(y2))


@dataclass
class GridCellMetrics:
    """Metrics calculated for an individual spatial grid cell."""
    name: str
    row: int
    col: int
    people_count: int = 0
    previous_count: int = 0
    tracked_ids: List[int] = field(default_factory=list)

    # Core Parameters (0 - 100)
    density: float = 0.0
    congestion: float = 0.0
    crowd_growth: float = 0.0
    movement_irregularity: float = 0.0

    # Risk Scores
    raw_risk: float = 0.0
    smoothed_risk: float = 0.0
    severity: str = "SAFE"  # SAFE, LOW_WARNING, HIGH_WARNING, CRITICAL

    # Alert Temporal State
    consecutive_warning_frames: int = 0
    last_alert_time: float = 0.0
    last_alert_severity: str = "SAFE"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "row": self.row,
            "col": self.col,
            "people_count": self.people_count,
            "density": round(self.density, 2),
            "congestion": round(self.congestion, 2),
            "crowd_growth": round(self.crowd_growth, 2),
            "movement_irregularity": round(self.movement_irregularity, 2),
            "raw_risk": round(self.raw_risk, 2),
            "smoothed_risk": round(self.smoothed_risk, 2),
            "severity": self.severity,
        }


@dataclass
class GRAResult:
    """Encapsulates the complete result of GRA processing for a single frame."""
    frame_index: int
    timestamp: str
    total_people: int
    grid_metrics: Dict[str, GridCellMetrics]
    active_alerts: List[Dict[str, Any]]
    safe_grids_count: int
    warning_grids_count: int  # LOW + HIGH
    critical_grids_count: int
    highest_risk_grid: str
    highest_risk_score: float
    highest_risk_severity: str
    detections: List[DetectionItem]


class GRAEngine:
    """
    Grid-based Risk Analysis (GRA) Engine.
    Partitions spatial camera view into a 3x3 grid, tracks individual ground trajectories,
    and calculates independent risk indicators per cell.
    """

    def __init__(self, config: GRAConfig = DEFAULT_GRA_CONFIG):
        self.config = config
        self.frame_index = 0

        # Trajectory store: track_id -> deque of (ground_x, ground_y, timestamp)
        self.trajectories: Dict[int, deque] = {}

        # 9 Grid Cells (A1..A3, B1..B3, C1..C3)
        self.cells: Dict[str, GridCellMetrics] = {}
        self._init_cells()

    def _init_cells(self):
        self.cells.clear()
        for r in range(self.config.grid_rows):
            for c in range(self.config.grid_cols):
                name = self.config.grid_names[r][c]
                self.cells[name] = GridCellMetrics(name=name, row=r, col=c)

    def reset(self):
        """Resets engine state and tracking histories."""
        self.frame_index = 0
        self.trajectories.clear()
        self._init_cells()

    def map_point_to_grid(self, x: float, y: float, frame_w: int, frame_h: int) -> Tuple[str, int, int]:
        """
        Maps a bottom-centre ground point (x, y) to its 3x3 grid coordinate.
        """
        cell_w = max(1.0, frame_w / float(self.config.grid_cols))
        cell_h = max(1.0, frame_h / float(self.config.grid_rows))

        col = int(x / cell_w)
        row = int(y / cell_h)

        # Clamp safely within valid grid boundaries
        col = max(0, min(self.config.grid_cols - 1, col))
        row = max(0, min(self.config.grid_rows - 1, row))

        grid_name = self.config.grid_names[row][col]
        return grid_name, row, col

    def _update_trajectories(self, detections: List[DetectionItem], now: float):
        """Updates FIFO trajectory queues for all active tracking IDs."""
        current_ids = set()
        for det in detections:
            tid = det.track_id
            current_ids.add(tid)
            if tid not in self.trajectories:
                self.trajectories[tid] = deque(maxlen=self.config.trajectory_window)
            self.trajectories[tid].append((det.ground_point[0], det.ground_point[1], now))

        # Evict inactive tracks that haven't been seen for 60 frames (~2s)
        # Keeps memory lightweight on 8 GB RAM machines
        inactive_ids = [tid for tid in self.trajectories if tid not in current_ids]
        if len(inactive_ids) > 150:
            for tid in inactive_ids[:100]:
                del self.trajectories[tid]

    def _calculate_velocity(self, track_id: int) -> Tuple[float, float, float]:
        """
        Calculates recent movement vector (dx, dy) and normalized speed for a tracked person.
        Returns: (dx, dy, speed_norm_per_frame)
        """
        traj = self.trajectories.get(track_id)
        if not traj or len(traj) < 2:
            return 0.0, 0.0, 0.0

        p_curr = traj[-1]
        p_prev = traj[0]
        num_frames = len(traj) - 1

        dx = (p_curr[0] - p_prev[0]) / max(1, num_frames)
        dy = (p_curr[1] - p_prev[1]) / max(1, num_frames)
        speed = math.hypot(dx, dy)
        return dx, dy, speed

    def classify_severity(self, risk_score: float) -> str:
        """Classifies risk score into severity level."""
        if risk_score <= self.config.threshold_safe_max:
            return "SAFE"
        elif risk_score <= self.config.threshold_low_warning_max:
            return "LOW_WARNING"
        elif risk_score <= self.config.threshold_high_warning_max:
            return "HIGH_WARNING"
        else:
            return "CRITICAL"

    def process_detections(
        self,
        raw_detections: List[Dict[str, Any]],
        frame_width: int,
        frame_height: int,
        timestamp: Optional[float] = None
    ) -> GRAResult:
        """
        Process a list of person detections for the current frame.
        
        Args:
            raw_detections: list of dicts with:
                - 'track_id': int
                - 'bbox': [x1, y1, x2, y2]
                - 'confidence': float
            frame_width: width in pixels
            frame_height: height in pixels
            timestamp: optional unix timestamp (time.time() if None)
            
        Returns:
            GRAResult containing all metrics, active alerts, and statistics.
        """
        now = timestamp if timestamp is not None else time.time()
        self.frame_index += 1
        frame_diag = math.hypot(frame_width, frame_height)
        if frame_diag < 1.0:
            frame_diag = 1000.0

        # Parse detections and map to grid cells
        detections: List[DetectionItem] = []
        cell_detections: Dict[str, List[DetectionItem]] = {name: [] for name in self.cells}

        for item in raw_detections:
            tid = int(item.get("track_id", -1))
            bbox = item.get("bbox", [0, 0, 0, 0])
            conf = float(item.get("confidence", 1.0))
            det = DetectionItem(track_id=tid, bbox=tuple(bbox), confidence=conf)

            grid_name, _, _ = self.map_point_to_grid(
                det.ground_point[0], det.ground_point[1], frame_width, frame_height
            )
            det.grid_name = grid_name
            detections.append(det)
            cell_detections[grid_name].append(det)

        # Update trajectory memory
        self._update_trajectories(detections, now)

        # Calculate metrics for each grid cell
        alerts: List[Dict[str, Any]] = []
        safe_count = 0
        warning_count = 0
        critical_count = 0
        highest_score = -1.0
        highest_grid_name = "A1"
        highest_severity = "SAFE"

        # Slow speed threshold in raw pixels per frame
        slow_px_thresh = self.config.slow_speed_threshold_norm * frame_diag

        for name, cell in self.cells.items():
            current_dets = cell_detections[name]
            n_curr = len(current_dets)
            n_prev = cell.people_count
            cell.previous_count = n_prev
            cell.people_count = n_curr
            cell.tracked_ids = [d.track_id for d in current_dets]

            # -------------------------------------------------------------
            # A. Crowd Density: D = min(100, (N / K) * 100)
            # -------------------------------------------------------------
            density = min(100.0, (n_curr / self.config.capacity_k) * 100.0)
            cell.density = density

            # -------------------------------------------------------------
            # B. Congestion: C = 100 * (S / N) if N > 0 else 0
            # S = count of tracked people with normalized speed below slow threshold
            # -------------------------------------------------------------
            slow_count = 0
            vectors: List[Tuple[float, float, float]] = []

            for det in current_dets:
                dx, dy, spd = self._calculate_velocity(det.track_id)
                vectors.append((dx, dy, spd))
                if spd <= slow_px_thresh:
                    slow_count += 1

            if n_curr > 0:
                congestion = 100.0 * (slow_count / float(n_curr))
            else:
                congestion = 0.0
            cell.congestion = congestion

            # -------------------------------------------------------------
            # C. Crowd Growth: G = min(100, max(0, N_curr - N_prev) / K * 100)
            # Detect sudden spikes in occupancy
            # -------------------------------------------------------------
            if self.frame_index == 1:
                growth = 0.0
            else:
                growth = min(100.0, (max(0.0, float(n_curr - n_prev)) / self.config.capacity_k) * 100.0)
            cell.crowd_growth = growth

            # -------------------------------------------------------------
            # D. Movement Irregularity: M = 100 * (1 - ||sum(v)|| / sum(||v||))
            # Directional dispersion of movement vectors
            # -------------------------------------------------------------
            if len(vectors) < 2:
                # Need at least 2 people to measure collective directional irregularity
                irregularity = 0.0
            else:
                sum_dx = sum(v[0] for v in vectors)
                sum_dy = sum(v[1] for v in vectors)
                sum_mag = sum(v[2] for v in vectors)

                # Avoid division by zero when crowd is largely stationary
                if sum_mag < (self.config.min_movement_magnitude_norm * frame_diag):
                    irregularity = 0.0
                else:
                    resultant_mag = math.hypot(sum_dx, sum_dy)
                    ratio = resultant_mag / max(1e-6, sum_mag)
                    irregularity = 100.0 * max(0.0, min(1.0, 1.0 - ratio))

            cell.movement_irregularity = irregularity

            # -------------------------------------------------------------
            # E. Combined Risk Score:
            # R = 0.40D + 0.25C + 0.20G + 0.15M
            # EMA: R_smooth = 0.70 * R_prev + 0.30 * R_curr
            # -------------------------------------------------------------
            raw_risk = (
                self.config.weight_density * density +
                self.config.weight_congestion * congestion +
                self.config.weight_growth * growth +
                self.config.weight_irregularity * irregularity
            )
            raw_risk = max(0.0, min(100.0, raw_risk))
            cell.raw_risk = raw_risk

            if self.frame_index == 1:
                smoothed_risk = raw_risk
            else:
                smoothed_risk = (
                    self.config.alpha_smooth_prev * cell.smoothed_risk +
                    self.config.alpha_smooth_curr * raw_risk
                )
            smoothed_risk = max(0.0, min(100.0, smoothed_risk))
            cell.smoothed_risk = smoothed_risk

            # Classification
            severity = self.classify_severity(smoothed_risk)
            cell.severity = severity

            # Track highest risk grid in frame
            if smoothed_risk > highest_score:
                highest_score = smoothed_risk
                highest_grid_name = name
                highest_severity = severity

            # Count categories
            if severity == "SAFE":
                safe_count += 1
                cell.consecutive_warning_frames = 0
            elif severity in ("LOW_WARNING", "HIGH_WARNING"):
                warning_count += 1
                if severity == "HIGH_WARNING":
                    cell.consecutive_warning_frames += 1
                else:
                    cell.consecutive_warning_frames = 0
            elif severity == "CRITICAL":
                critical_count += 1
                cell.consecutive_warning_frames += 1

            # -------------------------------------------------------------
            # Alert Generation: Temporal Confirmation & Cooldown
            # -------------------------------------------------------------
            req_confirm = (
                self.config.confirmation_frames_critical
                if severity == "CRITICAL"
                else self.config.confirmation_frames_high
            )

            is_confirmed = (
                severity in ("HIGH_WARNING", "CRITICAL") and
                cell.consecutive_warning_frames >= req_confirm
            )

            if is_confirmed:
                time_since_last = now - cell.last_alert_time
                cooldown_passed = time_since_last >= self.config.alert_cooldown_seconds
                severity_escalated = (
                    severity == "CRITICAL" and cell.last_alert_severity != "CRITICAL"
                )

                if cooldown_passed or severity_escalated:
                    cell.last_alert_time = now
                    cell.last_alert_severity = severity

                    alert_msg = {
                        "type": "CROWD_RISK_ALERT",
                        "alert_id": f"GRA-{uuid.uuid4().hex[:8].upper()}",
                        "source": "EventGuardAI_GRA",
                        "timestamp": datetime.now(timezone.utc).isoformat(),
                        "severity": severity,
                        "zone": name,
                        "risk_score": round(smoothed_risk, 1),
                        "metrics": {
                            "people_count": n_curr,
                            "density": round(density, 1),
                            "congestion": round(congestion, 1),
                            "crowd_growth": round(growth, 1),
                            "movement_irregularity": round(irregularity, 1),
                        },
                        "message": f"{severity}: crowd-risk condition in grid {name} (Risk: {smoothed_risk:.1f})",
                    }
                    alerts.append(alert_msg)

        iso_ts = datetime.now(timezone.utc).isoformat()
        import copy
        return GRAResult(
            frame_index=self.frame_index,
            timestamp=iso_ts,
            total_people=len(detections),
            grid_metrics={name: copy.copy(c) for name, c in self.cells.items()},
            active_alerts=alerts,
            safe_grids_count=safe_count,
            warning_grids_count=warning_count,
            critical_grids_count=critical_count,
            highest_risk_grid=highest_grid_name,
            highest_risk_score=round(max(0.0, highest_score), 1),
            highest_risk_severity=highest_severity,
            detections=detections,
        )
