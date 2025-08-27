import argparse
import sys
import importlib
from pathlib import Path

def execute_task(name):
    """Execute a functional task from ./task/ by the name of the subdirectory"""
    try:
        module = importlib.import_module(f"task.{name}")

        if hasattr(module, name):
            func = getattr(module, name)
            print(f"Task by name \"{name}\" will be executed.")
            func()
        else:
            print(f"Task by name \"{name}\" could not be found.")
    except ImportError:
        task_path = Path(f"task/{task_name}")
        if task_path.exists():
            print(f"Task directory '{task_name}' exists but could not import task.{task_name}")
            print("Make sure the task has an __init__.py file")
        else:
            print(f"No task found: {task_name}")

def main():
    parser = argparse.ArgumentParser(description="Task runner")
    parser.add_argument('task_name', help="Name of the task in ./task/ to run.")
    args = parser.parse_args()

    execute_task(args.task_name)

if __name__ == "__main__":
    main()

