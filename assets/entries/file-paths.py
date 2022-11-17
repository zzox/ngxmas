import glob
import pathlib
import json

path = "C:/Users/squid/Dropbox/Haxe/SECRETPROJECT/assets/"
raw_files = glob.glob(path + "/**/*.*", recursive=True)
split_on = "Swords/"

files = []
for file in raw_files:
    if ".json" in file or ".png" in file or ".xml" in file or ".txt" in file:
        files.append(file)

cache = {"paths": []}

for file in files:
    file_name = file.split("\\")[-1]
    cache["paths"].append(
        {"file": file_name, "path": file.replace("\\", "/").split(split_on)[1]}
    )

with open("./file-paths.json", "w") as output:
    output.writelines(json.dumps(cache, indent=4))
