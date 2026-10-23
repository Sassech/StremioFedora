# Stremio RPM Builder for Fedora

> **Stremio is now available on COPR.** There is no need to download the RPM
> from Releases anymore: the repository rebuilds automatically on every new
> upstream release.

```bash
sudo dnf remove stremio                      # the package from this repo, if installed
sudo dnf copr enable sassech/packages
sudo dnf install stremio-linux-shell         # latest release
# or
sudo dnf install stremio-linux-shell-git     # latest commit
```

Available for Fedora 44, 45 and rawhide (x86_64 and aarch64). See
[sassech/packages](https://copr.fedorainfracloud.org/coprs/sassech/packages/) and
[Sassech/copr-packages](https://github.com/Sassech/copr-packages).

The COPR package is named `stremio-linux-shell` and conflicts with the `stremio`
package built here, so remove the old one first. The command is still `stremio`.

For extra codecs and hardware decoding:

```bash
sudo dnf install ffmpeg mpv gstreamer1-vaapi libva-utils
```

## Build locally

This builder still works if you prefer a local RPM:

```bash
./docker-build.sh            # RPM in ./output/stremio-*.rpm
```

It builds [stremio-linux-shell](https://github.com/Stremio/stremio-linux-shell)
in a `fedora:44` container (Docker or Podman).
