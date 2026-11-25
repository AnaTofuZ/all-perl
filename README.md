# all-perl

Run the same program with Perl releases from the 1.x series through 5.44. The
image contains one final release from each historical series and each stable
Perl 5 branch. `versions.txt` is the exact release and source list; development
releases and intermediate patch releases are outside this first version's scope.

```sh
docker build -t all-perl .
docker run --rm all-perl -e 'print "hello\n";'
docker run --rm -e ALL_PERL_SINCE=5.20 all-perl -e 'print "$]\\n";'
docker run --rm -e ALL_PERL_BINS='1.0 5.44.0' all-perl -e 'print "ok\n";'
```

To try a smaller image while developing:

```sh
docker build --build-arg VERSIONS='5.44.0' -t all-perl:latest-only .
```

The command prints a label for each Perl, followed by combined standard output
and error. It exits with status 1 if any selected Perl fails, or 2 if none match.
Older versions may reject modern syntax; use a common subset when comparing
behavior. Building the full image downloads and compiles all listed releases, so it
can take a long time.

Sources: [patched Perl 1.0](https://github.com/AnaTofuZ/Perl-1.0),
[historical Perl archive](https://mirrors.develooper.com/perl/historical-perl/),
[CPAN Perl source](https://www.cpan.org/src/), and
[ruby/all-ruby](https://github.com/ruby/all-ruby) for the interface idea.
