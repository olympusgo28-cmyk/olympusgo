import importlib.util
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).parent.parent


def test_ultralytics_isnt_installed():
    assert importlib.util.find_spec("ultralytics") is None
    installed = subprocess.run([sys.executable, "-m", "pip", "freeze"], capture_output=True, text=True).stdout
    assert "ultralytics" not in installed.lower()


def test_ultralytics_isnt_in_the_requirements():
    assert "ultralytics" not in (ROOT / "requirements.txt").read_text().lower()


def test_no_code_here_imports_it():
    for path in (ROOT / "olympus_worker").rglob("*.py"):
        text = path.read_text()
        assert "import ultralytics" not in text and "from ultralytics" not in text, path


def test_torch_isnt_needed():
    assert importlib.util.find_spec("torch") is None


def test_the_reused_code_keeps_its_licence():
    assert "Apache License" in (ROOT / "olympus_worker/vendor/good_badminton/LICENSE").read_text()
    assert "Good-Badminton" in (ROOT / "NOTICE").read_text()
