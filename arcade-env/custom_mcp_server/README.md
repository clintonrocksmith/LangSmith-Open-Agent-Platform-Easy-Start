# Custom MCP Server with Comprehensive Tools

A powerful Model Context Protocol (MCP) server built with Python that provides a comprehensive set of tools for file operations, web scraping, API integrations, system utilities, and data processing.

## 🚀 Features

### 📁 File Operations
- **read_file**: Read file contents with encoding support
- **write_file**: Write/append content to files with automatic directory creation
- **search_files**: Search files by pattern and content with recursive support
- **list_directory**: List directory contents with detailed information
- **delete_file**: Safely delete files and directories
- **copy_file**: Copy files and directories with recursive support
- **create_directory**: Create directories with parent creation
- **get_file_info**: Get detailed file/directory information

### 🌐 Web Scraping
- **scrape_website**: Extract content from websites with CSS selectors
- **extract_links**: Extract all links from webpages with internal/external filtering
- **extract_text**: Clean text extraction from webpages
- **extract_metadata**: Extract metadata, Open Graph, and Twitter Card data
- **extract_tables**: Extract and format table data from webpages
- **search_web**: Search the web using DuckDuckGo

### 🔌 API Integrations
- **get_weather**: Current weather and 3-day forecast for any location
- **get_news**: Latest tech news from Hacker News with search capability
- **get_currency_rates**: Real-time currency exchange rates
- **get_ip_info**: IP address geolocation and ISP information
- **get_random_fact**: Random interesting facts
- **generate_qr_code**: Generate QR codes for text/URLs
- **shorten_url**: URL shortening service
- **get_crypto_prices**: Current cryptocurrency prices with 24h changes

### ⚙️ System Utilities
- **run_command**: Safe command execution with security filtering
- **get_system_info**: Comprehensive system information
- **monitor_resources**: Real-time resource monitoring
- **get_process_info**: Process information and management
- **get_network_info**: Network interfaces and connections
- **get_disk_usage**: Disk usage analysis
- **check_port**: Port status checking

### 📊 Data Processing
- **process_csv**: CSV data analysis (info, filter, sort, group, describe)
- **process_json**: JSON processing (format, validate, extract, transform)
- **analyze_text**: Text analysis (word count, readability, sentiment, keywords)
- **convert_data**: Data format conversion (CSV ↔ JSON ↔ YAML)
- **hash_data**: Generate hash values (MD5, SHA1, SHA256, SHA512)
- **encode_decode**: Encoding/decoding (Base64, URL encoding)
- **generate_sample_data**: Generate sample data for testing

## 🛠️ Installation

### Prerequisites
- Python 3.11+
- Virtual environment (recommended)

### Setup
```bash
# Activate your virtual environment
source bin/activate  # or activate.bat on Windows

# Install dependencies (already done in your setup)
pip install mcp aiohttp beautifulsoup4 requests pandas numpy psutil markdown pyyaml python-dotenv fastapi uvicorn httpx

# Run the server
python main.py
```

## 🚦 Running the Server

```bash
cd custom_mcp_server
python main.py
```

The server will start on `http://0.0.0.0:8000` and display:
```
🚀 Custom MCP Server running on http://0.0.0.0:8000
📚 Available tool categories:
  • File Operations (read, write, search, manage files)
  • Web Scraping (extract content from websites)
  • API Integrations (weather, news, utilities)
  • System Utilities (commands, status, monitoring)
  • Data Processing (CSV, JSON, text analysis)
```

## 📖 Usage Examples

### File Operations
```python
# Read a file
read_file(file_path="/path/to/file.txt")

# Search for Python files containing "import"
search_files(directory="/project", pattern="*.py", content_search="import")

# Create and write to a new file
write_file(file_path="/tmp/output.txt", content="Hello World!")
```

### Web Scraping
```python
# Scrape a website with specific CSS selector
scrape_website(url="https://example.com", css_selector=".content", extract_links=True)

# Extract all tables from a webpage
extract_tables(url="https://example.com/data.html")
```

### API Integrations
```python
# Get weather for a location
get_weather(location="New York, NY")

# Get latest tech news
get_news(query="artificial intelligence", page_size=5)

# Get cryptocurrency prices
get_crypto_prices()
```

### System Utilities
```python
# Get system information
get_system_info(detailed=True)

# Monitor resources for 10 seconds
monitor_resources(duration=10, interval=2.0)

# Check if port 8080 is open
check_port(port=8080)
```

### Data Processing
```python
# Analyze CSV data
process_csv(file_path="data.csv", operation="describe")

# Convert JSON to CSV
convert_data(source_format="json", target_format="csv", data='[{"name":"John","age":30}]')

# Analyze text sentiment
analyze_text(text="This is a great day!", analysis_type="sentiment")
```

## 🔒 Security Features

- **Command Execution Safety**: Dangerous commands are filtered and blocked
- **Path Validation**: File operations validate paths to prevent unauthorized access
- **Input Sanitization**: All inputs are properly validated and sanitized
- **Error Handling**: Comprehensive error handling prevents server crashes

## 🏗️ Architecture

```
custom_mcp_server/
├── main.py                 # Server entry point
├── tools/                  # Tool modules
│   ├── __init__.py
│   ├── file_operations.py  # File system tools
│   ├── web_scraping.py    # Web extraction tools
│   ├── api_integrations.py # External API tools
│   ├── system_utilities.py # System monitoring tools
│   └── data_processing.py  # Data analysis tools
└── README.md              # This file
```

## 🔧 Configuration

The server uses sensible defaults but can be configured by modifying the parameters in `main.py`:

- **Host**: `0.0.0.0` (accepts connections from any IP)
- **Port**: `8000`
- **Timeout**: Various timeouts for different operations
- **Security**: Command filtering and path validation

## 🌟 Integration with Open Agent Platform

This MCP server is designed to work seamlessly with the Open Agent Platform. To integrate:

1. Update your environment variables:
   ```bash
   NEXT_PUBLIC_MCP_SERVER_URL="http://localhost:8000"
   NEXT_PUBLIC_MCP_AUTH_REQUIRED=false
   ```

2. Restart your Open Agent Platform services

3. The tools will be automatically available to your agents

## 🤝 Contributing

To add new tools:

1. Create a new module in the `tools/` directory
2. Implement your tools following the existing patterns
3. Register your tools in the main server file
4. Update this README with your new tools

## 📝 License

This project is part of the Open Agent Platform ecosystem.

## 🆘 Troubleshooting

### Common Issues

1. **Port already in use**: Change the port in `main.py`
2. **Permission denied**: Ensure proper file permissions
3. **Module not found**: Check Python path and virtual environment
4. **Network timeouts**: Adjust timeout values for your network

### Debugging

Run with verbose logging:
```bash
python main.py --debug
```

## 🔮 Future Enhancements

- Database integration tools
- Machine learning utilities
- Docker containerization
- Authentication and authorization
- Rate limiting and caching
- WebSocket support for real-time updates 