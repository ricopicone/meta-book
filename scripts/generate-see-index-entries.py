import json
import argparse

argparser = argparse.ArgumentParser(description="Generate index entries for see entries")
argparser.add_argument("equivalents", help="Path to the JSON file containing the see entries (scripts/see-index-entries.json)")
argparser.add_argument("tex_output", help="Path to the TeX file to write the index entries to (scripts/see-index-entries.tex)")
args = argparser.parse_args()

def generate_index(equivalents):
    index_entries = ""
    for key, value in equivalents.items():
        for item in value:
            index_entries += "\\index{" + item + "|see{" + key + "}}\n"
    return index_entries

equivalents = json.load(open(args.equivalents))

index = generate_index(equivalents)

with open(args.tex_output, "w") as f:
    f.write(index)
