"""
System Utilities Tools for MCP Server
Provides system monitoring, command execution, and utility functions.
"""

import psutil
import platform
import socket
from datetime import datetime

def register_system_tools(mcp):
    """Register all system utility tools with the MCP server."""

    @mcp.tool(description="Get comprehensive system information")
    def get_system_info(detailed: bool = False) -> str:
        """Get comprehensive system information."""
        try:
            results = ["System Information"]
            results.append("=" * 40)
            
            # Basic system info
            results.append(f"OS: {platform.system()} {platform.release()}")
            results.append(f"Architecture: {platform.architecture()[0]}")
            results.append(f"Machine: {platform.machine()}")
            results.append(f"Processor: {platform.processor()}")
            results.append(f"Hostname: {socket.gethostname()}")
            
            # CPU info
            cpu_count = psutil.cpu_count(logical=False)
            cpu_logical = psutil.cpu_count(logical=True)
            
            results.append(f"\nCPU:")
            results.append(f"  Physical cores: {cpu_count}")
            results.append(f"  Logical cores: {cpu_logical}")
            
            # Memory info
            memory = psutil.virtual_memory()
            
            results.append(f"\nMemory:")
            results.append(f"  Total: {memory.total / (1024**3):.2f} GB")
            results.append(f"  Available: {memory.available / (1024**3):.2f} GB")
            results.append(f"  Used: {memory.used / (1024**3):.2f} GB ({memory.percent}%)")
            
            # Disk info (cross-platform)
            try:
                if platform.system() == "Windows":
                    disk = psutil.disk_usage('C:\\')
                    disk_label = "Disk (C:)"
                else:
                    disk = psutil.disk_usage('/')
                    disk_label = "Disk (root)"
                    
                results.append(f"\n{disk_label}:")
                results.append(f"  Total: {disk.total / (1024**3):.2f} GB")
                results.append(f"  Used: {disk.used / (1024**3):.2f} GB ({disk.used/disk.total*100:.1f}%)")
                results.append(f"  Free: {disk.free / (1024**3):.2f} GB")
            except Exception as e:
                results.append(f"\nDisk: Error getting disk info - {str(e)}")
            
            # Boot time
            boot_time = datetime.fromtimestamp(psutil.boot_time())
            uptime = datetime.now() - boot_time
            results.append(f"\nSystem:")
            results.append(f"  Boot time: {boot_time.strftime('%Y-%m-%d %H:%M:%S')}")
            results.append(f"  Uptime: {str(uptime).split('.')[0]}")
            
            if detailed:
                # Running processes count
                process_count = len(psutil.pids())
                results.append(f"\nProcesses: {process_count} running")
            
            return "\n".join(results)
        except Exception as e:
            return f"Error getting system info: {str(e)}"

    @mcp.tool(description="Get top processes by CPU usage")
    def get_process_info(show_all: bool = False) -> str:
        """Get information about running processes."""
        try:
            processes = []
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent', 'status']):
                processes.append(proc.info)
            
            # Sort by CPU usage
            processes.sort(key=lambda x: x['cpu_percent'] or 0, reverse=True)
            
            limit = 20 if show_all else 10
            results = [f"Top {limit} Processes by CPU Usage:"]
            results.append("=" * 60)
            results.append("PID\tName\t\tCPU%\tMemory%\tStatus")
            results.append("-" * 60)
            
            for proc in processes[:limit]:
                cpu = proc['cpu_percent'] or 0
                mem = proc['memory_percent'] or 0
                results.append(f"{proc['pid']}\t{proc['name'][:15]}\t{cpu:.1f}%\t{mem:.2f}%\t{proc['status']}")
            
            return "\n".join(results)
        except Exception as e:
            return f"Error getting process info: {str(e)}"

    @mcp.tool(description="Get network interface information")
    def get_network_info() -> str:
        """Get network interface and connection information."""
        try:
            results = ["Network Information"]
            results.append("=" * 40)
            
            # Get network interfaces
            interfaces = psutil.net_if_addrs()
            stats = psutil.net_if_stats()
            
            for interface, addrs in interfaces.items():
                results.append(f"\n{interface}:")
                
                # Interface stats
                if interface in stats:
                    stat = stats[interface]
                    results.append(f"  Status: {'Up' if stat.isup else 'Down'}")
                    results.append(f"  Speed: {stat.speed} Mbps")
                
                # Addresses
                for addr in addrs:
                    family_name = addr.family.name
                    results.append(f"  {family_name}: {addr.address}")
            
            # Network I/O statistics
            net_io = psutil.net_io_counters()
            results.append(f"\nNetwork I/O Statistics:")
            results.append(f"  Bytes sent: {net_io.bytes_sent / (1024**2):.2f} MB")
            results.append(f"  Bytes received: {net_io.bytes_recv / (1024**2):.2f} MB")
            results.append(f"  Packets sent: {net_io.packets_sent}")
            results.append(f"  Packets received: {net_io.packets_recv}")
            
            return "\n".join(results)
        except Exception as e:
            return f"Error getting network info: {str(e)}"

    @mcp.tool(description="Check if a port is open/listening")
    def check_port(port: int) -> str:
        """Check if a port is open/listening."""
        try:
            # Check if port is in use
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            
            result_localhost = sock.connect_ex(('localhost', port))
            sock.close()
            
            results = [f"Port {port} Status Check"]
            results.append("=" * 30)
            
            if result_localhost == 0:
                results.append(f"✅ Port {port} is OPEN on localhost")
            else:
                results.append(f"❌ Port {port} is CLOSED on localhost")
            
            # Check what process is using the port
            connections = psutil.net_connections(kind='inet')
            for conn in connections:
                if conn.laddr and conn.laddr.port == port:
                    try:
                        process = psutil.Process(conn.pid)
                        results.append(f"Process using port: {process.name()} (PID: {conn.pid})")
                    except:
                        results.append(f"Process using port: PID {conn.pid}")
                    break
            
            return "\n".join(results)
        except Exception as e:
            return f"Error checking port: {str(e)}" 