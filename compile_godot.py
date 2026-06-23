import os
from pathlib import Path

def compile_godot_files(target_folder):
    base_dir = Path(target_folder)
    
    if not base_dir.is_dir():
        print(f"Error: The directory '{target_folder}' does not exist.")
        return

    # Define output file names
    gd_output_path = base_dir / "compiled_scripts.txt"
    tscn_output_path = base_dir / "compiled_scenes.txt"
    tree_output_path = base_dir / "project_structure.txt"

    # Define ignore sets to keep compilation and tree maps clean
    ignore_dirs = {"addons", ".godot", ".import", ".git"}
    ignore_files = {"compiled_scripts.txt", "compiled_scenes.txt", "project_structure.txt"}

    # 1. Generate and write the project directory tree
    print("Mapping project structure...")
    tree_lines = [f"{base_dir.resolve().name}/"]
    tree_lines.extend(_generate_tree_lines(base_dir, ignore_dirs=ignore_dirs, ignore_files=ignore_files))
    
    with open(tree_output_path, 'w', encoding='utf-8') as tree_out:
        tree_out.write("\n".join(tree_lines) + "\n")

    # 2. Open output files in write mode and compile contents
    print("Compiling Godot files...")
    with open(gd_output_path, 'w', encoding='utf-8') as gd_out, \
         open(tscn_output_path, 'w', encoding='utf-8') as tscn_out:
        
        # Count tracked files for the final print statement
        gd_count = 0
        tscn_count = 0

        # rglob('*') recursively traverses all subdirectories and files
        for file_path in base_dir.rglob('*'):
            # Skip ignored directories
            if any(d in file_path.parts for d in ignore_dirs):
                continue
            if not file_path.is_file():
                continue
                
            # Skip the output files themselves if the script is run in the same directory
            if file_path.name in ignore_files:
                continue

            # Get the path relative to the base directory (e.g., "entities/player.gd")
            rel_path = file_path.relative_to(base_dir)

            if file_path.suffix == '.gd':
                _write_content(file_path, rel_path, gd_out)
                gd_count += 1
            elif file_path.suffix == '.tscn':
                _write_content(file_path, rel_path, tscn_out)
                tscn_count += 1

    print("\nCompilation Complete!")
    print(f"- Generated project tree   -> {tree_output_path.absolute()}")
    print(f"- Processed {gd_count} .gd files    -> {gd_output_path.absolute()}")
    print(f"- Processed {tscn_count} .tscn files  -> {tscn_output_path.absolute()}")


def _generate_tree_lines(dir_path, prefix="", ignore_dirs=None, ignore_files=None):
    """Recursively builds text tree lines, sorting directories before files."""
    lines = []
    try:
        # Sort items: Directories first, then files (alphabetically)
        items = sorted(list(dir_path.iterdir()), key=lambda x: (not x.is_dir(), x.name.lower()))
    except Exception:
        return lines

    # Filter out ignored items
    filtered_items = []
    for item in items:
        if item.is_dir() and item.name in ignore_dirs:
            continue
        if item.is_file() and item.name in ignore_files:
            continue
        filtered_items.append(item)

    count = len(filtered_items)
    for i, item in enumerate(filtered_items):
        is_last = (i == count - 1)
        connector = "└── " if is_last else "├── "
        
        lines.append(f"{prefix}{connector}{item.name}")
        
        if item.is_dir():
            # Adjust spacing prefix for nested items
            next_prefix = prefix + ("    " if is_last else "│   ")
            lines.extend(_generate_tree_lines(item, next_prefix, ignore_dirs, ignore_files))
            
    return lines


def _write_content(file_path, rel_path, out_file):
    try:
        # Read the Godot file
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Write the separator using the relative path, followed by the content
        out_file.write(f"===== [{rel_path}] =====\n")
        out_file.write(content)
        out_file.write("\n\n") # Add spacing between files
        
    except UnicodeDecodeError:
        print(f"Warning: Skipped '{rel_path}' - Unable to decode as UTF-8 text.")
    except Exception as e:
        print(f"Error reading '{rel_path}': {e}")


if __name__ == "__main__":
    # By default, this scans the directory the script is located in.
    # Change "./" to your specific Godot folder path if needed.
    project_folder = "./" 
    
    compile_godot_files(project_folder)