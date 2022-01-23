# helper target modified from: https://stackoverflow.com/a/59087509
help:
	@grep -B1 -h -E "^[a-zA-Z0-9_-]+\:([^\=]|$$)" $(MAKEFILE_LIST) \
     | grep -v -- -- \
     | sed 'N;s/\n/###/' \
     | sed -n 's/^# \(.*\)###\(.*\):.*/\2###\1/p' \
     | column -t  -s '###' \
     | grep -v '^help '

