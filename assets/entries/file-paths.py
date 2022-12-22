import glob
import pathlib
import json

path = "C:/Users/squid/Dropbox/Haxe/SECRET_PROJECT/assets/"
raw_files = glob.glob(path + "/**/*.*", recursive=True)
split_on = "SECRET_PROJECT/"

files = []
for file in raw_files:
    for extension in [
        ".json",
        ".png",
        ".xml",
        ".txt",
        ".ogg",
        ".ttf",
        ".world",
        ".tasc",
        ".mp3",
    ]:
        if extension in file:
            files.append(file)

cache = {"paths": []}

for file in files:
    file_name = file.split("\\")[-1]
    cache["paths"].append(
        {
            "file": file_name,
            "path": file.replace("\\", "/")
            .split(split_on)[1]
            .replace("/%s" % file_name, ""),
        }
    )


with open("./assets/entries/file-paths.json", "w") as output:
    out = json.dumps(cache, indent=4)
    print(out)
    output.writelines(out)
