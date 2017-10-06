# Mysqldump Tab parser plugin for Embulk

Embulk parser plugin for mysqldump file that dumped with the --tab option

## Overview

* **Plugin type**: parser
* **Guess supported**: no

## Configuration


## Example

```yaml
in:
  type: file
  path_prefix: /path/to/dump/users.txt
  parser:
    type: mysqldump_tab
    columns:
    - {name: id, type: long}
    - {name: name, type: string}
    - {name: email, type: string}
out:
  type: stdout
```


```
$ embulk gem install embulk-parser-mysqldump_tab
$ embulk guess -g mysqldump_tab config.yml -o guessed.yml
```

## Build

```
$ rake
```
