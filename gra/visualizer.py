"""
EventGuardAI - GRA Real-time Visualization Dashboard (OpenCV)
Renders 3x3 spatial grid, bounding boxes, tracking IDs, ground points,
per-grid risk scores, severity badges, and a compact HUD statistics panel.
"""

from typing import Dict, Tuple
import cv2
import numpy as np

from .config import GRAConfig, DEFAULT_GRA_CONFIG
from .engine import GRAResult, GridCellMetrics


class GRAVisualizer:
    """
    Renders the GRA HUD and risk map on top of video frames.
    """

    def __init__(self, config: GRAConfig = DEFAULT_GRA_CONFIG):
        self.config = config
        self.font = cv2.FONT_HERSHEY_SIMPLEX

    def _get_color(self, severity: str) -> Tuple[int, int, int]:
        """Returns BGR color for a given severity level."""
        if severity == "CRITICAL":
            return self.config.color_critical
        elif severity == "HIGH_WARNING":
            return self.config.color_high_warning
        elif severity == "LOW_WARNING":
            return self.config.color_low_warning
        else:
            return self.config.color_safe

    def draw(self, frame: np.ndarray, result: GRAResult, fps: float = 0.0) -> np.ndarray:
        """
        Draws the complete GRA overlay onto the provided frame.
        Returns a modified or annotated frame.
        """
        h, w = frame.shape[:2]
        output = frame.copy()

        # -------------------------------------------------------------
        # 1. Semi-transparent Risk Color Shading for Warning/Critical Cells
        # -------------------------------------------------------------
        overlay = output.copy()
        cell_w = w / float(self.config.grid_cols)
        cell_h = h / float(self.config.grid_rows)

        for name, cell in result.grid_metrics.items():
            if cell.severity in ("LOW_WARNING", "HIGH_WARNING", "CRITICAL"):
                x1 = int(cell.col * cell_w)
                y1 = int(cell.row * cell_h)
                x2 = int((cell.col + 1) * cell_w)
                y2 = int((cell.row + 1) * cell_h)

                color = self._get_color(cell.severity)
                # Alpha depends on severity: subtle for low, stronger for critical
                alpha = 0.12 if cell.severity == "LOW_WARNING" else (0.22 if cell.severity == "HIGH_WARNING" else 0.32)
                cv2.rectangle(overlay, (x1, y1), (x2, y2), color, -1)

        cv2.addWeighted(overlay, 0.75, output, 0.25, 0, output)

        # -------------------------------------------------------------
        # 2. Draw 3x3 Grid Dividing Lines
        # -------------------------------------------------------------
        grid_line_color = (180, 180, 180)
        grid_line_thick = 1

        for c in range(1, self.config.grid_cols):
            x = int(c * cell_w)
            cv2.line(output, (x, 0), (x, h), grid_line_color, grid_line_thick, cv2.LINE_AA)

        for r in range(1, self.config.grid_rows):
            y = int(r * cell_h)
            cv2.line(output, (0, y), (w, y), grid_line_color, grid_line_thick, cv2.LINE_AA)

        # -------------------------------------------------------------
        # 3. Draw Detected Persons: Bounding Box, Tracking ID & Ground Point
        # -------------------------------------------------------------
        for det in result.detections:
            x1, y1, x2, y2 = [int(v) for v in det.bbox]
            gx, gy = int(det.ground_point[0]), int(det.ground_point[1])

            # Get parent cell severity to color bounding box
            cell = result.grid_metrics.get(det.grid_name)
            box_color = self._get_color(cell.severity if cell else "SAFE")

            # Bounding box
            cv2.rectangle(output, (x1, y1), (x2, y2), box_color, 2, cv2.LINE_AA)

            # Ground-centre point
            cv2.circle(output, (gx, gy), 4, (0, 255, 255), -1, cv2.LINE_AA)
            cv2.circle(output, (gx, gy), 6, (0, 0, 0), 1, cv2.LINE_AA)

            # Tracking ID tag
            label = f"ID:{det.track_id}"
            (lw, lh), _ = cv2.getTextSize(label, self.font, 0.45, 1)
            cv2.rectangle(output, (x1, max(0, y1 - lh - 6)), (x1 + lw + 6, max(lh + 6, y1)), (20, 20, 20), -1)
            cv2.putText(output, label, (x1 + 3, max(lh + 2, y1 - 3)), self.font, 0.45, (255, 255, 255), 1, cv2.LINE_AA)

        # -------------------------------------------------------------
        # 4. Draw Grid Cell Badges (Grid Name, Count, Risk Score, Status)
        # -------------------------------------------------------------
        for name, cell in result.grid_metrics.items():
            cell_x = int(cell.col * cell_w)
            cell_y = int(cell.row * cell_h)

            color = self._get_color(cell.severity)

            # Top-left cell header badge
            badge_x = cell_x + 8
            badge_y = cell_y + 20

            # Grid Title (e.g., A1, B2)
            cv2.putText(output, cell.name, (badge_x, badge_y), self.font, 0.65, color, 2, cv2.LINE_AA)

            # Stats text
            count_text = f"P:{cell.people_count}"
            risk_text = f"R:{cell.smoothed_risk:.1f}"
            status_text = cell.severity.replace("_WARNING", "-WARN")

            # Background pill for readability
            info_str = f"{count_text} | {risk_text} [{status_text}]"
            (tw, th), _ = cv2.getTextSize(info_str, self.font, 0.40, 1)

            pill_x1 = badge_x
            pill_y1 = badge_y + 4
            pill_x2 = badge_x + tw + 8
            pill_y2 = pill_y1 + th + 6

            cv2.rectangle(output, (pill_x1, pill_y1), (pill_x2, pill_y2), (15, 15, 15), -1)
            cv2.rectangle(output, (pill_x1, pill_y1), (pill_x2, pill_y2), color, 1)
            cv2.putText(output, info_str, (badge_x + 4, pill_y2 - 3), self.font, 0.40, (240, 240, 240), 1, cv2.LINE_AA)

        # -------------------------------------------------------------
        # 5. Top Compact HUD Statistics Panel
        # -------------------------------------------------------------
        hud_h = 36
        hud_bg = output[0:hud_h, 0:w].copy()
        cv2.rectangle(output, (0, 0), (w, hud_h), (12, 14, 20), -1)
        cv2.line(output, (0, hud_h), (w, hud_h), (50, 55, 70), 1)

        # Title & System Mode
        title = "EVENTGUARD-AI  |  GRA ENGINE (YOLOv11+ByteTrack)"
        cv2.putText(output, title, (12, 22), self.font, 0.48, (255, 255, 255), 1, cv2.LINE_AA)

        # Stats items
        fps_str = f"FPS: {fps:.1f}"
        people_str = f"People: {result.total_people}"
        grids_str = f"Grids: [Safe:{result.safe_grids_count}  Warn:{result.warning_grids_count}  Crit:{result.critical_grids_count}]"
        highest_color = self._get_color(result.highest_risk_severity)
        peak_str = f"Peak: {result.highest_risk_grid} ({result.highest_risk_score:.1f} {result.highest_risk_severity})"

        hud_text = f"{people_str}   {grids_str}   {peak_str}   {fps_str}"
        (ht_w, ht_h), _ = cv2.getTextSize(hud_text, self.font, 0.42, 1)
        start_x = max(w - ht_w - 14, int(w * 0.40))
        cv2.putText(output, hud_text, (start_x, 22), self.font, 0.42, (220, 225, 235), 1, cv2.LINE_AA)

        # -------------------------------------------------------------
        # 6. Critical Alert Banner Overlay if Active
        # -------------------------------------------------------------
        if result.critical_grids_count > 0:
            banner_y = h - 28
            cv2.rectangle(output, (0, banner_y), (w, h), (30, 30, 220), -1)
            crit_msg = f"CRITICAL CROWD RISK ALERT ACTIVE - IMMEDIATE INTERVENTION REQUIRED IN {result.highest_risk_grid}"
            (cw, ch), _ = cv2.getTextSize(crit_msg, self.font, 0.48, 1)
            cv2.putText(output, crit_msg, (max(10, (w - cw) // 2), h - 8), self.font, 0.48, (255, 255, 255), 1, cv2.LINE_AA)

        return output
