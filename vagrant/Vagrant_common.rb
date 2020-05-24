# -*- mode: ruby -*-
# vi: set ft=ruby :

$pkey_candidate_paths = [
    "/c/Users/#{ENV['USER']}/.ssh/id_rsa",
    "C:\\Users\\#{ENV['USER']}\\.ssh\\id_rsa",
    File.join(ENV["HOME"], ".ssh", "id_rsa"),
]

def get_pkey_path()
    for candidate in $pkey_candidate_paths do
        if File.exists? candidate then
            puts("found pkey at #{candidate}")
            return candidate
        end
    end
    return nil
end

PKEY_PATH = get_pkey_path
if PKEY_PATH.nil? then
    puts("no key found! tried these:")
    for candidate in $pkey_candidate_paths do
        puts("- #{candidate}")
    end
    abort()
end

