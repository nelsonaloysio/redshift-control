redshift-control
---

Simple bash script to interact with redshift
and adjust screen colors and brightness.

Requires setting the "LAT_LONG" var in file.

```
usage: redshift-control {option} [--nocolor]
options:
  start   set automatic settings
  pause   interrupt or activate redshift
  stop    reset brightness and colors
  up      brighten monitor screens
  down    dim monitor screens
  force   instant night colors
```