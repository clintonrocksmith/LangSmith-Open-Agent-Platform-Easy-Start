"""
Web Scraping Tools for MCP Server
Provides web content extraction and scraping capabilities.
"""

import asyncio
import aiohttp
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
from typing import List, Optional, Dict, Any
import json
import re

def register_web_tools(mcp):
    """Register all web scraping tools with the MCP server."""

    @mcp.tool(description="Extract clean text content from a webpage")
    def extract_text(url: str, clean_text: bool = True) -> str:
        """Extract clean text content from a webpage."""
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
            
            response = requests.get(url, headers=headers, timeout=30)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Remove script and style elements
            for script in soup(["script", "style"]):
                script.decompose()
            
            text = soup.get_text(separator=' ', strip=True)
            
            if clean_text:
                # Remove extra whitespace
                text = re.sub(r'\s+', ' ', text)
                text = text.strip()
            
            # Get title if available
            title = soup.find('title')
            title_text = title.get_text(strip=True) if title else "No title"
            
            result = f"Title: {title_text}\nURL: {url}\n\n{text}"
            return result
        except Exception as e:
            return f"Error extracting text: {str(e)}"

    @mcp.tool(description="Extract all links from a webpage")
    def extract_links(url: str, internal_only: bool = False) -> str:
        """Extract all links from a webpage."""
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
            
            response = requests.get(url, headers=headers, timeout=30)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            base_domain = urlparse(url).netloc
            links = []
            
            for link in soup.find_all('a', href=True):
                href = urljoin(url, link['href'])
                text = link.get_text(strip=True)
                
                # Filter for internal links if requested
                if internal_only:
                    link_domain = urlparse(href).netloc
                    if link_domain != base_domain:
                        continue
                
                links.append({
                    'text': text,
                    'url': href,
                    'is_internal': urlparse(href).netloc == base_domain
                })
            
            # Remove duplicates
            unique_links = []
            seen_urls = set()
            for link in links:
                if link['url'] not in seen_urls:
                    unique_links.append(link)
                    seen_urls.add(link['url'])
            
            results = [f"Extracted {len(unique_links)} unique links from {url}:"]
            
            for link in unique_links[:20]:  # Limit to first 20 links
                internal_marker = "🏠" if link['is_internal'] else "🌐"
                results.append(f"{internal_marker} {link['text']}: {link['url']}")
            
            if len(unique_links) > 20:
                results.append(f"... and {len(unique_links) - 20} more links")
            
            return "\n".join(results)
        except Exception as e:
            return f"Error extracting links: {str(e)}"

    @mcp.tool(description="Search the web using DuckDuckGo")
    def search_web(query: str, num_results: int = 10) -> str:
        """Search the web using DuckDuckGo."""
        try:
            search_url = f"https://html.duckduckgo.com/html/?q={query}"
            
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
            
            response = requests.get(search_url, headers=headers, timeout=30)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            results = []
            results.append(f"Search results for: {query}")
            results.append("=" * 50)
            
            # Extract search results
            search_results = soup.find_all('div', class_='result')
            
            for i, result in enumerate(search_results[:num_results]):
                title_elem = result.find('a', class_='result__a')
                snippet_elem = result.find('a', class_='result__snippet')
                
                title = title_elem.get_text(strip=True) if title_elem else "No title"
                snippet = snippet_elem.get_text(strip=True) if snippet_elem else "No snippet"
                link_url = title_elem.get('href') if title_elem else "No URL"
                
                results.append(f"\n{i+1}. {title}")
                results.append(f"   {link_url}")
                results.append(f"   {snippet}")
            
            if not search_results:
                results.append("No search results found.")
            
            return "\n".join(results)
        except Exception as e:
            return f"Error searching web: {str(e)}" 