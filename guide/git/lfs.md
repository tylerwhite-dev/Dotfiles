# Git LFS

## Install

```
git lfs install
```

## Track file types

```
git lfs track "*.psd"
git lfs track "*.zip"
```

Or manually in `.gitattributes`:

```
*.png filter=lfs diff=lfs merge=lfs
*.zip filter=lfs diff=lfs merge=lfs
```

## Migrate existing files

Convert already committed files to LFS (rewrites history):

```
git lfs migrate import --include="path/to/files/*.png" --everything
```

After migration, force-push:

```
git push --force-with-lease origin main
```

## Useful commands

```
git lfs ls-files                          # list tracked files
git lfs status                            # show LFS status
git lfs pull                              # pull LFS files
git lfs checkout                          # checkout LFS files
git lfs env                               # show LFS environment
```
