#!/usr/bin/env python3
#Opens, reads, sorts, and outputs a valid input file of IPv4 OR IPv6 Addresses.

import sys
import ipaddress

with open('InternetProtocols.txt', 'r') as f:
	try:
		ips = sorted(ipaddress.ip_address(line.strip()) for line in f)
		sys.stdout.write('\n'.join(map(str, ips)))
		sys.stdout.write("\nEnd of list. Press Any Key To Exit.")
	except ValueError:
		sys.stdout.write('Input Error. Please re-check file contains only IPv4 or only IPv6 addresses.')
	input()