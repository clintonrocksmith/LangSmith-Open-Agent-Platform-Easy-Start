"""
Data Processing Tools for MCP Server
Provides data analysis, transformation, and processing capabilities.
"""

import json
import csv
import io
import re
import hashlib
import base64
from typing import Optional

def register_data_tools(mcp):
    """Register all data processing tools with the MCP server."""

    @mcp.tool(description="Format and validate JSON data")
    def process_json(json_data: str, operation: str = "format") -> str:
        """Process JSON data with various operations."""
        try:
            data = json.loads(json_data)
            
            if operation == "format":
                formatted = json.dumps(data, indent=2, ensure_ascii=False)
                result = f"JSON Processing - Operation: {operation}\n"
                result += "=" * 50 + "\n"
                result += "Formatted JSON:\n"
                result += formatted
                return result
                
            elif operation == "validate":
                result = f"JSON Processing - Operation: {operation}\n"
                result += "=" * 50 + "\n"
                result += "✅ JSON is valid\n"
                result += f"Type: {type(data).__name__}\n"
                if isinstance(data, dict):
                    result += f"Keys: {len(data)} ({', '.join(list(data.keys())[:10])}{'...' if len(data) > 10 else ''})\n"
                elif isinstance(data, list):
                    result += f"Items: {len(data)}\n"
                return result
            else:
                return f"Error: Unknown operation '{operation}'. Available: format, validate"
                
        except json.JSONDecodeError as e:
            return f"Error: Invalid JSON - {str(e)}"
        except Exception as e:
            return f"Error processing JSON: {str(e)}"

    @mcp.tool(description="Analyze text for word count, sentiment, and readability")
    def analyze_text(text: str, analysis_type: str = "word_count") -> str:
        """Perform various text analysis operations."""
        try:
            results = [f"Text Analysis - Type: {analysis_type}"]
            results.append("=" * 50)
            
            if analysis_type == "word_count":
                words = re.findall(r'\b\w+\b', text.lower())
                words = [word for word in words if len(word) >= 3]
                
                word_freq = {}
                for word in words:
                    word_freq[word] = word_freq.get(word, 0) + 1
                
                # Sort by frequency
                sorted_words = sorted(word_freq.items(), key=lambda x: x[1], reverse=True)
                
                results.append(f"Total words: {len(words)}")
                results.append(f"Unique words: {len(word_freq)}")
                results.append(f"Top 15 most frequent words:")
                for word, count in sorted_words[:15]:
                    results.append(f"  {word}: {count}")
                    
            elif analysis_type == "char_count":
                char_count = len(text)
                char_count_no_spaces = len(text.replace(' ', ''))
                lines = text.split('\n')
                paragraphs = [p for p in text.split('\n\n') if p.strip()]
                
                results.append(f"Total characters: {char_count}")
                results.append(f"Characters (no spaces): {char_count_no_spaces}")
                results.append(f"Lines: {len(lines)}")
                results.append(f"Paragraphs: {len(paragraphs)}")
                if lines:
                    results.append(f"Average line length: {char_count / len(lines):.1f} characters")
                    
            elif analysis_type == "sentiment":
                # Simple sentiment analysis based on word lists
                positive_words = ['good', 'great', 'excellent', 'amazing', 'wonderful', 'fantastic', 'love', 'like', 'happy', 'joy']
                negative_words = ['bad', 'terrible', 'awful', 'hate', 'dislike', 'sad', 'angry', 'frustrated', 'disappointed']
                
                words = re.findall(r'\b\w+\b', text.lower())
                positive_count = sum(1 for word in words if word in positive_words)
                negative_count = sum(1 for word in words if word in negative_words)
                
                sentiment_score = positive_count - negative_count
                total_sentiment_words = positive_count + negative_count
                
                results.append(f"Positive words: {positive_count}")
                results.append(f"Negative words: {negative_count}")
                results.append(f"Sentiment score: {sentiment_score}")
                
                if sentiment_score > 0:
                    sentiment = "Positive"
                elif sentiment_score < 0:
                    sentiment = "Negative"
                else:
                    sentiment = "Neutral"
                
                results.append(f"Overall sentiment: {sentiment}")
                
                if total_sentiment_words > 0:
                    results.append(f"Sentiment ratio: {positive_count / total_sentiment_words * 100:.1f}% positive")
            else:
                return f"Error: Unknown analysis type '{analysis_type}'. Available: word_count, char_count, sentiment"
            
            return "\n".join(results)
        except Exception as e:
            return f"Error analyzing text: {str(e)}"

    @mcp.tool(description="Convert data between JSON and CSV formats")
    def convert_data(data: str, source_format: str, target_format: str) -> str:
        """Convert data between different formats."""
        try:
            # Parse source data
            if source_format == "json":
                parsed_data = json.loads(data)
            elif source_format == "csv":
                # Simple CSV parsing
                lines = data.strip().split('\n')
                if not lines:
                    return "Error: Empty CSV data"
                
                headers = [h.strip() for h in lines[0].split(',')]
                parsed_data = []
                for line in lines[1:]:
                    values = [v.strip() for v in line.split(',')]
                    if len(values) == len(headers):
                        parsed_data.append(dict(zip(headers, values)))
            else:
                return f"Error: Unsupported source format '{source_format}'"
            
            # Convert to target format
            if target_format == "json":
                output = json.dumps(parsed_data, indent=2, ensure_ascii=False)
            elif target_format == "csv":
                if isinstance(parsed_data, list) and all(isinstance(item, dict) for item in parsed_data):
                    if parsed_data:
                        headers = list(parsed_data[0].keys())
                        csv_lines = [','.join(headers)]
                        for item in parsed_data:
                            row = [str(item.get(h, '')) for h in headers]
                            csv_lines.append(','.join(row))
                        output = '\n'.join(csv_lines)
                    else:
                        output = ""
                else:
                    return "Error: Data must be a list of dictionaries for CSV conversion"
            else:
                return f"Error: Unsupported target format '{target_format}'"
            
            result = f"Data Conversion: {source_format} → {target_format}\n"
            result += "=" * 50 + "\n"
            result += output
            
            return result
        except Exception as e:
            return f"Error converting data: {str(e)}"

    @mcp.tool(description="Generate hash values for data")
    def hash_data(data: str, algorithm: str = "sha256") -> str:
        """Generate hash values for data."""
        try:
            data_bytes = data.encode('utf-8')
            
            if algorithm == "md5":
                hash_obj = hashlib.md5(data_bytes)
            elif algorithm == "sha1":
                hash_obj = hashlib.sha1(data_bytes)
            elif algorithm == "sha256":
                hash_obj = hashlib.sha256(data_bytes)
            elif algorithm == "sha512":
                hash_obj = hashlib.sha512(data_bytes)
            else:
                return f"Error: Unsupported algorithm '{algorithm}'. Available: md5, sha1, sha256, sha512"
            
            hash_value = hash_obj.hexdigest()
            
            results = [f"Hash Generation - Algorithm: {algorithm.upper()}"]
            results.append("=" * 50)
            results.append(f"Input data length: {len(data)} characters")
            results.append(f"Hash value: {hash_value}")
            
            return "\n".join(results)
        except Exception as e:
            return f"Error generating hash: {str(e)}"

    @mcp.tool(description="Encode or decode data using Base64 or URL encoding")
    def encode_decode(data: str, operation: str) -> str:
        """Encode or decode data using various methods."""
        try:
            import urllib.parse
            
            results = [f"Encode/Decode - Operation: {operation}"]
            results.append("=" * 50)
            
            if operation == "base64_encode":
                encoded = base64.b64encode(data.encode('utf-8')).decode('ascii')
                results.append(f"Original: {data}")
                results.append(f"Base64 encoded: {encoded}")
                
            elif operation == "base64_decode":
                try:
                    decoded = base64.b64decode(data).decode('utf-8')
                    results.append(f"Base64 input: {data}")
                    results.append(f"Decoded: {decoded}")
                except Exception as e:
                    return f"Error: Invalid Base64 data - {str(e)}"
                    
            elif operation == "url_encode":
                encoded = urllib.parse.quote(data)
                results.append(f"Original: {data}")
                results.append(f"URL encoded: {encoded}")
                
            elif operation == "url_decode":
                decoded = urllib.parse.unquote(data)
                results.append(f"URL encoded input: {data}")
                results.append(f"Decoded: {decoded}")
                
            else:
                return f"Error: Unknown operation '{operation}'. Available: base64_encode, base64_decode, url_encode, url_decode"
            
            return "\n".join(results)
        except Exception as e:
            return f"Error in encode/decode operation: {str(e)}" 