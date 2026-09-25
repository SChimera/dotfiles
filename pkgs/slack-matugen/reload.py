"""Notify only the registered patched Slack process after Matugen renders CSS."""
import json
import os
from pathlib import Path
import signal

runtime = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}'))
try:
    state = json.loads((runtime / 'slack-matugen.json').read_text())
    pid = int(state['pid'])
    # Verify process start time as well as executable to avoid PID reuse.
    proc = Path('/proc') / str(pid)
    stat = (proc / 'stat').read_text().rsplit(') ', 1)[1].split()
    if stat[19] == state['startTime'] and str((proc / 'exe').resolve()) == state['exe']:
        os.kill(pid, signal.SIGUSR2)
except (FileNotFoundError, ProcessLookupError):
    pass  # Slack is closed; it will load the latest palette on startup.
