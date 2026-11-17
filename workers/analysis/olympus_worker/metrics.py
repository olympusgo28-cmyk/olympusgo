"""Turns foot positions on the court into a report. Pure, so it's easy to test.

Court coordinates are metres: x across (0 to 6.1), y along from the far
baseline (0) to the near baseline (13.4).
"""
import math
from dataclasses import dataclass, field

import numpy as np

COURT_WIDTH = 6.1
COURT_LENGTH = 13.4
NET = COURT_LENGTH / 2

# Past this nobody is really running: a sighting that far off is someone else,
# or a tracking jump.
MAX_SPEED = 8.0
# Added to how far someone could have run, because foot positions are noisy.
JUMP_MARGIN = 0.7
# Beside the court only a step counts, so a coach isn't picked up while the
# player's feet are out of sight.
OFF_COURT_REACH = 1.5
# Movement is added up once it's this far from the last counted point, so jitter
# from the pose model cancels out and slow steps still count.
MIN_STEP = 0.15
MOVING_SPEED = 0.5
SMOOTH_SAMPLES = 3
MAX_SMOOTH_GAP = 0.35

# Someone just off the court is still playing. Any wider reaches the next court.
MARGIN_X = 1.0
MARGIN_Y = 2.0

# More than one person inside the lines on this side, this much of the time
# anyone is seen, means doubles.
DOUBLES_SHARE = 0.3
# Found less often than this, the numbers wouldn't mean anything.
MIN_TRACKED_SHARE = 0.2

HEATMAP_ROWS = 13
HEATMAP_COLUMNS = 6


class ClipProblem(Exception):
    """Something about the clip itself. The code goes back to the player."""

    def __init__(self, code):
        super().__init__(code)
        self.code = code


class OutOfTime(Exception):
    """The job's time ran out. The sweep ends it, with its one retry."""


@dataclass
class Track:
    # (time, feet) for each sample with anyone on the chosen side.
    seen: list = field(default_factory=list)
    samples: int = 0
    crowded: int = 0


def on_side(point, side):
    x, y = point
    if not -MARGIN_X <= x <= COURT_WIDTH + MARGIN_X:
        return False
    if side == "near":
        return NET <= y <= COURT_LENGTH + MARGIN_Y
    return -MARGIN_Y <= y < NET


def _inside(point):
    x, y = point
    return 0 <= x <= COURT_WIDTH and 0 <= y <= COURT_LENGTH


def follow(track, time, feet, side):
    """Adds one sampled frame. Everyone on the other side is ignored here, so
    nothing about an opponent is ever kept."""
    track.samples += 1
    here = [tuple(p) for p in feet if on_side(p, side)]
    # A coach beside the court isn't a doubles partner.
    if sum(_inside(p) for p in here) > 1:
        track.crowded += 1
    if here:
        track.seen.append((time, here))


def player_path(track):
    """Follows one person from a spot near the middle of where people were on
    court. Someone inside the lines beats someone beside them, and a sighting
    nobody could have reached is skipped, so a tracking jump doesn't count."""
    on_court = [p for _, here in track.seen for p in here if _inside(p)]
    if not on_court:
        return []
    home = tuple(np.median(on_court, axis=0))
    path = []
    for time, here in track.seen:
        inside = [p for p in here if _inside(p)]
        if not path:
            if inside:
                path.append((time, min(inside, key=lambda p: math.dist(p, home))))
            continue
        last_time, last = path[-1]
        point = min(inside or here, key=lambda p: math.dist(p, last))
        reach = JUMP_MARGIN + MAX_SPEED * (time - last_time)
        if math.dist(point, last) <= (reach if inside else min(reach, OFF_COURT_REACH)):
            path.append((time, point))
    return path


def _smooth(times, points):
    """Averages neighbouring samples, within each unbroken stretch. Across a gap
    it would spread a long move over samples a tenth of a second apart."""
    a = np.asarray(points, dtype=float)
    breaks = np.flatnonzero(np.diff(times) > MAX_SMOOTH_GAP) + 1
    return np.concatenate([_smooth_stretch(part) for part in np.split(a, breaks)])


def _smooth_stretch(a):
    if len(a) < SMOOTH_SAMPLES:
        return a
    kernel = np.ones(SMOOTH_SAMPLES) / SMOOTH_SAMPLES
    pad = SMOOTH_SAMPLES // 2
    padded = np.pad(a, ((pad, pad), (0, 0)), mode="edge")
    return np.stack([np.convolve(padded[:, i], kernel, mode="valid") for i in range(2)], axis=1)


def heatmap(points):
    grid = np.zeros((HEATMAP_ROWS, HEATMAP_COLUMNS))
    for x, y in points:
        row = min(HEATMAP_ROWS - 1, max(0, int(y / COURT_LENGTH * HEATMAP_ROWS)))
        column = min(HEATMAP_COLUMNS - 1, max(0, int(x / COURT_WIDTH * HEATMAP_COLUMNS)))
        grid[row, column] += 1
    if len(points):
        grid = grid * 100 / len(points)
    return [[int(round(v)) for v in row] for row in grid]


def report(track):
    if not track.seen:
        raise ClipProblem("no_player")
    if track.crowded / len(track.seen) > DOUBLES_SHARE:
        raise ClipProblem("doubles")
    path = player_path(track)
    if len(path) / track.samples < MIN_TRACKED_SHARE:
        raise ClipProblem("no_player")

    times = np.asarray([t for t, _ in path], dtype=float)
    points = _smooth(times, [p for _, p in path])
    distance = 0.0
    moving_distance = 0.0
    moving = 0.0
    top = 0.0
    anchor = 0
    for i in range(1, len(points)):
        gap = times[i] - times[anchor]
        step = float(np.linalg.norm(points[i] - points[anchor]))
        if step < MIN_STEP:
            continue
        speed = min(step / gap, MAX_SPEED)
        distance += step
        top = max(top, speed)
        if speed >= MOVING_SPEED:
            moving += gap
            moving_distance += speed * gap
        anchor = i
    return {
        "distance_m": round(distance, 1),
        "avg_speed_ms": round(moving_distance / moving, 2) if moving > 0 else 0.0,
        "top_speed_ms": round(top, 2),
        "moving_seconds": int(round(moving)),
        "heatmap": heatmap(points),
    }
