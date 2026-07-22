#!/bin/bash
# ============================================================================
# SETUP DO AMBIENTE NOHA — a pessoa cola UMA vez no Terminal e nunca mais.
# Baixa TODAS as contas (clientes) a que a pessoa tem acesso no GitHub.
# Cada conta já vem com os 10 agentes dentro — é auto-suficiente.
#
# Uso:  bash <(curl -fsSL https://raw.githubusercontent.com/NohaConnect/noha-os/main/bin/noha-setup.sh)
#   ou: bash ~/Noha/os/bin/noha-setup.sh   (para atualizar)
# ============================================================================
set -e

echo "🌊 Preparando o ambiente Noha..."

command -v git >/dev/null || { echo "❌ Falta o git. Rode: xcode-select --install"; exit 1; }
command -v gh  >/dev/null || { echo "❌ Falta o GitHub CLI. Rode: brew install gh  → depois: gh auth login"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "❌ Faça login no GitHub primeiro: gh auth login"; exit 1; }

mkdir -p "$HOME/Noha/contas"

# 1) Cérebro (noha-os) — SÓ para quem administra o sistema (dono).
#    O time não tem acesso, e não precisa: os agentes viajam dentro de cada conta.
TEM_OS=0
if [ -d "$HOME/Noha/os/.git" ]; then
  git -C "$HOME/Noha/os" pull -q 2>/dev/null && TEM_OS=1 || true
elif gh repo view NohaConnect/noha-os >/dev/null 2>&1; then
  git clone -q "https://github.com/NohaConnect/noha-os.git" "$HOME/Noha/os" && TEM_OS=1
fi

# 2) Todas as contas (clientes) que VOCÊ tem acesso — os convites do GitHub definem isso.
N=0
for repo in $(gh repo list NohaConnect --limit 200 --json name --jq '.[].name' | grep '^conta-'); do
  pasta="$HOME/Noha/contas/${repo#conta-}"
  if [ -d "$pasta/.git" ]; then
    git -C "$pasta" pull -q 2>/dev/null || echo "  ⚠️  $repo: pull falhou (resolver depois)"
  else
    git clone -q "https://github.com/NohaConnect/$repo.git" "$pasta" && echo "  ✅ $repo" && N=$((N+1))
  fi
done

# 3) Ambiente-raiz (agentes em ~/Noha) — só monta se você é dono e tem o noha-os.
if [ "$TEM_OS" = "1" ]; then
  mkdir -p "$HOME/Noha/.claude/agents" "$HOME/Noha/.claude/skills"
  cp "$HOME/Noha/os/agentes/"*.md "$HOME/Noha/.claude/agents/"
  cp "$HOME/Noha/os/agentes/auditores/"*.md "$HOME/Noha/.claude/agents/" 2>/dev/null || true
  cp -R "$HOME/Noha/os/skills/universais/." "$HOME/Noha/.claude/skills/" 2>/dev/null || true
  cp "$HOME/Noha/os/templates/ambiente/CLAUDE.md" "$HOME/Noha/CLAUDE.md"
  echo ""
  echo "✅ Ambiente completo pronto em ~/Noha (você tem o cérebro noha-os)."
  echo "   Abra o Claude Code em ~/Noha e converse — todos os agentes e contas estão ali."
else
  echo ""
  echo "✅ Suas contas estão em ~/Noha/contas/ (baixadas as que você tem acesso)."
  echo "   Abra o Claude Code DENTRO da pasta do cliente, ex:  ~/Noha/contas/biazzi"
  echo "   Os 10 agentes já estão lá dentro — é só conversar."
fi
