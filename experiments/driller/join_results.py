#!/usr/bin/env python

import json
import sys

results = { }
for i in open(sys.argv[1]):
    r = json.loads(i)
    results.setdefault(r['tag'], {})[r['bin']] = r

if len(sys.argv) == 2:
    print "TAGS:"
    for i in results:
        print i, len(results[i]), len([v for v in results[i].values() if v['crashed']])
else:
    for b in sorted(results[sys.argv[2]].values(), key=lambda v:v['bin']):
        print ','.join(map(str, (
            b['bin'],
            int(b['crashed']),
            int(b['crash_time']) if b['crash_time'] != -1 else '',
            b['blocks_triggered'],
            b['transitions_triggered']
        )))
