<!--
################################################################################
# Copyright 2024, Fraunhofer Institute for Secure Information Technology SIT.  #
# All rights reserved.                                                         #
# ---------------------------------------------------------------------------- #
# Dockerfile.                                                                  #
# ---------------------------------------------------------------------------- #
# Author:        Michael Eckel <michael.eckel@sit.fraunhofer.de>               #
# Date Modified: 2024-02-15T11:18:05+00:00                                     #
# Date Created:  2024-02-15T11:18:05+00:00                                     #
################################################################################
-->

**WARNING:** *THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.*

For further details, see the [LICENSE](LICENSE) file.

# Paper: SECURA: Unified Reference Architecture for Advanced Security and Trust in Safety Critical Infrastructures

Our paper "[SECURA: Unified Reference Architecture for Advanced Security and Trust in Safety Critical Infrastructures](https://doi.org/10.1145/3664476.3664513)" by [Michael Eckel](mailto:michael.eckel@sit.fraunhofer.de) and [Sigrid Gürgens](mailto:sigrid.guergens@sit.fraunhofer.de) (all [Fraunhofer SIT](https://www.sit.fraunhofer.de/) and [ATHENE Center](https://www.athene-center.de/)) was first published at the 19th International Conference on Availability, Reliability and Security ([ARES 2024](https://www.ares-conference.eu/)), organized by [SBA Research](https://www.sba-research.org/) in cooperation with the [University of Vienna](https://www.univie.ac.at/), Austria.

This repository contains the code and data referred to in the paper.

## Querying the VirusTotal Database with Linux IMA Logs

The VirusTotal database can be queried for vulnerabilities of binary executables based on a hash value.
For that purpose, it provides a REST API (<https://www.virustotal.com/api/v3/>).
An Overview of the API can be found here: <https://docs.virustotal.com/reference/overview>.

An API key is required to use the API; please obtain one from <https://www.virustotal.com/gui/join-us>.
The public API is limited to 500 requests per day and a rate of 4 requests per minute (see <https://docs.virustotal.com/reference/public-vs-premium-api>).

This proof-of-concept (PoC) implementation uses [Linux Integrity Measurement Architecture (IMA)](https://sourceforge.net/p/linux-ima/wiki/Home/) logs to query the VirusTotal database for known vulnerabilities.

### Prerequisites and Docker Container

The PoC implementation has been tested under Ubuntu 22.04 on an x86 64-bit system (amd64) using Bash.
The required packages are `python3` and `python3-requests`:

```bash
apt-get update && apt-get install -y python3 python3-requests
```

Alternatively, a Docker container can be used to execute the script in a sandbox.

Build Docker image:

```bash
docker build \
    -t 'eckelmeckel/poc-ima-vuln:1.0.0' \
    --build-arg "uid=$(id -u)" \
    --build-arg "gid=$(id -g)" \
    .
```

Run Docker container:

```bash
docker run \
    -v "${PWD}:/home/bob/poc-ima-vuln" \
    -it --rm --init \
    'eckelmeckel/poc-ima-vuln:1.0.0'
```

### IMA Logs

There is an example IMA log available under `ima-logs/ascii_runtime_measurements.sample`.

For this PoC, the IMA log is required to use the ASCII (not binary) format and the `ima-ng` template with SHA-256.
For further details, see <https://sourceforge.net/p/linux-ima/wiki/Home/#enabling-ima-measurement>.

The IMA log of a system is typically accessible via the `/sys/kernel/security/ima/ascii_runtime_measurements` character device.
You can store the system's current IMA log it in the `ima-logs` folder with:

```bash
sudo cat /sys/kernel/security/ima/ascii_runtime_measurements \
    > ima-logs/ascii_runtime_measurements
```

### API Key

Once you obtained an API key from <https://www.virustotal.com/gui/join-us>, please put it in the file `virustotal-api-key.txt`.

### Usage

The PoC script usage is as follows (`python3 query-virus-total-db-with-ima-log.py -h`):

```text
usage: query-virus-total-db-with-ima-log.py [-h] [--timeout TIMEOUT] [--dry-run] ima_file_path api_key dest_folder

Query VirusTotal for information on a file identified by its hash value.

positional arguments:
  ima_file_path      The file path to the ASCII IMA log in expected format: 'ima-ng' with SHA-256.
  api_key            Your VirusTotal API key. Please obtain one from <https://www.virustotal.com/gui/join-us>.
  dest_folder        The destination folder for the JSON results; one file per hash. Overwrites existing files.

optional arguments:
  -h, --help         show this help message and exit
  --timeout TIMEOUT  Timeout in seconds between processing entries. Must be a positive integer.
  --dry-run          Run the script in dry-run mode without querying the VirusTotal database.
```

Example invocation in *dry-run* mode (quit with Ctrl+C):

```bash
python3 query-virus-total-db-with-ima-log.py --timeout 2 --dry-run \
    ima-logs/ascii_runtime_measurements.sample "$(cat virustotal-api-key.txt)" \
    out/
```

Example invocation in *live* mode (quit with Ctrl+C):

```bash
python3 query-virus-total-db-with-ima-log.py --timeout 2 \
    ima-logs/ascii_runtime_measurements.sample "$(cat virustotal-api-key.txt)" \
    out/
```

Example outputs can be found in `example-out/`.

For logs with more than 500 entries, you have to stay within the daily limit of the VirusTotal free account.
You can use a timeout value of `175` seconds and should be fine.
