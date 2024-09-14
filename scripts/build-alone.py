import argparse
import shutil
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description="Build a tex file in book environment by its hash.")
parser.add_argument(
    'hash', 
    metavar='hash', 
    type=str, 
    help='the hash of the section to build'
)
parser.add_argument(
    '--trashaux', 
    metavar='trashaux', 
    type=str, 
    help='trash entire folder (including aux)',
    required=False
)
args = parser.parse_args()

h = args.hash
trashaux = args.trashaux

# find the tex file

chdirs = []
p = Path('.') # ls of directory
for x in p.rglob("*"): # includes subdirectories
	if x.is_dir() and str(x).startswith('ch'):
		chdirs.append(str(x))
otherdirs = ['common/versioned','versionless'] # directories to search
dirs = otherdirs + chdirs

f = None
for d in dirs:
	if Path.exists(Path(d+f'/{h}')):
		f = Path(d+f'/{h}/index.tex')
	elif Path.exists(Path(d+f'/{h}.tex')):
		f = Path(d+f'/{h}.tex')

if not f:
	raise(Exception(f'A TeX file for hash {h} not found!'))
elif not Path.exists(f):
	raise(Exception(f'A TeX file for hash {h} not found!'))
else:
	print(f'File {f} found.')

# identify output tex file

build_dir = Path(f'build-sections/{h}')
if Path.exists(build_dir):
	if trashaux == True or trashaux == 'true':
		shutil.rmtree(build_dir)
build_dir.mkdir(parents=True,exist_ok=True)
exercises_dir = Path(f'{build_dir}/exercises')
exercises_dir.mkdir(parents=True,exist_ok=True) # for xsim problems
full_tex_filename = f'{build_dir}/{h}.tex'

# identify 0-*.tex files

tex_filenames = [
	'0-documentclass.tex',
	'0-xr.tex',
	'0-preamble.tex',
	'0-begin.tex',
	f,
	'0-bib.tex',
	'0-index.tex',
	'0-post.tex'
]

print(f'Writing buildable file to {full_tex_filename}')

with open(full_tex_filename, 'w') as full_tex_file:
	for tex_filename in tex_filenames:
		with open(tex_filename) as tex_file:
			for line in tex_file:
				full_tex_file.write(line)

# copy styles to the directory (to fix issue with missing styles/index_style.ist)

styles_dir = Path('common/styles-tex')
if Path.exists(styles_dir):
	shutil.copytree(styles_dir,f'{build_dir}/{styles_dir}',dirs_exist_ok=True)
else:
	raise Exception(f'styles directory does not exist: {styles_dir}!')