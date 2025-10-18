import json
import requests


# fetch version: -> https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28
# github api has rate limt
# prefer use local version file
def update_all_version_from_github_api():
    all_version = []
    for page in range(1, 10):
        url = f"https://api.github.com/repos/elixir-lang/elixir/releases?page={page}&per_page=100"
        response = requests.get(url)
        if response.status_code != 200:
            print("Failed to fetch data from github api")
            print(response)
            return
        data = response.json()

        data = response.json()
        all_version = all_version + data

    with open(
        "elixir_windows_versions_from_github_api.json", "w", encoding="utf-8"
    ) as file:
        json.dump(all_version, file, indent=4)


def get_all_version():
    version_set = set()
    with open(
        "elixir_windows_versions_from_github_api.json", "r", encoding="utf-8"
    ) as file:
        data = json.load(file)
        for item in data:
            for asset in item["assets"]:
                if asset["content_type"] != "application/x-ms-dos-executable":
                    continue
                version = asset["browser_download_url"].split("releases/download/")[1]
                fix_version = version.replace("/", "-")
                version_set.add(fix_version.replace(".exe", "")[1:])
    return version_set


if __name__ == "__main__":
    update_all_version_from_github_api()
    versions = list(get_all_version())
    versions = sorted(versions, reverse=True)
    print(versions)
    with open("versions_win.txt", "w") as file:
        for v in versions:
            file.write(v + "\n")
