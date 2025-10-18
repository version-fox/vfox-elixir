# --*- coding: utf-8 --*-
"""Fetch all Elixir versions from GitHub API and save to a local file."""

import json
import re
import requests
from packaging import version


# fetch version: -> https://api.github.com/repos/elixir-lang/elixir/tags?per_page=100&sort=pushed
# github api has rate limt
# prefer use local version file
def update_all_version_from_github_api():
    """Fetch all Elixir version tags from GitHub API and save to local JSON file.

    Makes paginated requests to GitHub API to retrieve all available Elixir version tags.
    The fetched data is saved to 'elixir_versions_from_github_api.json' for local use
    to avoid hitting GitHub API rate limits on subsequent runs.

    Note:
        GitHub API has rate limits, so prefer using the local version file when possible.
    """
    all_version = []
    for page in range(1, 10):
        url = (
            f"https://api.github.com/repos/elixir-lang/elixir/tags"
            f"?per_page=100&sort=pushed&page={page}"
        )
        response = requests.get(url, timeout=30)
        if response.status_code != 200:
            print("Failed to fetch data from github api")
            return
        data = response.json()

        data = response.json()
        all_version = all_version + data

    with open("elixir_versions_from_github_api.json", "w", encoding="utf-8") as file:
        json.dump(all_version, file, indent=4)


def get_all_version():
    """Extract all Elixir version numbers from GitHub API data.

    Reads the local JSON file containing GitHub API response data and extracts
    version numbers from tarball URLs that contain 'refs/tags/v' pattern.

    Returns:
        set: A set of version strings extracted from the GitHub API data.
    """
    version_set = set()
    with open("elixir_versions_from_github_api.json", "r", encoding="utf-8") as file:
        data = json.load(file)
        for item in data:
            if "refs/tags/" not in item["tarball_url"]:
                continue
            split_info = item["tarball_url"].split("refs/tags/v")
            if len(split_info) > 1:
                version_str = split_info[1]
                version_set.add(version_str)
    return version_set


def parse_version(version_string):
    """Parse a version string and return parsing result with metadata.

    Attempts to parse a version string using the packaging library's version parser.
    Returns a tuple containing the parsed version (or original string if invalid),
    a boolean indicating parsing success, and the original version string.

    Args:
        version_string (str): The version string to parse.

    Returns:
        tuple: A 3-tuple containing:
            - Parsed version object (or original string if invalid)
            - Boolean indicating if parsing was successful
            - Original version string
    """
    try:
        return version.parse(version_string), True, version_string
    except version.InvalidVersion:
        print(f"Invalid version: {version_string}")
        return version_string, False, version_string


def custom_version_sort_key(ver_tuple):
    """Custom sorting key, prioritize semantic versions, sort invalid versions by string"""
    parsed_ver, is_valid_ver, original_ver = ver_tuple
    if is_valid_ver:
        # Valid semantic version, return (0, parsed_version) to ensure it comes first
        return (0, parsed_ver)

    # Invalid version, try to extract numeric part for sorting
    # Try to match version pattern, e.g. "1.18-latest" -> "1.18"
    match = re.match(r"^(\d+(?:\.\d+)*)", original_ver)
    if match:
        try:
            # Extract numeric part and parse
            numeric_part = match.group(1)
            parsed_numeric = version.parse(numeric_part)
            return (
                1,
                parsed_numeric,
                original_ver,
            )  # After valid versions, but sorted by numeric part
        except version.InvalidVersion:
            pass
    # Completely unparseable versions, sort by string
    return (2, original_ver)


if __name__ == "__main__":
    update_all_version_from_github_api()
    versions = list(get_all_version())
    version_tuples = []
    for v in versions:
        ver, is_valid, original = parse_version(v)
        version_tuples.append((ver, is_valid, original))

    # Sort using custom sorting key
    sorted_versions = sorted(version_tuples, key=custom_version_sort_key, reverse=True)

    with open("versions.txt", "w", encoding="utf-8") as file:
        for v_tuple in sorted_versions:
            _, _, original = v_tuple
            file.write(original + "\n")
