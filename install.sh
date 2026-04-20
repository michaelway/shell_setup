#!/bin/bash
set -e

# =============================================================================
# Personal Setup Script
# Installs and configures tools via micromamba (conda-forge) and uv.
# Safe to re-run — all steps are idempotent.
# =============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Personal Setup Script ==="
echo

# =============================================================================
# uv — fast Python package/project manager
# =============================================================================
echo -e "${BLUE}Checking for uv...${NC}"
if ! command -v uv &> /dev/null; then
    echo -e "${YELLOW}uv not found. Installing...${NC}"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    echo -e "${GREEN}uv installed successfully${NC}"
else
    echo -e "${GREEN}uv already installed${NC}"
fi
echo

# =============================================================================
# micromamba — minimal conda-compatible package manager
# =============================================================================
echo -e "${BLUE}Checking for micromamba...${NC}"
MICROMAMBA_CMD="$(command -v micromamba || true)"
if [ -z "$MICROMAMBA_CMD" ]; then
    echo -e "${YELLOW}micromamba not found. Installing...${NC}"
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj -C "$INSTALL_DIR" bin/micromamba
    MICROMAMBA_CMD="$INSTALL_DIR/micromamba"
    export PATH="$INSTALL_DIR:$PATH"
    echo -e "${GREEN}micromamba installed at $MICROMAMBA_CMD${NC}"
else
    echo -e "${GREEN}micromamba already installed at $MICROMAMBA_CMD${NC}"
fi
echo

mkdir -p ~/.local/bin

# Activate micromamba in the current shell so subsequent installs work
eval "$("$MICROMAMBA_CMD" shell hook --shell bash)"

# Initialise the base environment prefix if it doesn't exist yet
echo -e "${BLUE}Setting up micromamba base environment...${NC}"
if ! "$MICROMAMBA_CMD" env list | grep -q "base"; then
    echo -e "${YELLOW}Initializing micromamba base...${NC}"
    "$MICROMAMBA_CMD" shell init --shell=bash --prefix="$HOME/micromamba"
fi
echo

# =============================================================================
# CLI tools via micromamba (conda-forge / bioconda)
# =============================================================================
echo -e "${BLUE}Installing CLI tools via micromamba...${NC}"

# Keys are the command names; values are the conda package names where they differ.
declare -A TOOL_PACKAGES=(
    [git]="git"
    [tmux]="tmux"
    [htop]="htop"
    [jq]="jq"
    [yq]="yq"
    [fd]="fd-find"
    [shellcheck]="shellcheck"
    [shfmt]="go-shfmt"
    [direnv]="direnv"
    [starship]="starship"
    [zoxide]="zoxide"
    [bat]="bat"
    [exa]="exa"
    [bedtools]="bedtools"
    [samtools]="samtools"
    [bcftools]="bcftools"
    [agat]="agat"
    [miniprot]="miniprot"
    [minimap2]="minimap2"
    [diamond]="diamond"
    [btop]="btop"
    [fzf]="fzf"
    [ncdu]="ncdu"
    [broot]="broot"
    [tldr]="tldr"
    [navi]="navi"
    [seqkit]="seqkit"
    [zellij]="zellij"
    [micro]="micro"
    [pigz]="pigz"
    [rsync]="rsync"
    [screen]="screen"
    [tabix]="tabix"
    [rg]="ripgrep"
    [atuin]="atuin"
    [aria2c]="aria2"
)

for cli in "${!TOOL_PACKAGES[@]}"; do
    package_name="${TOOL_PACKAGES[$cli]}"
    if command -v "$cli" &> /dev/null; then
        echo -e "${GREEN}${cli} already on PATH, skipping${NC}"
    elif "$MICROMAMBA_CMD" list -n base | grep -qE "^${package_name}[[:space:]]"; then
        echo -e "${GREEN}${package_name} already installed${NC}"
    else
        echo -e "${YELLOW}Installing ${package_name} (${cli})...${NC}"
        "$MICROMAMBA_CMD" install -n base -y -c conda-forge -c bioconda "$package_name"
        echo -e "${GREEN}${package_name} installed${NC}"
    fi
done
echo

# =============================================================================
# SSH key setup
# =============================================================================
echo -e "${BLUE}Setting up SSH keys...${NC}"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    echo -e "${YELLOW}Generating SSH key pair...${NC}"
    ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "$USER@$(hostname)"
    echo -e "${GREEN}Created SSH key at ~/.ssh/id_ed25519${NC}"
else
    echo -e "${YELLOW}SSH key already exists at ~/.ssh/id_ed25519${NC}"
fi

if [ -n "${SSH_REMOTE_HOST:-}" ]; then
    SSH_REMOTE_USER="${SSH_REMOTE_USER:-$USER}"
    SSH_REMOTE_PORT="${SSH_REMOTE_PORT:-22}"
    if command -v ssh-copy-id &> /dev/null; then
        echo -e "${BLUE}Copying SSH key to ${SSH_REMOTE_USER}@${SSH_REMOTE_HOST}:${SSH_REMOTE_PORT}${NC}"
        ssh-copy-id -i "$HOME/.ssh/id_ed25519.pub" -p "$SSH_REMOTE_PORT" "${SSH_REMOTE_USER}@${SSH_REMOTE_HOST}"
        echo -e "${GREEN}SSH key deployed to remote host${NC}"
    else
        echo -e "${YELLOW}ssh-copy-id not found — install openssh-client to deploy keys remotely${NC}"
    fi
else
    echo -e "${YELLOW}SSH_REMOTE_HOST not set, skipping remote key deployment${NC}"
fi
echo

# =============================================================================
# .bashrc — tool initialisations and shell config
# Appends a line only if it isn't already present (idempotent).
# =============================================================================
echo -e "${BLUE}Updating .bashrc...${NC}"
BASHRC="$HOME/.bashrc"

add_to_bashrc() {
    local line="$1"
    local header="$2"
    if ! grep -Fxq "$line" "$BASHRC"; then
        {
            echo ""
            echo "# ${header}"
            echo "$line"
        } >> "$BASHRC"
        echo -e "${GREEN}Added: ${header}${NC}"
    else
        echo -e "${YELLOW}Already present: ${header}${NC}"
    fi
}

# Remove legacy atuin env source if present from older installs
# shellcheck disable=SC2016
if grep -q '. "$HOME/.atuin/bin/env"' "$BASHRC"; then
    # shellcheck disable=SC2016
    sed -i '/\. "\$HOME\/\.atuin\/bin\/env"/d' "$BASHRC"
    echo -e "${GREEN}Removed legacy atuin env source${NC}"
fi

# Single quotes are intentional below — we want literals written into .bashrc,
# not values expanded at script-run time.
# shellcheck disable=SC2016
add_to_bashrc 'export PATH="$HOME/micromamba/bin:$PATH"'               "micromamba bin on PATH"
# shellcheck disable=SC2016
add_to_bashrc 'eval "$('"$MICROMAMBA_CMD"' run -n base atuin init bash)"' "atuin shell history"
# shellcheck disable=SC2016
add_to_bashrc 'eval "$(zoxide init bash)"'                             "zoxide smart cd"
# shellcheck disable=SC2016
add_to_bashrc 'eval "$(direnv hook bash)"'                             "direnv per-directory env"
# shellcheck disable=SC2016
add_to_bashrc 'eval "$(starship init bash)"'                           "starship prompt"
add_to_bashrc "alias ll='exa -lh --sort=modified --reverse'"           "ll alias (exa sorted by time)"
echo

# =============================================================================
# Done
# =============================================================================
echo -e "${GREEN}=== Setup complete ===${NC}"
echo
echo "Sourcing ~/.bashrc to activate changes in this session..."
# shellcheck source=/dev/null
source "$HOME/.bashrc"
echo -e "${GREEN}Done. Restart your terminal or run: source ~/.bashrc${NC}"
echo
