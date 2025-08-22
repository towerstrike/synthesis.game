import os
import json
import shutil
import re
import sys
from pathlib import Path
from collections import defaultdict, deque
def discover_structure(base_dir="."):
    base_path = Path(base_dir)
    structure = {}
    source_roots = ['module', 'src', 'include', 'test', 'example']
    for root in source_roots:
        root_path = base_path / root
        if root_path.exists() and root_path.is_dir():
            if root == 'modules':
                for subdir in root_path.iterdir():
                    if subdir.is_dir() and not subdir.name.startswith('.'):
                        files_list = []
                        discover_directory(subdir, base_path, files_list)
                        if files_list:
                            structure[subdir.name] = files_list
            else:
                files_list = []
                discover_directory(root_path, base_path, files_list)
                if files_list:
                    structure[root] = files_list
    return structure
def discover_directory(dir_path, base_path, files_list):
    for file_path in dir_path.iterdir():
        if file_path.is_file() and not file_path.name.startswith('.'):
            rel_path = file_path.relative_to(base_path)
            if 'module' in rel_path.parts and '.' not in file_path.name:
                files_list.append(str(rel_path))
            else:
                files_list.append(str(rel_path))
        elif file_path.is_dir() and not file_path.name.startswith('.'):
            discover_directory(file_path, base_path, files_list)
def analyze_module_dependencies(base_dir="."):
    base_path = Path(base_dir)
    module_deps = defaultdict(set)
    module_files = {}
    for module_dir in (base_path / 'module').rglob('*'):
        if module_dir.is_file() and not module_dir.name.startswith('.') and '.' not in module_dir.name:
            try:
                content = module_dir.read_text(encoding='utf-8', errors='ignore')
                module_name = None
                export_match = re.search(r'export\s+module\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*;', content)
                if export_match:
                    module_name = export_match.group(1)
                else:
                    module_name = module_dir.name
                module_files[module_name] = str(module_dir.relative_to(base_path))
                import_matches = re.findall(r'import\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*;', content)
                for imp in import_matches:
                    module_deps[module_name].add(imp)
            except Exception as e:
                print(f"Warning: Could not analyze {module_dir}: {e}")
                module_name = module_dir.name
                module_files[module_name] = str(module_dir.relative_to(base_path))
    return module_deps, module_files
def topological_sort_modules(module_deps, module_files):
    graph = defaultdict(set)
    in_degree = defaultdict(int)
    all_modules = set(module_files.keys())
    for module, deps in module_deps.items():
        for dep in deps:
            if dep in all_modules and dep != module:
                graph[dep].add(module)
                in_degree[module] += 1
    for module in all_modules:
        if module not in in_degree:
            in_degree[module] = 0
    stages = []
    remaining_modules = set(all_modules)
    temp_in_degree = in_degree.copy()
    while remaining_modules:
        current_stage = [module for module in remaining_modules if temp_in_degree[module] == 0]
        if not current_stage:
            print("Warning: Circular dependencies detected, adding remaining modules", file=sys.stderr)
            current_stage = list(remaining_modules)
        stages.append(current_stage)
        remaining_modules -= set(current_stage)
        for module in current_stage:
            for neighbor in graph[module]:
                if neighbor in remaining_modules:
                    temp_in_degree[neighbor] -= 1
    return stages
if __name__ == '__main__':
    structure = discover_structure()
    module_deps, module_files = analyze_module_dependencies()
    dependency_stages = topological_sort_modules(module_deps, module_files)
    print("🔍 Module Dependency Analysis", file=sys.stderr)
    print("━" * 50, file=sys.stderr)
    all_modules = []
    for stage in dependency_stages:
        all_modules.extend(stage)
    for module_name in all_modules:
        deps = module_deps.get(module_name, set())
        if deps:
            deps_str = " ← " + ", ".join(sorted(deps))
            print(f"📦 {module_name}{deps_str}", file=sys.stderr)
        else:
            print(f"📦 {module_name} (no dependencies)", file=sys.stderr)
    print(f"\n🚀 Build Stages (Parallel within each stage)", file=sys.stderr)
    print("━" * 45, file=sys.stderr)
    for i, stage in enumerate(dependency_stages, 1):
        print(f"Stage {i}: {len(stage)} modules in parallel", file=sys.stderr)
        for module_name in sorted(stage):
            print(f"  ├─ {module_name}", file=sys.stderr)
        if i < len(dependency_stages):
            print(f"  ⬇️  (wait for stage {i} to complete)", file=sys.stderr)
    print("", file=sys.stderr)
    stage_num = 0
    for stage in dependency_stages:
        stage_files = []
        for module_name in stage:
            if module_name in module_files:
                file_path = module_files[module_name]
                stage_files.append(file_path)
        if stage_files:
            print(f"stagecxx{stage_num}={' '.join(stage_files)}\n")
            stage_num += 1
    for category, files in structure.items():
        if category != 'module' and files:
            print(f"{category}={' '.join(files)}")
