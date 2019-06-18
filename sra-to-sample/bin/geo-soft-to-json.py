#!/usr/bin/env python

import argparse
import sys
import re
import requests

def sra_ids_in_link(link):
    r = requests.get(link)
    return re.compile('run=(SRR\d+)').findall(r.text)

def to_json(info):
    name = '_'.join([info[x] for x in ('organism', 'source', 'title')]).replace(' ', '_')
    if 'sra_ids' not in info:
        sys.stderr.write("warning: can not find sra for " + info['geo'] + "\n")
        return ('')
    return ('{'
            '"id": "' + info['title'] + '", '
            '"name": "' + name + '", '
            '"sra": ["' + '", "'.join(info['sra_ids']) + '"]'
            '}')

def main():
    parser = argparse.ArgumentParser(
        description='Convert GEO SOFT format to JSON with SRA codes.')
    parser.add_argument('--soft', required=True, help='SOFT file from GEO')
    args = parser.parse_args()

    # Variables.
    jsons = [] # list holds JSON entries for all samples.
    info = {} # dict holds information for each sample (gets overwritten)
    sample = None

    # Compile required regular expressions.
    sample_p = re.compile('\^SAMPLE = (.+)')
    sample_title_p = re.compile('\!Sample_title = (.+)')
    sample_organism_p = re.compile('\!Sample_organism_ch1 = (.+)')
    sample_source_p = re.compile('\!Sample_source_name_ch1 = (.+)')
    sample_sra_p = re.compile('\!Sample_relation = SRA: (.+)')

    # Open a handle to the input SOFT file.
    if args.soft == '-':
        f = sys.stdin
    else:
        f = open(args.soft, 'r')

    # Parse line by line until first ^SAMPLE is found.
    for l in f:
        l = l.strip("\n")
        m = sample_p.match(l)
        if m:
            sample = m.group(1)
            info = {"geo": m.group(1)}
            break

    # Parse all remaining lines in f.
    for l in f:
        l = l.strip("\n")

        m = sample_p.match(l)
        if m:
            js = to_json(info)
            if js != '':
                jsons.append(js)
            info = {"geo": m.group(1)}
            continue

        m = sample_title_p.match(l)
        if m:
            info["title"] = m.group(1)
            continue

        m = sample_organism_p.match(l)
        if m:
            info["organism"] = m.group(1)
            continue

        m = sample_source_p.match(l)
        if m:
            info["source"] = m.group(1)
            continue

        m = sample_sra_p.match(l)
        if m:
            link = m.group(1)
            sra_ids = sra_ids_in_link(link)
            info["sra_link"] = link
            info["sra_ids"] = sra_ids
            continue
    f.close()

    # Store JSON for final sample.
    if sample != None:
        jsons.append(to_json(info))

    # Print the JSON file.
    print('{ "samples":[')
    print("\t" + ",\n\t".join(jsons))
    print(']}')


if __name__ == "__main__":
    main()
