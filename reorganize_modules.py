#!/usr/bin/env python3
"""
Module Reorganization Script for synthesis.game
Moves files from flat structure to hierarchical module organization
"""

import os
import shutil
import sys
from pathlib import Path

# Module reorganization mapping: current_path -> (new_path, new_module_name, action)
# Actions: 'move', 'delete', 'keep_as_core'
MODULE_MAPPING = {
    # Core foundation modules (keep in core/)
    'module/core/type': ('module/core/type', 'core.type', 'keep_as_core'),
    'module/core/trait': ('module/core/trait', 'core.trait', 'keep_as_core'),
    'module/core/platform': ('module/core/platform', 'core.platform', 'keep_as_core'),
    'module/core/result': ('module/core/result', 'core.result', 'keep_as_core'),
    'module/core/optional': ('module/core/optional', 'core.optional', 'keep_as_core'),
    'module/core/variant': ('module/core/variant', 'core.variant', 'keep_as_core'),
    'module/core/error': ('module/core/error', 'core.error', 'keep_as_core'),
    'module/core/null': ('module/core/null', 'core.null', 'keep_as_core'),

    # Memory management modules
    'module/core/alloc': ('module/memory/alloc', 'memory.alloc', 'move'),
    'module/core/box': ('module/memory/box', 'memory.box', 'move'),
    'module/core/rc': ('module/memory/rc', 'memory.rc', 'move'),

    # Collection modules
    'module/core/span': ('module/collection/span', 'collection.span', 'move'),
    'module/core/slice': ('module/collection/slice', 'collection.slice', 'move'),
    'module/core/string': ('module/collection/string', 'collection.string', 'move'),
    'module/core/str': ('module/collection/str', 'collection.str', 'move'),
    'module/core/list': ('module/collection/list', 'collection.list', 'move'),
    'module/core/map': ('module/collection/map', 'collection.map', 'move'),
    'module/core/set': ('module/collection/set', 'collection.set', 'move'),
    'module/core/deque': ('module/collection/deque', 'collection.deque', 'move'),
    'module/core/ring': ('module/collection/ring', 'collection.ring', 'move'),
    'module/core/buffer': ('module/collection/buffer', 'collection.buffer', 'move'),
    'module/core/pair': ('module/collection/pair', 'collection.pair', 'move'),

    # I/O and networking modules  
    'module/core/io': ('module/io/io', 'io.io', 'move'),
    'module/core/file': ('module/io/file', 'io.file', 'move'),
    'module/core/path': ('module/io/path', 'io.path', 'move'),
    'module/core/fs': ('module/io/fs', 'io.fs', 'move'),
    'module/core/stream': ('module/io/stream', 'io.stream', 'move'),
    'module/core/format': ('module/io/format', 'io.format', 'move'),
    'module/core/print': ('module/io/print', 'io.print', 'move'),
    'module/core/console': ('module/io/console', 'io.console', 'move'),
    'module/core/net': ('module/io/net', 'io.net', 'move'),
    'module/core/tcp': ('module/io/tcp', 'io.tcp', 'move'),
    'module/core/udp': ('module/io/udp', 'io.udp', 'move'),
    'module/core/binary': ('module/io/binary', 'io.binary', 'move'),

    # Math and algorithms
    'module/core/math': ('module/math/math', 'math.math', 'move'),
    'module/core/algorithm': ('module/math/algorithm', 'math.algorithm', 'move'),
    'module/core/compare': ('module/math/compare', 'math.compare', 'move'),
    'module/core/hash': ('module/math/hash', 'math.hash', 'move'),
    'module/core/random': ('module/math/random', 'math.random', 'move'),
    'module/core/limit': ('module/math/limit', 'math.limit', 'move'),

    # Task execution and synchronization
    'module/core/thread': ('module/task/thread', 'task.thread', 'move'),
    'module/core/atomic': ('module/sync/atomic', 'sync.atomic', 'move'),

    # Algorithm and iteration
    'module/core/iterator': ('module/algorithm/iterator', 'algorithm.iterator', 'move'),
    'module/core/function': ('module/algorithm/function', 'algorithm.function', 'move'),

    # Time and system utilities
    'module/core/time': ('module/system/time', 'system.time', 'move'),
    'module/core/semantic': ('module/system/semantic', 'system.semantic', 'move'),
}

# Source file mappings: current_src -> new_src
SRC_MAPPING = {
    'src/core/alloc.posix': 'src/memory/alloc.posix',
    'src/core/box': 'src/memory/box', 
    'src/core/variant': 'src/core/variant',
    'src/core/print.posix': 'src/io/print.posix',
    'src/core/math.fixed.neon': 'src/math/simd.neon',
    'src/core/metal': 'src/graphic/metal.macos',
}

def create_directories():
    """Create the new hierarchical directory structure"""
    directories = [
        'module/core',
        'module/memory', 
        'module/collection',
        'module/io',
        'module/math',
        'module/task',
        'module/sync',
        'module/algorithm',
        'module/system',
        'module/graphic',
        'module/voxel',
        'module/physics',
        'module/compute',
        'module/spatial',
        'module/audio',
        'src/core',
        'src/memory',
        'src/collection', 
        'src/io',
        'src/math',
        'src/task',
        'src/sync',
        'src/algorithm',
        'src/system',
        'src/graphic',
        'src/voxel',
        'src/physics',
        'src/compute',
        'src/spatial',
        'src/audio',
    ]
    
    for directory in directories:
        Path(directory).mkdir(parents=True, exist_ok=True)
        print(f"✅ Created directory: {directory}")

def backup_current_structure():
    """Create backup of current structure"""
    if Path('module_backup').exists():
        shutil.rmtree('module_backup')
    if Path('src_backup').exists():
        shutil.rmtree('src_backup')
        
    shutil.copytree('module', 'module_backup')
    shutil.copytree('src', 'src_backup')
    print("✅ Created backup: module_backup/ and src_backup/")

def update_module_export(file_path, new_module_name):
    """Update the export module statement in a file"""
    if not Path(file_path).exists():
        print(f"⚠️  File not found: {file_path}")
        return
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Replace the export module line
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if line.strip().startswith('export module '):
                lines[i] = f'export module {new_module_name};'
                break
        
        with open(file_path, 'w') as f:
            f.write('\n'.join(lines))
            
        print(f"✅ Updated export: {file_path} -> {new_module_name}")
        
    except Exception as e:
        print(f"❌ Error updating {file_path}: {e}")

def update_import_statements():
    """Update import statements throughout the codebase"""
    import_updates = {
        'import result;': 'import core.result;',
        'import variant;': 'import core.variant;',
        'import optional;': 'import core.optional;',
        'import error;': 'import core.error;',
        'import null;': 'import core.null;',
        'import type;': 'import core.type;',
        'import trait;': 'import core.trait;',
        'import platform;': 'import core.platform;',
        'import alloc;': 'import memory.alloc;',
        'import box;': 'import memory.box;',
        'import rc;': 'import memory.rc;',
        # Add more as needed
    }
    
    # Update all module files
    for root, dirs, files in os.walk('module'):
        for file in files:
            if not file.startswith('.'):  # Skip hidden files
                file_path = Path(root) / file
                try:
                    with open(file_path, 'r') as f:
                        content = f.read()
                    
                    updated = False
                    for old_import, new_import in import_updates.items():
                        if old_import in content:
                            content = content.replace(old_import, new_import)
                            updated = True
                    
                    if updated:
                        with open(file_path, 'w') as f:
                            f.write(content)
                        print(f"✅ Updated imports: {file_path}")
                        
                except Exception as e:
                    print(f"⚠️  Error updating imports in {file_path}: {e}")

def reorganize_modules():
    """Move module files to their new hierarchical locations"""
    for current_path, (new_path, new_module_name, action) in MODULE_MAPPING.items():
        if not Path(current_path).exists():
            print(f"⚠️  Module not found: {current_path}")
            continue
            
        if action == 'delete':
            os.remove(current_path)
            print(f"🗑️  Deleted: {current_path}")
            
        elif action == 'keep_as_core':
            # Just update the export statement, don't move
            update_module_export(current_path, new_module_name)
            
        elif action == 'move':
            # Move file to new location
            Path(new_path).parent.mkdir(parents=True, exist_ok=True)
            shutil.move(current_path, new_path)
            update_module_export(new_path, new_module_name)
            print(f"📦 Moved: {current_path} -> {new_path} (module: {new_module_name})")

def reorganize_src_files():
    """Move src files to their new hierarchical locations"""
    for current_src, new_src in SRC_MAPPING.items():
        if not Path(current_src).exists():
            print(f"⚠️  Source file not found: {current_src}")
            continue
            
        # Create destination directory
        Path(new_src).parent.mkdir(parents=True, exist_ok=True)
        
        # Move file
        shutil.move(current_src, new_src)
        print(f"📄 Moved source: {current_src} -> {new_src}")

def clean_empty_directories():
    """Remove empty directories after reorganization"""
    for root, dirs, files in os.walk('module', topdown=False):
        for directory in dirs:
            dir_path = Path(root) / directory
            if dir_path.exists() and not any(dir_path.iterdir()):
                dir_path.rmdir()
                print(f"🧹 Removed empty directory: {dir_path}")
    
    for root, dirs, files in os.walk('src', topdown=False):
        for directory in dirs:
            dir_path = Path(root) / directory
            if dir_path.exists() and not any(dir_path.iterdir()):
                dir_path.rmdir()
                print(f"🧹 Removed empty directory: {dir_path}")

def main():
    """Main reorganization process"""
    if len(sys.argv) > 1 and sys.argv[1] == '--dry-run':
        print("🔍 DRY RUN MODE - No files will be moved")
        for current_path, (new_path, new_module_name, action) in MODULE_MAPPING.items():
            print(f"Would {action}: {current_path} -> {new_path} ({new_module_name})")
        return
    
    print("🚀 Starting module reorganization for synthesis.game")
    print("⚠️  This will restructure your entire module system!")
    
    response = input("Continue? (yes/no): ")
    if response.lower() not in ['yes', 'y']:
        print("❌ Aborted")
        return
    
    try:
        print("\n1️⃣ Creating backup...")
        backup_current_structure()
        
        print("\n2️⃣ Creating new directory structure...")
        create_directories()
        
        print("\n3️⃣ Reorganizing module files...")
        reorganize_modules()
        
        print("\n4️⃣ Reorganizing source files...")
        reorganize_src_files()
        
        print("\n5️⃣ Updating import statements...")
        update_import_statements()
        
        print("\n6️⃣ Cleaning up empty directories...")
        clean_empty_directories()
        
        print("\n✅ Module reorganization complete!")
        print("\n📂 New structure:")
        print("   module/core/        - Core foundation types")
        print("   module/memory/      - Memory management") 
        print("   module/collection/  - Data structures")
        print("   module/io/          - I/O and networking")
        print("   module/math/        - Math and algorithms")
        print("   module/threading/   - Concurrency")
        print("   module/algorithm/   - Algorithms and iteration")
        print("   module/system/      - System utilities")
        print("\n💾 Backup created: module_backup/ and src_backup/")
        print("\n🔧 Next steps:")
        print("   1. Update discover.py to handle hierarchical modules")
        print("   2. Update meson.build for new module structure")
        print("   3. Test build: ./build.sh")
        
    except Exception as e:
        print(f"❌ Error during reorganization: {e}")
        print("💾 Restore from backup if needed:")
        print("   rm -rf module src")
        print("   mv module_backup module")
        print("   mv src_backup src")

if __name__ == '__main__':
    main()