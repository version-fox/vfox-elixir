import json
import requests

# fetch version: -> https://api.github.com/repos/elixir-lang/elixir/tags?per_page=100&sort=pushed
# github api has rate limt
# prefer use local version file
def update_all_version_from_github_api():
    url = "https://api.github.com/repos/elixir-lang/elixir/tags?per_page=100&sort=pushed"
    response = requests.get(url)
    data = response.json()
    print(data)
    if response.status_code != 200:
        print("Failed to fetch data from github api")
        return

    with open("elixir_versions_from_gtihub_api.json", 'w', encoding="utf-8") as file:
        json.dump(data, file, indent=4)

def get_all_version():
    version_set = set()
    with open("elixir_versions_from_gtihub_api.json", 'r', encoding="utf-8") as file:
        data = json.load(file)
        for item in data:
            if "refs/tags/" not in item["tarball_url"]:
                continue
            version = item["tarball_url"].split("refs/tags/v")[1]
            version_set.add(version)
    return version_set

if __name__ == "__main__":
    update_all_version_from_github_api()
    version_set = get_all_version()
    with open("versions.txt", 'w') as file:
        for version in version_set:
            file.write(version + '\n')