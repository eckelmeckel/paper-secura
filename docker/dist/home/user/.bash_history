python3 query-virus-total-db-with-ima-log.py --timeout 2 ima-logs/ascii_runtime_measurements.sample "$(cat virustotal-api-key.txt)" out/
python3 query-virus-total-db-with-ima-log.py --timeout 2 --dry-run ima-logs/ascii_runtime_measurements.sample "$(cat virustotal-api-key.txt)" out/
