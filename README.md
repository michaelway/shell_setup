# shell_setup

Setup script that installs and configures my favourite CLI tools via [micromamba](https://mamba.readthedocs.io/) (conda-forge) and [uv](https://github.com/astral-sh/uv). Works without sudo privileges. Safe to re-run — all steps are idempotent.

## Quick install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/michaelway/shell_setup/main/install.sh)
```

## What it installs

- **uv** — fast Python package/project manager
- **micromamba** — minimal conda-compatible package manager
- **CLI tools** via conda-forge/bioconda: `git`, `tmux`, `htop`, `jq`, `yq`, `fd`, `fzf`, `bat`, `exa`, `ripgrep`, `zoxide`, `starship`, `direnv`, `atuin`, `shellcheck`, `shfmt`, `ncdu`, `broot`, `tldr`, `navi`, `zellij`, `micro`, `pigz`, `rsync`, `screen`, `aria2`, and bioinformatics tools (`bedtools`, `samtools`, `bcftools`, `agat`, `miniprot`, `minimap2`, `diamond`, `seqkit`, `tabix`)
- **SSH key** (`~/.ssh/id_ed25519`) if not already present
- **`.bashrc` entries** for micromamba, atuin, zoxide, direnv, starship, and an `ll` alias

