import json
import requests
from packaging import version

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
    with open("versions.txt", "w", encoding="utf-8") as file:
        for v in versions:
            file.write(str(v) + '\n')
        for v in invalid_versions:
            file.write(v + '\n')
