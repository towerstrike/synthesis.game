project('synthesis.game', 'cpp',
  version: '0.0.0',
  default_options: [
    'cpp_std=c++20',
    'default_library=static'
  ])

fs = import('fs')

# Find modules and src files using discover script
python = find_program('python3')

# Generate compile_commands.json for clangd
run_command(python, 'gen_compile_commands.py', meson.current_build_dir(), meson.current_source_dir(), check: false)
discovery_result = run_command(python, 'discover.py', check: true)

# Parse the output and separate by category
module_name_map = {}
extensionless_files = []
extension_files = []
module_stages = []
feature_map = {}

parsing_module_names = false
parsing_features = false
foreach line : discovery_result.stdout().strip().split('\n')
  if line == 'module_names_start'
    parsing_module_names = true
  elif line == 'module_names_end'
    parsing_module_names = false
  elif line == 'features_start'
    parsing_features = true
  elif line == 'features_end'
    parsing_features = false
  elif line != ''
    parts = line.split('=')
    if parts.length() == 2
      if parsing_module_names
        # Parse module name mapping: file_path=module_name
        file_path = parts[0]
        module_name = parts[1]
        module_name_map += {file_path: module_name}
      elif parsing_features
        # Parse feature mapping: feature_name=access_level:flags
        feature_name = parts[0]
        feature_parts = parts[1].split(':')
        access_level = feature_parts[0]
        compile_flags = feature_parts.length() > 1 ? feature_parts[1].split(',') : []
        feature_map += {feature_name: {'access_level': access_level, 'compile_flags': compile_flags}}
      else
        category = parts[0]
        file_list = parts[1].split(' ')
        
        if file_list != ['']
          if category.startswith('stage')
            # Module stage
            message('Found module stage: ' + category + ' with ' + file_list.length().to_string() + ' files')
            module_stages += [file_list]
            # Also add module files to extensionless_files for target creation
            foreach file_path : file_list
              extensionless_files += file_path
            endforeach
          else
            foreach file_path : file_list
              # Platform-specific extensions should be treated as extensionless for build
              platform_extensions = ['.posix', '.darwin', '.windows', '.macos', '.linux', '.neon', '.avx2', '.sse']
              is_platform_file = false
              
              foreach ext : platform_extensions
                if file_path.endswith(ext)
                  is_platform_file = true
                  break
                endif
              endforeach
              
              if not file_path.contains('.') or is_platform_file
                extensionless_files += file_path
              else
                extension_files += file_path
              endif
            endforeach
          endif
        endif
      endif
    endif
  endif
endforeach

files = extensionless_files + extension_files

# Feature detection will be done inline where needed

# Freestanding flags with modules support
freestanding_args = [
  '-ffreestanding',
  '-fno-exceptions',
  '-fno-rtti',
  '-nostdlib',
  '-fno-stack-protector',
  '-std=c++20',
  '-fmodules',
  '-fcxx-modules'
]

# Additional module flags
module_cache_dir = meson.current_build_dir() / 'module-cache'
run_command('mkdir', '-p', module_cache_dir, check: false)

module_args = freestanding_args + [
  '-fmodules-cache-path=' + module_cache_dir,
  '-fprebuilt-module-path=' + meson.current_build_dir()
]

# Create custom targets for extensionless files
cpp_targets = []
cppm_targets = []
cppm_target_map = {}

# First process all module files to create .cppm targets
foreach file_path : extensionless_files 
  if file_path.startswith('module/') or file_path.startswith('include/')
    basename = fs.name(file_path)
    # Replace path separators with underscores for unique output names
    safe_name = file_path.replace('/', '_').replace('\\', '_')
    
    # Module files get .cppm extension
    copy_target = custom_target(safe_name + '_cppm',
      input: files(file_path),
      output: basename + '.cppm',
      command: ['cp', '@INPUT@', '@OUTPUT@'],
      build_by_default: true
    )
    message('Creating module target for: ' + file_path)
    cppm_targets += copy_target
    cppm_target_map += {file_path: copy_target}
  endif
endforeach

# Then process other extensionless files (not modules or includes)
cpp_target_map = {}
foreach file_path : extensionless_files
  if not file_path.startswith('module/') and not file_path.startswith('include/')
    basename = fs.name(file_path)
    # Replace path separators with underscores for unique output names
    safe_name = file_path.replace('/', '_').replace('\\', '_')
    
    # Other files get .cpp extension
    copy_target = custom_target(safe_name + '_cpp',
      input: files(file_path),
      output: safe_name + '.cpp',
      command: ['cp', '@INPUT@', '@OUTPUT@'],
      build_by_default: true
    )
    message('Creating target for: ' + file_path)
    cpp_targets += copy_target
    cpp_target_map += {file_path: copy_target}
  endif
endforeach

# Separate module files from regular files
module_files = []
regular_files = []

if extension_files.length() > 0
  foreach file_path : extension_files
    if file_path.endswith('.cppm')
      module_files += files(file_path)
    else
      regular_files += files(file_path)
    endif
  endforeach
endif

# Build module stages with explicit PCM generation
module_libraries = []
all_pcm_targets = []

if module_stages.length() > 0
  foreach i : range(module_stages.length())
    stage = module_stages[i]
    stage_name = 'modules_stage_' + i.to_string()
    
    # Create PCM files for this stage first
    stage_pcm_targets = []
    stage_obj_targets = []
    
    foreach mod_file : stage
      if mod_file in cppm_target_map
        cppm_target = cppm_target_map[mod_file]
        # Use the actual module name from the discovery script
        if mod_file in module_name_map
          full_module_name = module_name_map[mod_file]
          safe_module_name = full_module_name.replace('.', '_')
        else
          # Fallback to filename if not in map
          full_module_name = fs.name(mod_file)
          safe_module_name = full_module_name
        endif
        
        # Create PCM file with proper module path
        pcm_command = [
          '/opt/homebrew/bin/clang++',
          '@INPUT@',
          '--precompile',
          '-std=c++20',
          '-o', '@OUTPUT@'
        ]
        
        # Determine compilation flags based on file feature
        file_feature = get_file_feature(mod_file)
        if file_feature != '' and file_feature in feature_map
          # Use feature-specific compilation flags
          feature_data = feature_map[file_feature]
          access_level = feature_data['access_level']
          if access_level == 'freestanding'
            pcm_command += freestanding_args
          endif
          pcm_command += feature_data['compile_flags']
        else
          # Default to freestanding for files without features
          pcm_command += freestanding_args
        endif
        
        # Add prebuilt module path for later stages
        if i > 0
          pcm_command += ['-fprebuilt-module-path=' + meson.current_build_dir()]
        endif
        
        pcm_depends = []
        if i > 0
          pcm_depends = all_pcm_targets
        endif
        
        pcm_target = custom_target(safe_module_name + '_pcm',
          input: cppm_target,
          output: full_module_name + '.pcm',
          command: pcm_command,
          depends: pcm_depends,  # Only depend on previous stages
          build_by_default: true
        )
        
        # Create object file that depends on PCM
        obj_command = [
          '/opt/homebrew/bin/clang++',
          '@INPUT@',
          '-c',
          '-std=c++20',
          '-o', '@OUTPUT@'
        ]
        
        # Use same feature-specific compilation flags as PCM
        if file_feature != '' and file_feature in feature_map
          feature_data = feature_map[file_feature]
          access_level = feature_data['access_level']
          if access_level == 'freestanding'
            obj_command += freestanding_args
          endif
          obj_command += feature_data['compile_flags']
        else
          obj_command += freestanding_args
        endif
        
        # Add module path for later stages
        if i > 0
          obj_command += ['-fprebuilt-module-path=' + meson.current_build_dir()]
        endif
        
        obj_target = custom_target(safe_module_name + '_obj',
          input: pcm_target,
          output: safe_module_name + '.o', 
          command: obj_command,
          build_by_default: true
        )
        
        stage_pcm_targets += pcm_target
        stage_obj_targets += obj_target
      endif
    endforeach
    
    all_pcm_targets += stage_pcm_targets
    
    message('Stage ' + i.to_string() + ' has ' + stage_obj_targets.length().to_string() + ' modules')
    
    if stage_obj_targets.length() > 0
      # Create library from object files
      stage_lib = static_library(stage_name,
        stage_obj_targets,
        pic: false,
        install: false
      )
      message('Created static library for ' + stage_name)
      
      module_libraries += stage_lib
    endif
  endforeach
endif

# Build src library separately 
src_libraries = []
src_files = []

# Add all src files from both extensionless and extension categories
foreach file_path : extensionless_files
  if file_path.startswith('src/')
    src_files += cpp_target_map[file_path]
  endif
endforeach

foreach file_path : extension_files
  if file_path.startswith('src/')
    src_files += files(file_path)
  endif
endforeach

if src_files.length() > 0
  src_lib = static_library('src',
    src_files,
    cpp_args: module_args,  # src can use modules
    link_with: module_libraries,  # src depends on all module stages
    pic: false,
    install: false
  )
  src_libraries += src_lib
endif

# Build final executable linking everything together
all_libraries = module_libraries + src_libraries

# Create main executable with proper module linking
main_cpp_args = freestanding_args + [
  '-fmodules',
  '-fcxx-modules',
  '-fprebuilt-module-path=' + meson.current_build_dir()
]

executable('synthesis',
   cpp_targets,  # Only extensionless -> .cpp conversions, no module or src files
   cpp_args: main_cpp_args,
   link_with: all_libraries,
   link_args: [
     '-lSystem', 
     '-e', '__start',
     '-framework', 'Metal',
     '-framework', 'MetalKit', 
     '-framework', 'CoreVideo',
     '-framework', 'QuartzCore',
     '-framework', 'Foundation',
     '-framework', 'AppKit',
     '-framework', 'Cocoa'
   ],
   install: true,
   install_dir: 'bin')
