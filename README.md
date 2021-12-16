## Drupal Bootstrap Pro

Easily download and run the latest Drupal locally through the help of make commands.

Use this project to quickly test out a module or to contribute a patch.

# Requirements

- Unix or Unix-like environment
- PHP >= 7.3
- Composer 2

# How to use it

Run `make` or `make help`

# Quick start

`make init`

# 🍶 Pro Tip

Running `make` only works in the directory of the `Makefile`. However, you can add a Unix shell alias:

`alias sake='make -C $(git rev-parse --show-toplevel)'`

And now you can use `sake` instead of `make` anywhere in your project (exception would be in git submodules).
