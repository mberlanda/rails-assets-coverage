# Rails Assets Coverage

The purpose of this script is to find which assets are used by a Rails app.
I tried to not use any dependency in order to make it runnable on every UNIX machine without installing perl package manager.
This should be intended as a proof of concept for a future ruby gem:

### Usage


If you don't have cpanminus installed:
```
  $ [VERBOSE=1|OUTPUT=1|] perl rails_assets_coverage.pl [RAILS_ROOT|.]
```
Otherwise
```
  $ [VERBOSE=1|OUTPUT=1|] perl -Ilib scripts/rails_assets.pl [RAILS_ROOT|.]
```

Options:
- `RAILS_ROOT` arg is the path to rails application you want to analyze.
- with `VERBOSE` env var the script will print on STDOOUT the result of the parsing activity.
- with `OUTPUT` env var the script will generate an assets_status.yml report inside your `RAILS_ROOT`.


### Setup

For a proper usage you should install `cpanminus` and `Module::Builder` perl module:

```
  $ sudo [apt|brew] install cpanminus
  $ sudo cpanm -i Module::Builder
  $ perl Build.PL
  $ ./Build installdeps
  $ ./Build test
  $ ./Build install
```

### Notes

This repo was born as a [gist](https://gist.github.com/mberlanda/ccabea23498d32f27f4591eb4d78a4be). I would keep it alive for discussions on this topic.

Any fork, star, issue or pull requests are welcome!
