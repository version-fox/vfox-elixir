import json
import requests
from packaging import version

def fetch_hex_builds():
    """Fetch builds from hex.pm that include main and development versions"""
    try:
        url = "https://builds.hex.pm/builds/elixir/builds.txt"
        response = requests.get(url)
        if response.status_code != 200:
            print("Failed to fetch data from hex.pm builds")
            return []
        
        builds = []
        for line in response.text.strip().split('\n'):
            line = line.strip()
            if line:
                builds.append(line)
        
        return builds
    except Exception as e:
        print(f"Error fetching hex builds: {e}")
        return []

def filter_main_builds(builds):
    """Filter builds to include main and main-otp-* versions"""
    main_builds = []
    for build in builds:
        # Include main and main-otp-XX patterns
        if build.startswith('main') or '-main-' in build:
            main_builds.append(build)
    return main_builds

def get_main_builds():
    """Get main builds from hex.pm"""
    # Fetch main builds from hex.pm
    hex_builds = fetch_hex_builds()
    main_builds = filter_main_builds(hex_builds)
    
    # For now, if hex.pm is not accessible, provide some example main builds
    # This matches what users expect based on the issue discussion
    if not main_builds:
        print("Using fallback main builds (hex.pm not accessible)")
        main_builds = [
            'main',
            'main-otp-24',
            'main-otp-25', 
            'main-otp-26',
            'main-otp-27'
        ]
    
    return main_builds

# fetch version: -> https://api.github.com/repos/elixir-lang/elixir/tags?per_page=100&sort=pushed
# github api has rate limt
# prefer use local version file
def update_all_version_from_github_api():
    all_version = []
    for page in range(1,10):
        url = f"https://api.github.com/repos/elixir-lang/elixir/tags?per_page=100&sort=pushed&page={page}"
        response = requests.get(url)
        if response.status_code != 200:
            print("Failed to fetch data from github api")
            return
        data = response.json()

        data = response.json()
        all_version = all_version + data


    with open("elixir_versions_from_github_api.json", 'w', encoding="utf-8") as file:
        json.dump(all_version, file, indent=4)

def get_all_version():
    version_set = set()
    with open("elixir_versions_from_github_api.json", 'r', encoding="utf-8") as file:
        data = json.load(file)
        for item in data:
            if "refs/tags/" not in item["tarball_url"]:
                continue
            split_info = item["tarball_url"].split("refs/tags/v")
            if len(split_info) > 1:
                version = split_info[1]
                version_set.add(version)
    return version_set

def parse_version(ver):
    try:
        return version.parse(ver), True
    except version.InvalidVersion:
        print(f"Invalid version: {ver}")
        return ver, False

if __name__ == "__main__":
    update_all_version_from_github_api()
    versions = list(get_all_version())
    valid_versions = [] # semantic version
    invalid_versions = []
    for v in versions:
        ver, is_valid = parse_version(v)
        if is_valid:
            valid_versions.append(ver)
            continue
        invalid_versions.append(ver)

    versions = sorted(valid_versions, reverse=True)
    
    # Get main builds from hex.pm
    main_builds = get_main_builds()
    
    with open("versions.txt", "w", encoding="utf-8") as file:
        # First write main builds at the top
        for build in main_builds:
            file.write(build + '\n')
        # Then write regular versions
        for v in versions:
            file.write(str(v) + '\n')
        for v in invalid_versions:
            file.write(v + '\n')
