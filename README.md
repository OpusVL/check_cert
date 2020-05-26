# Nagios Plugin Check HTTPS/SSL Certificate Expiry Date

This plugin uses `curl` to extract certificate details from the host. It reports on the number of days remaining until expiry or negative numbers indicate it has expired.

## Usage

```text
Usage: check_cert.sh -H host [OPTIONS]

Options:
   -c,--critical days         minimum number of days a certificate has to be  valid to issue a critical status
   -h,--help                  a help message
   -V,--version               version
   -w,--warning days          minimum number of days a certificate has to be valid to issue a warning status
```

## Dependencies

curl
