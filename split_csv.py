import os
import csv


input_path = r"C:\Users\YOUR_USERNAME\Downloads\large_file.csv"
output_dir = r"C:\Users\YOUR_USERNAME\Downloads\csv_parts"

target_size = 150 * 1024 * 1024  

os.makedirs(output_dir, exist_ok=True)

with open(input_path, "r", newline="", encoding="utf-8-sig") as source:
    reader = csv.reader(source)
    header = next(reader)

    part = 1
    output = None
    writer = None

    def new_part():
        global_dummy = None
        path = os.path.join(output_dir, f"part_{part:03d}.csv")
        f = open(path, "w", newline="", encoding="utf-8")
        w = csv.writer(f)
        w.writerow(header)
        return f, w

    output, writer = new_part()

    for row in reader:
        writer.writerow(row)

        if output.tell() >= target_size:
            output.close()
            part += 1
            output, writer = new_part()

    output.close()

print(f"Finished. Parts saved in: {output_dir}")