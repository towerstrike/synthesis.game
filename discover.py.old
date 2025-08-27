import os
import json
import shutil
import re
import sys
import platform
from pathlib import Path
from collections import defaultdict, deque

import tomllib

def load_feature_config(config_path="features.toml"):
    """Load feature configuration from TOML file"""
    if not Path(config_path).exists():
        return {"features": {}, "access_levels": {}}
    
    with open(config_path, "rb") as f:
        return tomllib.load(f)

def detect_available_features(config):
    """Auto-detect which features are available on this system"""
    available = set()
    current_platform = platform.system().lower()
    
    for name, feature in config.get("features", {}).items():
        if current_platform not in feature.get("platforms", [current_platform]):
            continue
            
        detection = feature.get("detection", {})
        if is_feature_available(detection):
            available.add(name)
    
    return available

def is_feature_available(detection_config):
    """Check if a feature is available using configured detection method"""
    if not detection_config:
        return True
        
    method = detection_config.get("method", "always")
    
    if method == "framework_exists":
        framework = detection_config.get("framework")
        if framework:
            return Path(f"/System/Library/Frameworks/{framework}.framework").exists()
    elif method == "platform_match":
        return platform.system().lower() == detection_config.get("platform", "")
    
    return True  # Default to available

def get_file_feature(file_path):
    """Extract feature from file extension (e.g., 'file.metal' -> 'metal')"""
    path = Path(file_path)
    parts = path.name.split('.')
    if len(parts) > 1:
        potential_feature = parts[-1]
        # Check if it's a known feature extension vs regular extension
        if potential_feature in ['metal', 'vulkan', 'directx', 'posix', 'darwin', 'windows', 'linux', 'avx2', 'neon']:
            return potential_feature
    return None

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
    platform_extensions = {'.posix', '.darwin', '.windows', '.macos', '.linux', '.neon', '.avx2', '.sse'}
    
    for file_path in dir_path.iterdir():
        if file_path.is_file() and not file_path.name.startswith('.'):
            rel_path = file_path.relative_to(base_path)
            
            # Check if file has platform-specific extension
            has_platform_ext = any(file_path.name.endswith(ext) for ext in platform_extensions)
            has_regular_ext = '.' in file_path.name and not has_platform_ext
            
            # Only include files that are either:
            # 1. Extensionless (universal)  
            # 2. Have platform-specific extensions
            # 3. Have regular extensions like .cpp, .h (but these go to extension_files)
            if not has_regular_ext or has_platform_ext:
                files_list.append(str(rel_path))
                
        elif file_path.is_dir() and not file_path.name.startswith('.'):
            discover_directory(file_path, base_path, files_list)
def analyze_module_dependencies(base_dir="."):
    base_path = Path(base_dir)
    module_deps = defaultdict(set)
    module_files = {}
    
    # Process both module/ and include/ directories
    module_directories = ['module', 'include']
    for dir_name in module_directories:
        module_root = base_path / dir_name
        if not module_root.exists():
            continue
            
        for module_dir in module_root.rglob('*'):
            if module_dir.is_file() and not module_dir.name.startswith('.') and '.' not in module_dir.name:
                try:
                    content = module_dir.read_text(encoding='utf-8', errors='ignore')
                    module_name = None
                    
                    # Parse export module statement to get full module name (e.g., "core.type")
                    export_match = re.search(r'export\s+module\s+([a-zA-Z_][a-zA-Z0-9_.]*)\s*;', content)
                    if export_match:
                        module_name = export_match.group(1)
                    else:
                        # Build module name from file path
                        rel_path = module_dir.relative_to(module_root)
                        if rel_path.parent.name != '.':
                            module_name = f"{rel_path.parent.name}.{rel_path.name}"
                        else:
                            module_name = rel_path.name
                    
                    module_files[module_name] = str(module_dir.relative_to(base_path))
                    
                    # Parse import statements to get dependencies (e.g., "core.type")
                    import_matches = re.findall(r'import\s+([a-zA-Z_][a-zA-Z0-9_.]*)\s*;', content)
                    for imp in import_matches:
                        module_deps[module_name].add(imp)
                        
                except Exception as e:
                    print(f"Warning: Could not analyze {module_dir}: {e}")
                    # Fallback: build name from path
                    rel_path = module_dir.relative_to(module_root)
                    if rel_path.parent.name != '.':
                        module_name = f"{rel_path.parent.name}.{rel_path.name}"
                    else:
                        module_name = rel_path.name
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
    # Load feature configuration and detect available features
    config = load_feature_config()
    available_features = detect_available_features(config)
    
    print(f"🔧 Available features: {', '.join(sorted(available_features))}", file=sys.stderr)
    
    structure = discover_structure()
    module_deps, module_files = analyze_module_dependencies()
    
    # Filter modules based on available features
    filtered_module_files = {}
    for module_name, file_path in module_files.items():
        feature = get_file_feature(file_path)
        if feature is None or feature in available_features:
            filtered_module_files[module_name] = file_path
        else:
            print(f"⏭️  Skipping {module_name} (requires {feature})", file=sys.stderr)
    
    dependency_stages = topological_sort_modules(module_deps, filtered_module_files)
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
    
    # Output module name mapping for meson
    print("# Module name mapping: file_path=module_name", file=sys.stderr)
    for module_name, file_path in filtered_module_files.items():
        print(f"# {file_path} -> {module_name}", file=sys.stderr)
    print("", file=sys.stderr)
    stage_num = 0
    for stage in dependency_stages:
        stage_files = []
        for module_name in stage:
            if module_name in filtered_module_files:
                file_path = filtered_module_files[module_name]
                stage_files.append(file_path)
        if stage_files:
            print(f"stagecxx{stage_num}={' '.join(stage_files)}\n")
            stage_num += 1
    for category, files in structure.items():
        if category != 'module' and category != 'include' and files:
            print(f"{category}={' '.join(files)}")
    
    # Output module name mapping for meson
    print("module_names_start")
    for module_name, file_path in filtered_module_files.items():
        print(f"{file_path}={module_name}")
    print("module_names_end")
    
    # Output feature information for meson
    print("features_start")
    for feature_name in sorted(available_features):
        feature_config = config.get("features", {}).get(feature_name, {})
        access_level = feature_config.get("access_level", "freestanding")
        compile_flags = feature_config.get("compile_flags", [])
        print(f"{feature_name}={access_level}:{','.join(compile_flags)}")
    print("features_end")
