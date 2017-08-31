# Rails Assets Coverage

The purpose of this script is to find which assets are used by a Rails app.
I tried to not use any dependency in order to make it runnable on every UNIX machine without installing perl package manager.
This should be intended as a proof of concept for a future ruby gem:

### Usage

```
  $ [VERBOSE=1|OUTPUT=1|] perl assets_coverage.pl [RAILS_ROOT|.]
```

- If you enable `VERBOSE` env var, the result of the parsing activity will be printed on STDOUT.
- If you enable `OUTPUT` env var, this would generate an output.yml report inside your rails root.

Please note that the OUTPUT option would require one package from cpanm:

```
  $ sudo [apt|brew] install cpanminus
  $ sudo cpanm -i YAML::Dumper
```

In case you don't want to install cpanminus, it would still work for now since I copied the source of [YAML v1.23](http://search.cpan.org/dist/YAML/lib/YAML/Dumper.pod) under the [lib/](lib/) subfolder.

### Notes

This repo was born as a [gist](https://gist.github.com/mberlanda/ccabea23498d32f27f4591eb4d78a4be). I would keep it alive for discussions on this topic.

Any fork, star, issue or pull requests are welcome!
