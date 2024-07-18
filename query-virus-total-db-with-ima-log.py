#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""
################################################################################
# Copyright 2024, Fraunhofer Institute for Secure Information Technology SIT.  #
# All rights reserved.                                                         #
# ---------------------------------------------------------------------------- #
# Queries VirusTotal for information on a file using an ASCII IMA log in the   #
# 'ima-ng' SHA-256 format.                                                     #
# ---------------------------------------------------------------------------- #
# Author:        Michael Eckel <michael.eckel@sit.fraunhofer.de>               #
# Date Modified: 2024-05-15T11:18:05+00:00                                     #
# Date Created:  2024-01-07T16:56:11+00:00                                     #
################################################################################
"""

__author__ = "Michael Eckel <michael.eckel@sit.fraunhofer.de>"


import argparse
import json
import os
import re
import requests
import time


def main():
    # parse CLI arguments
    parser = argparse.ArgumentParser(
        description="Query VirusTotal for information on a file identified by its hash value.")
    parser.add_argument(
        "ima_file_path", help="The file path to the ASCII IMA log in expected format: 'ima-ng' with SHA-256.")
    parser.add_argument(
        "api_key", help="Your VirusTotal API key. Please obtain one from <https://www.virustotal.com/gui/join-us>.")
    parser.add_argument(
        "dest_folder", help="The destination folder for the JSON results; one file per hash. Overwrites existing files.")
    parser.add_argument('--timeout', type=positive_int, default=0,
                        help='Timeout in seconds between processing entries. Must be a positive integer.')
    parser.add_argument('--dry-run', action='store_true',
                        help='Run the script in dry-run mode without querying the VirusTotal database.')
    args = parser.parse_args()

    # sanity checks
    if not os.path.isdir(args.dest_folder):
        print(f"The folder '{args.dest_folder}' exists.")
        return 1

    # query VirusTotal
    for hash_type, hash_value in generate_hashes_from_ima_log(args.ima_file_path):
        # print current hash
        print(f"{hash_type}: {hash_value}")

        # check if it is a hex string
        if not is_hex_string(hash_value):
            print(f"  ERROR: not a hex value: {hash_value}; skipping ...")
            continue

        # check if dry-run mode
        result = ''
        if args.dry_run:
            print("  INFO: Running in dry run mode. Not querying VirusTotal database.")
        else:
            # query VirusTotal
            result = query_virustotal(hash_value, args.api_key)

            # craft destination file name and write JSON result
            dest_filename = os.path.join(
                args.dest_folder, hash_value) + ".json"
            with open(dest_filename, 'w') as file:
                file.write(json.dumps(result, indent=2))

        # wait (timeout)
        if (args.timeout > 0):
            print(f"  INFO: Waiting for {args.timeout} seconds.")
            time.sleep(args.timeout)


def generate_hashes_from_ima_log(file_path):
    with open(file_path, 'r') as file:
        for line in file:
            parts = line.strip().split()
            # ensure correct format: ima-ng
            if len(parts) >= 3 and parts[2] == "ima-ng":
                # the hash prefix ("sha256:") is optional
                for part in parts:
                    if ':' in part:  # hash with explicit type
                        hash_info = part.split(':')
                        if len(hash_info) == 2:
                            hash_type, hash_value = hash_info
                            yield (hash_type, hash_value)
                            break  # assuming only one hash per line
                    elif len(part) == 64:  # assuming SHA-256 without explicit type
                        yield ("sha256 (assumed)", part)
                        break  # Assuming only one hash per line


def query_virustotal(hash_value, api_key):
    # API Info: https://docs.virustotal.com/reference/overview
    url = f'https://www.virustotal.com/api/v3/files/{hash_value}'
    headers = {'accept': 'application/json', 'x-apikey': api_key}
    response = requests.get(url, headers=headers)

    # check status code of response
    if response.status_code == 200:
        # request successful
        return response.json()
    elif response.status_code == 400:
        # bad request - the request was somehow incorrect
        return {'error': 'Bad request. The request was incorrect or cannot be otherwise served.'}
    elif response.status_code == 403:
        # forbidden - API key is wrong or lacks access to a resource
        return {'error': 'Forbidden. You don’t have enough permissions to make the request.'}
    elif response.status_code == 404:
        # not found - the requested item doesn’t exist
        return {'error': 'Not found. The requested resource does not exist.'}
    elif response.status_code == 429:
        # too many requests - quota exceeded
        return {'error': 'Too many requests. You have exceeded your API request rate limit.'}
    else:
        # other errors
        return {'error': f'HTTP {response.status_code}. An error occurred.'}


def positive_int(value):
    ivalue = int(value)
    if ivalue <= 0:
        raise argparse.ArgumentTypeError(
            f"{value} is an invalid positive int value")
    return ivalue


def is_hex_string(s):
    pattern = re.compile(r'^[0-9a-fA-F]+$')
    return bool(pattern.match(s))


if __name__ == '__main__':
    main()
