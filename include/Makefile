# $(call print_var,my_variable_name)
print_var=$(info $(info $1 has $(words $($1)) values:) $(foreach F,$($1), $(info - $F)))

### also consider something like (using ascii 30 Record Separator)
### sed 'N;s/\n/\x1e/' | sed -n 's/^# \(.*\)\x1e\(.*\):.*/\2 --- \1/p' | column -t -s ' --- '
### may reduce readability during debug though.

# helper target modified from: https://stackoverflow.com/a/59087509
### note this will ONLY pick up entries with #-comments,
### so if it's run on a Makefile with no commented entries,
### make will show something like 
### make: *** [.../Makefile:11: help] Error 1
### to make a comment invisible to help, use ###
help:
	@grep -B1 -h -E "^[a-zA-Z0-9_-]+\:([^\=]|$$)" $(MAKEFILE_LIST) \
     | grep -v -- -- \
     | sed 'N;s/\n/###/' \
     | sed -n 's/^# \(.*\)###\(.*\):.*/\2###\1/p' \
     | column -t  -s '###' \
     | grep -v '^help '

define render_jsonnet
	test -d $(dir $2) || mkdir -p $(dir $2)
	jsonnet $1 | jq -S | tee $2
endef

define generate_ts_interface
	test -d $(dir $2) || mkdir -p $(dir $2)
	cat $1 | json2ts | cat | tee $2
endef

