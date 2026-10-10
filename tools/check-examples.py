#!/usr/bin/env python3
"""Extract a paper's compilable examples and compile them.

A fenced code block is an example when its attributes name a file:

    ```{.cpp file="async_int.hpp"}
    ...
    ```

Each such block is written to that file in the output directory. Blocks that
name the same file are concatenated in the order they appear, so an example
can be split across the prose that explains it. Every block is preceded by a
#line directive, so compiler diagnostics point into the paper.

Files that the paper shouldn't show (scaffolding headers, stand-ins for real
I/O) live in a support directory that is copied into the output
directory first; an extracted file with the same name replaces it.

Every extracted .cpp file is then compiled, but not linked. The exit status is
non-zero if any of them fails to compile.
"""

import argparse
import pathlib
import re
import shutil
import subprocess
import sys

FENCE = re.compile(r'^(`{3,}|~{3,})\s*\{([^}]*)\}\s*$')
FILE_ATTR = re.compile(r'(?:^|\s)file="([^"]+)"')


def extract(paper):
    files = {}
    lines = paper.read_text().splitlines(keepends=True)
    i = 0
    while i < len(lines):
        fence = FENCE.match(lines[i])
        name = fence and FILE_ATTR.search(fence.group(2))
        i += 1
        if not name:
            continue
        start = i
        while i < len(lines) and not lines[i].startswith(fence.group(1)):
            i += 1
        if i == len(lines):
            sys.exit(f'{paper}:{start}: unterminated code block for {name.group(1)}')
        files.setdefault(name.group(1), []).append(
            f'#line {start + 1} "{paper}"\n' + ''.join(lines[start:i]))
        i += 1
    return {name: ''.join(blocks) for name, blocks in files.items()}


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    parser.add_argument('paper', type=pathlib.Path)
    parser.add_argument('--out', type=pathlib.Path, required=True,
                        help='output directory (emptied first)')
    parser.add_argument('--support', type=pathlib.Path,
                        help='directory of files the paper does not show')
    parser.add_argument('--cxx', default='c++', help='compiler to run')
    parser.add_argument('cxxflags', nargs='*', help='flags for every compile')
    args = parser.parse_args()

    shutil.rmtree(args.out, ignore_errors=True)
    args.out.mkdir(parents=True)
    if args.support and args.support.is_dir():
        shutil.copytree(args.support, args.out, dirs_exist_ok=True)

    files = extract(args.paper)
    for name, text in files.items():
        path = args.out / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)

    sources = sorted(name for name in files if name.endswith('.cpp'))
    failed = [source for source in sources if subprocess.run(
        [args.cxx, *args.cxxflags, '-I', str(args.out), '-c',
         str(args.out / source), '-o', str(args.out / f'{source}.o')]
    ).returncode != 0]

    for source in failed:
        print(f'failed: {source}', file=sys.stderr)
    print(f'{len(sources) - len(failed)} of {len(sources)} examples compiled',
          file=sys.stderr)
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main()
