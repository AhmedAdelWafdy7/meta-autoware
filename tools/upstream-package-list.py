#!/usr/bin/env python3
"""List the ROS packages in an Autoware container image, without pulling it.

Streams each layer of the image's arm64 manifest from the registry and keeps the names under
share/ament_index/resource_index/packages/, which is what `ros2 pkg list` reads. Whiteouts are
applied, so a package removed by a later layer is not listed.

Usage:
    tools/upstream-package-list.py <image:tag> <output.json>
    tools/upstream-package-list.py ghcr.io/autowarefoundation/autoware:universe-jazzy-2.0.0 \
        results/upstream/universe-jazzy-2.0.0.json
"""
import io
import json
import sys
import tarfile
import urllib.request
from pathlib import PurePosixPath

INDEX = "share/ament_index/resource_index/packages/"
ATTEMPTS = 10
ACCEPT = ", ".join([
    "application/vnd.oci.image.index.v1+json",
    "application/vnd.docker.distribution.manifest.list.v2+json",
    "application/vnd.oci.image.manifest.v1+json",
    "application/vnd.docker.distribution.manifest.v2+json",
])


def get(url, token, accept=ACCEPT):
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}", "Accept": accept})
    return urllib.request.urlopen(req)


def get_token(registry, repo):
    with urllib.request.urlopen(f"https://{registry}/token?scope=repository:{repo}:pull") as r:
        return json.load(r)["token"]


class ResumingBlob(io.RawIOBase):
    """A blob download that reconnects from the current offset when the connection drops."""

    def __init__(self, url, size, registry, repo):
        self.url, self.size, self.registry, self.repo = url, size, registry, repo
        self.offset = 0
        self.response = None

    def readable(self):
        return True

    def readinto(self, buffer):
        for attempt in range(1, ATTEMPTS + 1):
            try:
                if self.response is None:
                    # anonymous tokens are short-lived, and a 3 GB layer takes longer
                    req = urllib.request.Request(self.url, headers={
                        "Authorization": f"Bearer {get_token(self.registry, self.repo)}",
                        "Range": f"bytes={self.offset}-",
                    })
                    self.response = urllib.request.urlopen(req)
                    if self.offset and self.response.status != 206:
                        sys.exit(f"error: {self.url} ignored the Range request; cannot resume")
                n = self.response.readinto(buffer)
                if n == 0 and self.offset < self.size:
                    # the registry can close the connection cleanly before the end
                    raise ConnectionError("closed early")
                self.offset += n
                return n
            except OSError as e:
                if self.response is not None:
                    self.response.close()
                self.response = None
                if attempt == ATTEMPTS:
                    raise
                print(f"  connection lost at {self.offset // 1_000_000} MB ({e}), resuming",
                      file=sys.stderr)

    def close(self):
        if self.response is not None:
            self.response.close()
        super().close()


def read_layer(url, size, registry, repo):
    """A layer's whiteouts and package index entries, in order; read whole before applying."""
    changes = []
    with ResumingBlob(url, size, registry, repo) as blob, \
            tarfile.open(fileobj=io.BufferedReader(blob, 1 << 20), mode="r|gz") as tar:
        for member in tar:
            path = PurePosixPath("/" + member.name.lstrip("./"))
            name = path.name
            if name == ".wh..wh..opq":
                changes.append(("opaque", str(path.parent), None))
            elif name.startswith(".wh."):
                changes.append(("whiteout", str(path.parent / name[4:]), None))
            elif str(path.parent).endswith(INDEX.rstrip("/")) and not member.isdir():
                changes.append(("add", str(path), name))
    return changes


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    image, out = sys.argv[1], sys.argv[2]
    registry, rest = image.split("/", 1)
    repo, tag = rest.rsplit(":", 1)

    token = get_token(registry, repo)
    base = f"https://{registry}/v2/{repo}"

    with get(f"{base}/manifests/{tag}", token) as r:
        index_digest = r.headers["Docker-Content-Digest"]
        index = json.load(r)
    arm64 = [m for m in index["manifests"] if m.get("platform", {}).get("architecture") == "arm64"]
    if not arm64:
        sys.exit(f"error: {image} has no arm64 manifest")
    manifest_digest = arm64[0]["digest"]
    with get(f"{base}/manifests/{manifest_digest}", token) as r:
        layers = json.load(r)["layers"]

    # path of each package's index entry -> package name
    entries = {}
    for n, layer in enumerate(layers, 1):
        print(f"layer {n}/{len(layers)} ({layer['size'] // 1_000_000} MB)", file=sys.stderr)
        changes = read_layer(f"{base}/blobs/{layer['digest']}", layer["size"], registry, repo)
        for kind, path, name in changes:
            if kind == "opaque":
                entries = {p: v for p, v in entries.items() if not p.startswith(path + "/")}
            elif kind == "whiteout":
                entries = {p: v for p, v in entries.items()
                           if p != path and not p.startswith(path + "/")}
            else:
                entries[path] = name

    packages = {}
    for path, name in entries.items():
        prefix = path.split("/" + INDEX)[0]
        packages.setdefault(name, prefix)

    result = {
        "image": image,
        "index_digest": index_digest,
        "arm64_manifest_digest": manifest_digest,
        "package_count": len(packages),
        "packages": dict(sorted(packages.items())),
    }
    with open(out, "w") as f:
        json.dump(result, f, indent=2)
        f.write("\n")
    print(f"{len(packages)} packages -> {out}", file=sys.stderr)


if __name__ == "__main__":
    main()
