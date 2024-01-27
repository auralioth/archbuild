# Usage

- The software is first built from the `PKGBUILD` file defined in the folder. If it does not exist, it will be built from `AUR`.

- If your `commit` contains `[no build]` then the whole build jobs will not be triggered.

- If your `commit` contains `[no rel]` then the packages will not be released.

# Problems

- [ ] Currently the `build-aur-action` can only handle the case where a `PKGBUILD` file builds a software package. If there is a one-to-many situation, it can only be packaged separately.
