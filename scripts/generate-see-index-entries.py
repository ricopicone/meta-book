def generate_index(equivalents):
    index_entries = ""
    for key, value in equivalents.items():
        for item in value:
            index_entries += "\\myindex{" + item + "|see{" + key + "}}\n"
    return index_entries

equivalents = {
    # "Amplifers": ["Amplifires am I right"],
}

index = generate_index(equivalents)

with open("index-see-entries.tex", "w") as f:
    f.write(index)
