import pytest

from olympus_worker.metrics import (
    ClipProblem,
    Track,
    follow,
    heatmap,
    on_side,
    report,
)
from olympus_worker.pose import feet_from
import numpy as np


def walk(side="near", start=(3.0, 10.0), speed=2.0, seconds=10, hz=10):
    """Walking along x and back, at a steady speed."""
    t = Track()
    for i in range(seconds * hz):
        time = i / hz
        phase = (speed * time) % 8
        x = 1 + (phase if phase < 4 else 8 - phase)
        follow(t, time, [(x, start[1])], side)
    return t


def test_a_steady_walk_measures_about_right():
    r = report(walk())
    # Smoothing reads about 10% low on a path that keeps turning. Real clips
    # decide whether that needs correcting.
    assert r["distance_m"] == pytest.approx(19.8, abs=2.2)
    assert r["avg_speed_ms"] == pytest.approx(2, abs=0.3)
    assert r["moving_seconds"] == pytest.approx(10, abs=1)


def test_a_slow_walk_still_counts():
    t = Track()
    for i in range(100):
        follow(t, i / 10, [(1 + i * 0.04, 10.0)], "near")
    assert report(t)["distance_m"] == pytest.approx(3.96, abs=0.4)


def test_quick_turns_arent_lost():
    t = Track()
    for i in range(100):
        phase = i % 20
        x = 1 + (phase if phase < 10 else 20 - phase) * 0.4
        follow(t, i / 10, [(x, 10.0)], "near")
    assert report(t)["distance_m"] == pytest.approx(39.6, abs=8)


def test_standing_still_measures_nothing():
    t = Track()
    for i in range(50):
        follow(t, i / 10, [(3.0, 10.0)], "near")
    r = report(t)
    assert r["distance_m"] == 0
    assert r["moving_seconds"] == 0


def test_jitter_isnt_counted_as_running():
    t = Track()
    for i in range(100):
        follow(t, i / 10, [(3.0 + (0.2 if i % 2 else -0.2), 10.0)], "near")
    assert report(t)["distance_m"] < 1


def test_a_jump_that_stays_is_never_faster_than_a_sprint():
    t = Track()
    for i in range(20):
        follow(t, i / 10, [(1.0, 8.0)], "near")
    follow(t, 2.0, [(5.0, 13.0)], "near")
    for i in range(21, 40):
        follow(t, i / 10, [(5.0, 13.0)], "near")
    assert report(t)["top_speed_ms"] <= 8


def test_a_one_frame_flip_isnt_counted():
    t = Track()
    for i in range(50):
        x = 5.6 if i == 25 else 3.0
        follow(t, i / 10, [(x, 10.0)], "near")
    r = report(t)
    assert r["distance_m"] == 0
    assert r["top_speed_ms"] == 0


def test_the_player_isnt_swapped_for_someone_beside_the_court():
    t = Track()
    for i in range(50):
        people = [(-0.5, 10.0)] if i == 0 else [(-0.5, 10.0), (3.0, 7.5 + i * 0.1)]
        follow(t, i / 10, people, "near")
    assert report(t)["distance_m"] == pytest.approx(4.8, abs=0.5)


def test_a_coach_beside_the_court_all_game_isnt_doubles():
    t = Track()
    for i in range(100):
        follow(t, i / 10, [(-0.5, 10.0), (3.0, 8.0 + i * 0.02)], "near")
    assert t.crowded == 0
    assert report(t)["distance_m"] == pytest.approx(2, abs=0.4)


def test_a_coach_isnt_picked_up_while_the_player_is_out_of_sight():
    t = Track()
    for i in range(30):
        follow(t, i / 10, [(3.0, 9.0)], "near")
    for i in range(30, 34):
        follow(t, i / 10, [(-0.5, 9.0)], "near")
    for i in range(34, 60):
        follow(t, i / 10, [(-0.5, 9.0), (3.0, 9.0)], "near")
    assert report(t)["distance_m"] == 0


def test_a_dropout_cant_give_an_impossible_speed():
    t = Track()
    for i in range(30):
        follow(t, i / 10, [(0.2, 8.0)], "near")
    for i in range(40, 70):
        follow(t, i / 10, [(5.9, 9.0)], "near")
    r = report(t)
    assert r["top_speed_ms"] <= 8
    assert r["distance_m"] == pytest.approx(5.8, abs=0.6)


def rally(noise, seconds=180, hz=10, top=5.0, seed=1):
    """A player moving between random spots, seen with noisy feet."""
    rng = np.random.default_rng(seed)
    spot = np.array([3.0, 10.0])
    target = spot
    speed = 3.0
    true = 0.0
    t = Track()
    for i in range(seconds * hz):
        gap = target - spot
        if np.linalg.norm(gap) < 0.1:
            target = np.array([rng.uniform(0.3, 5.8), rng.uniform(7.2, 13)])
            speed = rng.uniform(1.5, top)
            continue
        step = min(speed / hz, float(np.linalg.norm(gap)))
        spot = spot + gap / np.linalg.norm(gap) * step
        true += step
        seen = spot + rng.normal(0, noise, 2) * (1, 1.5)
        follow(t, i / hz, [tuple(seen)], "near")
    return t, true


@pytest.mark.parametrize("noise", [0.02, 0.05, 0.1, 0.15])
def test_a_noisy_rally_stays_one_player(noise):
    t, true = rally(noise, top=6.5)
    from olympus_worker.metrics import player_path

    assert len(player_path(t)) > len(t.seen) * 0.97
    r = report(t)
    assert r["top_speed_ms"] <= 8
    assert r["distance_m"] == pytest.approx(true, rel=0.3)


def test_someone_just_appearing_far_away_doesnt_join_the_path():
    t = Track()
    for i in range(50):
        people = [(3.0, 10.0)] if i != 30 else [(0.5, 7.0)]
        follow(t, i / 10, people, "near")
    assert report(t)["distance_m"] == 0


def test_a_big_step_in_a_short_gap_cant_lift_the_average_past_the_top():
    t = Track()
    follow(t, 0.0, [(1.0, 8.0)], "near")
    follow(t, 0.0995, [(2.45, 8.0)], "near")
    for i in range(2, 9):
        follow(t, i / 10, [], "near")
    r = report(t)
    assert r["avg_speed_ms"] <= r["top_speed_ms"] <= 8


def test_slow_steps_dont_inflate_the_average():
    t = Track()
    for i in range(600):
        follow(t, i / 10, [(0.5 + i * 0.008, 8.0)], "near")
    follow(t, 60.0, [(5.3, 8.0)], "near")
    follow(t, 60.1, [(5.9, 8.0)], "near")
    r = report(t)
    assert r["avg_speed_ms"] <= r["top_speed_ms"]
    assert r["distance_m"] > 4


def test_nobody_inside_the_lines_is_nobody():
    t = Track()
    for i in range(50):
        follow(t, i / 10, [(-0.5, 10.0)], "near")
    with pytest.raises(ClipProblem) as caught:
        report(t)
    assert caught.value.code == "no_player"


def test_only_the_chosen_side_is_kept():
    t = Track()
    for i in range(50):
        follow(t, i / 10, [(3.0, 10.0), (3.0 + i * 0.1, 3.0)], "near")
    assert all(y > 6.7 for _, here in t.seen for _, y in here)
    assert t.crowded == 0
    assert report(t)["distance_m"] == 0


def test_the_far_side_works_too():
    assert on_side((3, 3), "far")
    assert not on_side((3, 3), "near")
    assert on_side((3, 10), "near")
    assert not on_side((3, 10), "far")


def test_someone_off_the_court_is_ignored():
    assert not on_side((-3, 10), "near")
    assert not on_side((3, 20), "near")


def test_two_people_on_one_side_is_doubles():
    t = Track()
    for i in range(50):
        follow(t, i / 10, [(2.0, 10.0), (4.0, 10.0)], "near")
    with pytest.raises(ClipProblem) as caught:
        report(t)
    assert caught.value.code == "doubles"


def test_doubles_is_measured_against_the_time_anyone_was_seen():
    t = Track()
    for i in range(100):
        people = [] if i % 2 else [(2.0, 10.0), (4.0, 10.0)]
        follow(t, i / 10, people, "near")
    with pytest.raises(ClipProblem) as caught:
        report(t)
    assert caught.value.code == "doubles"


def test_someone_walking_past_now_and_then_isnt_doubles():
    t = Track()
    for i in range(50):
        people = [(3.0, 10.0)] + ([(6.5, 8.0)] if i % 10 == 0 else [])
        follow(t, i / 10, people, "near")
    assert report(t)["distance_m"] == 0


def test_nobody_found_says_so():
    t = Track()
    for i in range(50):
        follow(t, i / 10, [], "near")
    with pytest.raises(ClipProblem) as caught:
        report(t)
    assert caught.value.code == "no_player"


def test_the_heatmap_is_the_shape_the_database_wants():
    grid = heatmap([(3.0, 10.0)] * 10)
    assert len(grid) == 13
    assert all(len(r) == 6 for r in grid)
    assert sum(map(sum, grid)) == 100
    assert grid[9][2] == 100


def test_a_point_off_the_court_still_lands_on_the_grid():
    grid = heatmap([(-1.0, 15.0)])
    assert grid[12][0] == 100


def test_feet_come_from_confident_ankles():
    person = np.zeros((17, 2))
    person[15] = [100, 200]
    person[16] = [120, 220]
    scores = np.ones(17)
    assert feet_from(np.array([person]), np.array([scores])) == [(110.0, 210.0)]


def test_a_person_with_no_ankle_in_view_is_skipped():
    person = np.zeros((17, 2))
    scores = np.zeros(17)
    assert feet_from(np.array([person]), np.array([scores])) == []
    assert feet_from(None, None) == []
