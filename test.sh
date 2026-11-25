#!/bin/sh
set -eu

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
for version in 1.0 5.44.0; do
    mkdir -p "$tmp/$version/bin"
    ln -s "$(command -v perl)" "$tmp/$version/bin/perl"
done

result=$(ALL_PERL_ROOT="$tmp" ./all-perl -e 'print "ok\n";')
[ "$result" = '1.0          ok
5.44.0       ok' ]
[ "$(ALL_PERL_ROOT="$tmp" ALL_PERL_SINCE=5.40 ./all-perl -e 'print "ok\n";')" = '5.44.0       ok' ]
[ "$(ALL_PERL_ROOT="$tmp" ALL_PERL_BINS=1.0 ./all-perl -e 'print "ok\n";')" = '1.0          ok' ]
if ALL_PERL_ROOT="$tmp" ./all-perl -e 'exit 7;' >/dev/null; then
    echo 'expected nonzero status' >&2
    exit 1
fi
echo ok
