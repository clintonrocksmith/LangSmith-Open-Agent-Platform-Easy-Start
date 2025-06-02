"""
API Integrations Tools for MCP Server
Provides integrations with various external APIs for weather, news, and utilities.
"""

import requests
import json
from typing import Optional

def register_api_tools(mcp):
    """Register all API integration tools with the MCP server."""

    @mcp.tool(description="Get current weather information for a location")
    def get_weather(location: str) -> str:
        """Get current weather information for a location using wttr.in."""
        try:
            weather_url = f"http://wttr.in/{location}?format=j1"
            
            response = requests.get(weather_url, timeout=30)
            if response.status_code == 200:
                data = response.json()
                
                current = data['current_condition'][0]
                weather_desc = current['weatherDesc'][0]['value']
                temp_c = current['temp_C']
                temp_f = current['temp_F']
                humidity = current['humidity']
                wind_speed = current['windspeedKmph']
                wind_dir = current['winddir16Point']
                feels_like_c = current['FeelsLikeC']
                feels_like_f = current['FeelsLikeF']
                
                # Get location info
                area = data['nearest_area'][0]
                location_name = f"{area['areaName'][0]['value']}, {area['country'][0]['value']}"
                
                result = [
                    f"Weather for {location_name}",
                    "=" * 40,
                    f"Condition: {weather_desc}",
                    f"Temperature: {temp_c}°C ({temp_f}°F)",
                    f"Feels like: {feels_like_c}°C ({feels_like_f}°F)",
                    f"Humidity: {humidity}%",
                    f"Wind: {wind_speed} km/h {wind_dir}",
                ]
                
                return "\n".join(result)
            else:
                return f"Error: Unable to fetch weather data (HTTP {response.status_code})"
        except Exception as e:
            return f"Error getting weather: {str(e)}"

    @mcp.tool(description="Get latest tech news from Hacker News")
    def get_news(page_size: int = 10) -> str:
        """Get latest tech news from Hacker News."""
        try:
            url = "https://hacker-news.firebaseio.com/v0/topstories.json"
            
            response = requests.get(url, timeout=30)
            if response.status_code == 200:
                story_ids = response.json()
                
                results = ["Top Tech News (Hacker News)"]
                results.append("=" * 40)
                
                # Get details for first few stories
                for i, story_id in enumerate(story_ids[:page_size], 1):
                    story_url = f"https://hacker-news.firebaseio.com/v0/item/{story_id}.json"
                    story_response = requests.get(story_url, timeout=10)
                    if story_response.status_code == 200:
                        story = story_response.json()
                        
                        title = story.get('title', 'No title')
                        url = story.get('url', 'No URL')
                        score = story.get('score', 0)
                        comments = story.get('descendants', 0)
                        
                        results.append(f"\n{i}. {title}")
                        results.append(f"   Score: {score} | Comments: {comments}")
                        if url != 'No URL':
                            results.append(f"   URL: {url}")
                
                return "\n".join(results)
            else:
                return f"Error: Unable to fetch news (HTTP {response.status_code})"
        except Exception as e:
            return f"Error getting news: {str(e)}"

    @mcp.tool(description="Get current cryptocurrency prices")
    def get_crypto_prices() -> str:
        """Get current cryptocurrency prices."""
        try:
            url = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,litecoin,ripple,cardano&vs_currencies=usd&include_24hr_change=true"
            
            response = requests.get(url, timeout=30)
            if response.status_code == 200:
                data = response.json()
                
                results = ["Cryptocurrency Prices (USD)"]
                results.append("=" * 40)
                
                crypto_names = {
                    'bitcoin': 'Bitcoin (BTC)',
                    'ethereum': 'Ethereum (ETH)',
                    'litecoin': 'Litecoin (LTC)',
                    'ripple': 'XRP (XRP)',
                    'cardano': 'Cardano (ADA)'
                }
                
                for crypto_id, crypto_data in data.items():
                    name = crypto_names.get(crypto_id, crypto_id.title())
                    price = crypto_data['usd']
                    change_24h = crypto_data.get('usd_24h_change', 0)
                    change_symbol = "+" if change_24h >= 0 else ""
                    
                    results.append(f"{name}: ${price:,.2f} ({change_symbol}{change_24h:.2f}%)")
                
                return "\n".join(results)
            else:
                return f"Error: Unable to fetch crypto prices (HTTP {response.status_code})"
        except Exception as e:
            return f"Error getting crypto prices: {str(e)}"

    @mcp.tool(description="Get information about an IP address")
    def get_ip_info(ip_address: Optional[str] = None) -> str:
        """Get information about an IP address."""
        try:
            if ip_address:
                url = f"http://ip-api.com/json/{ip_address}"
            else:
                url = "http://ip-api.com/json/"
            
            response = requests.get(url, timeout=30)
            if response.status_code == 200:
                data = response.json()
                
                if data['status'] == 'success':
                    results = [f"IP Information for {data['query']}"]
                    results.append("=" * 40)
                    results.append(f"Country: {data.get('country', 'Unknown')}")
                    results.append(f"Region: {data.get('regionName', 'Unknown')}")
                    results.append(f"City: {data.get('city', 'Unknown')}")
                    results.append(f"ZIP: {data.get('zip', 'Unknown')}")
                    results.append(f"ISP: {data.get('isp', 'Unknown')}")
                    results.append(f"Organization: {data.get('org', 'Unknown')}")
                    results.append(f"Timezone: {data.get('timezone', 'Unknown')}")
                    results.append(f"Coordinates: {data.get('lat', 'Unknown')}, {data.get('lon', 'Unknown')}")
                    
                    return "\n".join(results)
                else:
                    return f"Error: {data.get('message', 'Unknown error')}"
            else:
                return f"Error: Unable to fetch IP data (HTTP {response.status_code})"
        except Exception as e:
            return f"Error getting IP info: {str(e)}" 