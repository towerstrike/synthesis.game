#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path

def main():
    if len(sys.argv) != 3:
        print("Usage: gen_compile_commands.py <build_dir> <source_dir>")
        sys.exit(1)
    
    build_dir = Path(sys.argv[1])
    source_dir = Path(sys.argv[2])
    
    # Find all extensionless module files
    module_files = []
    module_dir = source_dir / 'module'
    
    if module_dir.exists():
        for module_file in module_dir.rglob('*'):
            if module_file.is_file() and '.' not in module_file.name:
                rel_path = module_file.relative_to(source_dir)
                module_files.append(str(rel_path))
    
    # Ultra-minimal flags for ccls - test basic functionality first
    base_flags = [
        "/opt/homebrew/bin/clang++",
        "-std=c++20",
        "-I" + str(source_dir.absolute()),
        "-I" + str(source_dir.absolute() / "module"),
        "-I" + str(source_dir.absolute() / "src"),
    ]
    
    # Create compilation database entries
    entries = []
    
    # Add entry for each module file with virtual .cppm extension for ccls
    for module_file in module_files:
        # Add virtual .cppm extension so ccls recognizes as C++ module
        virtual_file = module_file 
        entry = {
            "directory": str(source_dir.absolute()),
            "command": " ".join(base_flags + ["-c", module_file]),
            "file": virtual_file
        }
        entries.append(entry)
    
    # Add src files with virtual .cpp extension for ccls
    src_dir = source_dir / 'src'
    if src_dir.exists():
        for src_file in src_dir.rglob('*'):
            if src_file.is_file() and '.' not in src_file.name:
                rel_path = src_file.relative_to(source_dir)
                # Add virtual .cpp extension so ccls recognizes as C++
                virtual_file = str(rel_path) 
                entry = {
                    "directory": str(source_dir.absolute()),
                    "command": " ".join(base_flags + ["-c", str(rel_path)]),
                    "file": virtual_file
                }
                entries.append(entry)
    
    # Write compile_commands.json
    compile_commands_file = build_dir / 'compile_commands.json'
    with open(compile_commands_file, 'w') as f:
        json.dump(entries, f, indent=2)
    
    # Create symlink in source directory
    if source_dir != build_dir:
        symlink_path = source_dir / 'compile_commands.json'
        if symlink_path.exists():
            symlink_path.unlink()
        symlink_path.symlink_to(compile_commands_file)

    
    print(f"Generated compile_commands.json with {len(entries)} entries")

if __name__ == "__main__":
    main()
