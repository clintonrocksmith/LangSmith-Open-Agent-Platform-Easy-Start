"""
File Operations Tools for MCP Server
Provides comprehensive file system operations.
"""

import os
import shutil
import glob
import json
from pathlib import Path
from typing import Any, Dict, List, Optional
import mimetypes

from pydantic import BaseModel, Field

# Pydantic models for tool parameters
class ReadFileParams(BaseModel):
    file_path: str = Field(description="Path to the file to read")
    encoding: str = Field(default="utf-8", description="File encoding")

class WriteFileParams(BaseModel):
    file_path: str = Field(description="Path to the file to write")
    content: str = Field(description="Content to write to the file")
    encoding: str = Field(default="utf-8", description="File encoding")
    append: bool = Field(default=False, description="Whether to append to the file")

class SearchFilesParams(BaseModel):
    directory: str = Field(description="Directory to search in")
    pattern: str = Field(description="Search pattern (supports wildcards)")
    content_search: Optional[str] = Field(default=None, description="Search for text within files")
    recursive: bool = Field(default=True, description="Search recursively in subdirectories")

class ListDirectoryParams(BaseModel):
    directory: str = Field(description="Directory to list")
    show_hidden: bool = Field(default=False, description="Show hidden files")
    detailed: bool = Field(default=False, description="Show detailed file information")

class DeleteFileParams(BaseModel):
    file_path: str = Field(description="Path to the file or directory to delete")
    recursive: bool = Field(default=False, description="Delete directories recursively")

class CopyFileParams(BaseModel):
    source: str = Field(description="Source file or directory path")
    destination: str = Field(description="Destination path")
    recursive: bool = Field(default=False, description="Copy directories recursively")

class CreateDirectoryParams(BaseModel):
    directory: str = Field(description="Directory path to create")
    parents: bool = Field(default=True, description="Create parent directories if they don't exist")

class GetFileInfoParams(BaseModel):
    file_path: str = Field(description="Path to the file to get information about")

def register_file_tools(mcp):
    """Register all file operation tools with the MCP server."""

    @mcp.tool(description="Read the contents of a file")
    def read_file(file_path: str, encoding: str = "utf-8") -> str:
        """Read the contents of a file."""
        try:
            file_path_obj = Path(file_path)
            if not file_path_obj.exists():
                return f"Error: File '{file_path}' does not exist."
            
            if file_path_obj.is_dir():
                return f"Error: '{file_path}' is a directory, not a file."
            
            with open(file_path_obj, 'r', encoding=encoding) as f:
                content = f.read()
            
            return f"File: {file_path}\nSize: {file_path_obj.stat().st_size} bytes\n\n{content}"
        except Exception as e:
            return f"Error reading file: {str(e)}"

    @mcp.tool(description="Write content to a file")
    def write_file(file_path: str, content: str, encoding: str = "utf-8", append: bool = False) -> str:
        """Write content to a file."""
        try:
            file_path_obj = Path(file_path)
            
            # Create parent directories if they don't exist
            file_path_obj.parent.mkdir(parents=True, exist_ok=True)
            
            mode = 'a' if append else 'w'
            with open(file_path_obj, mode, encoding=encoding) as f:
                f.write(content)
            
            action = "appended to" if append else "written to"
            return f"Successfully {action} file: {file_path}"
        except Exception as e:
            return f"Error writing file: {str(e)}"

    @mcp.tool(description="Search for files by pattern and optionally by content")
    def search_files(directory: str, pattern: str, content_search: Optional[str] = None, recursive: bool = True) -> str:
        """Search for files by pattern and optionally by content."""
        try:
            directory_obj = Path(directory)
            if not directory_obj.exists():
                return f"Error: Directory '{directory}' does not exist."
            
            # Search by file pattern
            if recursive:
                full_pattern = f"**/{pattern}"
            else:
                full_pattern = pattern
            
            files = list(directory_obj.glob(full_pattern))
            
            results = []
            
            # If content search is specified, filter files by content
            if content_search:
                content_matches = []
                for file_path in files:
                    if file_path.is_file():
                        try:
                            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                                file_content = f.read()
                                if content_search.lower() in file_content.lower():
                                    content_matches.append(file_path)
                        except:
                            continue
                files = content_matches
            
            if files:
                results.append(f"Found {len(files)} files matching criteria:")
                for file_path in files[:20]:  # Limit to first 20 results
                    if file_path.is_file():
                        size = file_path.stat().st_size
                        results.append(f"  📄 {file_path} ({size} bytes)")
                    else:
                        results.append(f"  📁 {file_path}/")
                
                if len(files) > 20:
                    results.append(f"  ... and {len(files) - 20} more files")
            else:
                results.append("No files found matching the criteria.")
            
            return "\n".join(results)
        except Exception as e:
            return f"Error searching files: {str(e)}"

    @mcp.tool(description="List contents of a directory")
    def list_directory(directory: str, show_hidden: bool = False, detailed: bool = False) -> str:
        """List contents of a directory."""
        try:
            directory_obj = Path(directory)
            if not directory_obj.exists():
                return f"Error: Directory '{directory}' does not exist."
            
            if not directory_obj.is_dir():
                return f"Error: '{directory}' is not a directory."
            
            items = []
            for item in directory_obj.iterdir():
                if not show_hidden and item.name.startswith('.'):
                    continue
                
                if detailed:
                    stat = item.stat()
                    size = stat.st_size
                    modified = stat.st_mtime
                    
                    if item.is_dir():
                        items.append(f"📁 {item.name}/ (modified: {modified})")
                    else:
                        mime_type = mimetypes.guess_type(item.name)[0] or "unknown"
                        items.append(f"📄 {item.name} ({size} bytes, {mime_type}, modified: {modified})")
                else:
                    if item.is_dir():
                        items.append(f"📁 {item.name}/")
                    else:
                        items.append(f"📄 {item.name}")
            
            if items:
                result = f"Contents of {directory}:\n" + "\n".join(sorted(items))
            else:
                result = f"Directory {directory} is empty."
            
            return result
        except Exception as e:
            return f"Error listing directory: {str(e)}"

    @mcp.tool(description="Delete a file or directory")
    def delete_file(file_path: str, recursive: bool = False) -> str:
        """Delete a file or directory."""
        try:
            file_path_obj = Path(file_path)
            if not file_path_obj.exists():
                return f"Error: '{file_path}' does not exist."
            
            if file_path_obj.is_dir():
                if recursive:
                    shutil.rmtree(file_path_obj)
                    return f"Successfully deleted directory: {file_path}"
                else:
                    if any(file_path_obj.iterdir()):
                        return f"Error: Directory '{file_path}' is not empty. Use recursive=true to delete."
                    file_path_obj.rmdir()
                    return f"Successfully deleted empty directory: {file_path}"
            else:
                file_path_obj.unlink()
                return f"Successfully deleted file: {file_path}"
        except Exception as e:
            return f"Error deleting: {str(e)}"

    @mcp.tool(description="Copy a file or directory")
    def copy_file(source: str, destination: str, recursive: bool = False) -> str:
        """Copy a file or directory."""
        try:
            source_obj = Path(source)
            destination_obj = Path(destination)
            
            if not source_obj.exists():
                return f"Error: Source '{source}' does not exist."
            
            # Create parent directories for destination
            destination_obj.parent.mkdir(parents=True, exist_ok=True)
            
            if source_obj.is_dir():
                if recursive:
                    shutil.copytree(source_obj, destination_obj, dirs_exist_ok=True)
                    return f"Successfully copied directory: {source} → {destination}"
                else:
                    return f"Error: Source is a directory. Use recursive=true to copy directories."
            else:
                shutil.copy2(source_obj, destination_obj)
                return f"Successfully copied file: {source} → {destination}"
        except Exception as e:
            return f"Error copying: {str(e)}"

    @mcp.tool(description="Create a directory")
    def create_directory(directory: str, parents: bool = True) -> str:
        """Create a directory."""
        try:
            directory_obj = Path(directory)
            directory_obj.mkdir(parents=parents, exist_ok=True)
            return f"Successfully created directory: {directory}"
        except Exception as e:
            return f"Error creating directory: {str(e)}"

    @mcp.tool(description="Get detailed information about a file or directory")
    def get_file_info(file_path: str) -> str:
        """Get detailed information about a file or directory."""
        try:
            file_path_obj = Path(file_path)
            if not file_path_obj.exists():
                return f"Error: '{file_path}' does not exist."
            
            stat = file_path_obj.stat()
            info = [
                f"Path: {file_path_obj.absolute()}",
                f"Name: {file_path_obj.name}",
                f"Type: {'Directory' if file_path_obj.is_dir() else 'File'}",
                f"Size: {stat.st_size} bytes",
                f"Created: {stat.st_ctime}",
                f"Modified: {stat.st_mtime}",
                f"Accessed: {stat.st_atime}",
                f"Permissions: {oct(stat.st_mode)[-3:]}",
            ]
            
            if file_path_obj.is_file():
                mime_type = mimetypes.guess_type(file_path_obj.name)[0] or "unknown"
                info.append(f"MIME Type: {mime_type}")
            
            return "\n".join(info)
        except Exception as e:
            return f"Error getting file info: {str(e)}" 