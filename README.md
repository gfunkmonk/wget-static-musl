# wget-static-musl

This is a static version of wget built with musl via a simple workflow.
I built this because statically linking wget is a surprisingly hard task. If you run `./wget --version` you will see it is almost identical to the version shipped by Ubuntu or Debian — it is a proof of concept.
Just note that statically linking against musl is easier than against glibc.
Also note that the fewer dependencies a piece of software has, the easier it is to link statically; with a large number of dependencies, static linking can become impossible.
