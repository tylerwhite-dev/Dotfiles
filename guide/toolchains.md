# toolchains

## nvm

install latest LTS NodeJS

```bash
nvm install --lts
nvm use node --lts

nvm --version
node -v
npm -v
```

## rustup

install latest stable rust+cargo

```bash
rustup toolchain install stable

rustc -V
cargo -V
rustup show
```

## uv

Run a standalone Python script without loading the current project's dependencies:

```bash
uv run --no-project script.py
```

If the script needs a package, supply it for this run:

```bash
uv run --no-project --with requests script.py
```

## SDKMAN

look at available java

```bash
sdk list java
```

```bash
sdk install java [version]-[distro]
```
also you can install languages, build systems, frameworks

- kotlin
- scala
- gradle
- maven
