# EventGuardAI — GRA (Grid-based Risk Analysis) Module

This module implements the **GRA (Grid-based Risk Analysis)** crowd risk assessment algorithm on top of YOLOv11/v8 person detection and ByteTrack tracking.

For full mathematical derivations, sequence diagrams, benchmarks, and examiner notes, see [GRA_ALGORITHM.md](../GRA_ALGORITHM.md).

## Quick Start
```bash
# Live Camera:
python run_gra.py --source 0 --ws ws://127.0.0.1:8765/ai

# Prerecorded Video:
python run_gra.py --source crowd.mp4 --ws ws://127.0.0.1:8765/ai

# Simulation Test:
python run_gra.py --source simulate --headless --max-frames 100

# Automated Test Suite:
python tests/test_gra.py
```
