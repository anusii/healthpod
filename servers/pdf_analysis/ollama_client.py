"""
Ollama Client for LLM Communication.

Copyright (C) 2025, Software Innovation Institute ANU

Licensed under the GNU General Public License, Version 3 (the "License");

License: https://opensource.org/license/gpl-3-0

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <https://opensource.org/license/gpl-3-0>.

Authors: Tony Chen
"""

import json
import logging
from typing import Dict, Any, Optional

import requests

# Configure logging
logger = logging.getLogger(__name__)


class OllamaClient:
    """Client for interacting with Ollama LLM API."""

    def __init__(
        self,
        base_url: str = "http://localhost:11434",
        model: str = "qwen3:8b",
        timeout: int = 900,
    ):
        """
        Initialise the Ollama client.

        Args:
            base_url: The base URL of the Ollama server
            model: The model to use (default: qwen3:8b)
            timeout: Request timeout in seconds (default: 900 for large reports)
        """
        self.base_url = base_url.rstrip("/")
        self.model = model
        self.timeout = timeout
        self.api_url = f"{self.base_url}/api/generate"

    def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.1,
        stream: bool = False,
    ) -> Dict[str, Any]:
        """
        Generate a response from the LLM.

        Args:
            prompt: The prompt to send to the LLM
            system_prompt: Optional system prompt for context
            temperature: Sampling temperature (0.0 to 1.0, lower is more deterministic)
            stream: Whether to stream the response

        Returns:
            The LLM response as a dictionary

        Raises:
            requests.exceptions.RequestException: If the request fails
            json.JSONDecodeError: If the response is not valid JSON
        """
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": stream,
            "options": {
                "temperature": temperature,
            },
        }

        if system_prompt:
            payload["system"] = system_prompt

        logger.info(f"Sending request to Ollama API: {self.api_url}")
        logger.debug(f"Model: {self.model}, Temperature: {temperature}")

        try:
            response = requests.post(self.api_url, json=payload, timeout=self.timeout)
            response.raise_for_status()

            result = response.json()
            logger.info("Successfully received response from Ollama")
            logger.debug(f"Response: {result}")

            return result

        except requests.exceptions.Timeout:
            logger.error(f"Request timed out after {self.timeout} seconds")
            raise
        except requests.exceptions.ConnectionError:
            logger.error(f"Failed to connect to Ollama server at {self.base_url}")
            raise
        except requests.exceptions.HTTPError as e:
            logger.error(f"HTTP error occurred: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            raise

    def extract_json_from_response(self, response: Dict[str, Any]) -> Dict[str, Any]:
        """
        Extract and parse JSON from the LLM response.

        Args:
            response: The response dictionary from Ollama

        Returns:
            The parsed JSON data

        Raises:
            json.JSONDecodeError: If the response does not contain valid JSON
            KeyError: If the response structure is unexpected
        """
        response_text = response.get("response", "")

        # Try to find JSON in the response (may be wrapped in markdown code
        # blocks)
        response_text = response_text.strip()

        # Remove markdown code blocks if present
        if response_text.startswith("```json"):
            response_text = response_text[7:]
        elif response_text.startswith("```"):
            response_text = response_text[3:]

        if response_text.endswith("```"):
            response_text = response_text[:-3]

        response_text = response_text.strip()

        try:
            return json.loads(response_text)
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON from response: {e}")
            logger.error(f"Response text: {response_text}")
            raise

    def check_connection(self) -> bool:
        """
        Check if the Ollama server is accessible.

        Returns:
            True if the server is accessible, False otherwise
        """
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            response.raise_for_status()
            logger.info("Successfully connected to Ollama server")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to Ollama server: {e}")
            return False
