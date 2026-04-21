# Info
search [pkgs](https://search.nixos.org/packages)

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

# Nix-env

## Show installed
```bash
nix-env -q
```

## Install by attribute

```bash
nix-env -iA nixpkgs.[pkg]
```


## Install from nix file
```bash
nix-env -f [pkgsfile].nix -i
```


## Remove
```bash
nix-env -e [pkg]
```


# Nix-channel
check current channels
```bash
nix-channel --list
```

add nixpkgs-unstable (used by default in nix)
```bash
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
```