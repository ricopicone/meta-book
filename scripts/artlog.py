import json
import xlsxwriter

fnamejson = '../common-rtcbook/book-json/book-hp1-cleaned.json'

# fix trailing comma in json
with open(fnamejson, 'r') as file:
    data = file.readlines()

for i,line in enumerate(data):
    if line.startswith('}'):
        data[i-1] = data[i-1].rstrip(', \n')
        break

with open(fnamejson,'w') as file:
    file.writelines(data)

# create spreadsheet
workbook = xlsxwriter.Workbook('artlog.xlsx')
worksheet = workbook.add_worksheet()

# open json data file
f = open(fnamejson)
data = json.load(f)

# functions

def write_row(row,irow):
    for icol,el in enumerate(row):
        worksheet.write(irow,icol,el)

def translate(figdata={}):
    table = {
        'format': {
            'pdf': '.pdf',
            'jpg': '.jpg',
            'png': '.png'
        },
        'permission': {
            'permission': 'Permission Received',
            'public': 'Not Needed - Public Domain',
            'authored': 'Not Needed - Author Created',
            'fair': 'Not Needed - Fair Use',
            'cc': 'Not Needed - Creative Commons',
            'seeking': 'Perm Needed - author seeking'
        },
        'reprint': {
            'pe': 'Print and Electronic',
            'p': 'Print Only',
            'e': 'Electronic Only'
        },
        'territory': {
            'world': 'World',
            'restricted': 'Restricted - explain in Comments'
        },
        'language': {
            'all': 'All',
            'english': 'English only',
            'other': 'Other restrictions - explain in comments'
        },
        'edition': {
            'all': 'All',
            'one': 'One',
            'ncopies': '# of copies - explain in comments'
        }
    }
    for k,v in figdata.items():
        if k in table:
            if v in table[k]:
                figdata[k] = table[k][v]
            else:
                print(f'k: {k}')
                print(f'table[k]: {table[k]}')
                print(f'v: {v}')
                print(table[k][v])
                raise Exception(f'no translation for {k} {v}')
    return figdata
 
# Iterating through the json
irow=0
for k,v in data.items():
    print(k)
    if type(v)==dict:
        if v['type'] == 'figure':
            print(v)
            figdata = translate(v)
            row = [
                figdata['number'],
                figdata['color'],
                figdata['format'],
                figdata['caption'],
                figdata['credit'],
                figdata['permission'],
                figdata['reprint'],
                figdata['territory'],
                figdata['language'],
                figdata['edition'],
                figdata['fair'],
                figdata['publicity'],
                figdata['size'],
                figdata['permissioncomment'],
                figdata['layoutcomment']
            ]
            write_row(row,irow)
            irow+=1


# Closing files
f.close()
workbook.close()
