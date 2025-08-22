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
extensionless_files = []
extension_files = []
module_stages = []

foreach line : discovery_result.stdout().strip().split('\n')
  if line != ''
    parts = line.split('=')
    if parts.length() == 2
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
            if not file_path.contains('.')
              extensionless_files += file_path
            else
              extension_files += file_path
            endif
          endforeach
        endif
      endif
    endif
  endif
endforeach

files = extensionless_files + extension_files

# Freestanding flags with modules support
freestanding_args = [
  '-ffreestanding',
  '-fno-exceptions',
  '-fno-rtti',
  '-nostdlib',
  '-fno-stack-protector',
  '-std=c++20',
  '-stdlib=libc++',
  '-fmodules',
  '-fcxx-modules'
]

# Additional module flags
module_cache_dir = meson.current_build_dir() / 'module-cache'
run_command('mkdir', '-p', module_cache_dir, check: false)

module_args = freestanding_args + [
  '-fmodules-cache-path=' + module_cache_dir,
  '-fprebuilt-module-path=' + module_cache_dir
]

# Create custom targets for extensionless files
cpp_targets = []
cppm_targets = []
cppm_target_map = {}

# First process all module files to create .cppm targets
foreach file_path : extensionless_files 
  if file_path.startswith('module/')
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

# Then process other extensionless files
foreach file_path : extensionless_files
  if not file_path.startswith('module/')
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
        module_name = fs.name(mod_file)
        
        # Create PCM file with proper module path
        pcm_command = [
          '/opt/homebrew/bin/clang++',
          '@INPUT@',
          '--precompile',
          '-std=c++20',
          '-o', '@OUTPUT@'
        ] + freestanding_args
        
        # Add prebuilt module path for later stages
        if i > 0
          pcm_command += ['-fprebuilt-module-path=' + meson.current_build_dir()]
        endif
        
        pcm_target = custom_target(module_name + '_pcm',
          input: cppm_target,
          output: module_name + '.pcm',
          command: pcm_command,
          depends: all_pcm_targets,  # Sequential across all stages
          build_by_default: true
        )
        
        # Create object file that depends on PCM
        obj_command = [
          '/opt/homebrew/bin/clang++',
          '@INPUT@',
          '-c',
          '-std=c++20',
          '-o', '@OUTPUT@'
        ] + freestanding_args
        
        # Add module path for later stages
        if i > 0
          obj_command += ['-fprebuilt-module-path=' + meson.current_build_dir()]
        endif
        
        obj_target = custom_target(module_name + '_obj',
          input: pcm_target,
          output: module_name + '.o', 
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
foreach file_path : regular_files
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
   link_args: ['-lSystem', '-e', '__start'],
   install: true,
   install_dir: 'bin')
