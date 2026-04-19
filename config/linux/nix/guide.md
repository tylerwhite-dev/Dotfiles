# Info
[pkgs](https://search.nixos.org/packages)


# Install nix

## Multi-user (recommended)
```
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
```

## Single-user installation
```
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon
```

## Ensure nix is installed correctly

- restart shell
- run `nix --version`

# Manage pkgs

## Show installed
```
nix-env -q
```

## Install

### From .nix file
```
nix-env -f [pkgsfile].nix -i
```

### As attribute
```
nix-env -iA nixpkgs.[pkg]
```

### By name (slow)
```
nix-env -i [pkg]
```

## Delete
```
nix-env -e [pkg]
```

## Update
```
nix-env -u
```

# Nix-shell

# Channels

## Add "unstable"

check current channels
```
nix-channel --list
```

add nixpkgs-unstable
```
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
```