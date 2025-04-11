import subprocess
import os
import signal
from flask import Flask

app = Flask(__name__)
process = None

@app.route('/start_script', methods=['GET'])
def start_script():
    global process
    if process is None:
        process = subprocess.Popen(["python", "worker.py"])
        return "Worker script started"
    return "Script is already running"

@app.route('/stop_script', methods=['GET'])
def stop_script():
    global process
    if process:
        os.kill(process.pid, signal.SIGTERM)
        process = None
        return "Script stopped"
    return "No script is running"