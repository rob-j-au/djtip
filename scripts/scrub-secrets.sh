#!/bin/bash
# Script to scrub secrets from git history
# WARNING: This rewrites git history - use with caution!

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${RED}⚠️  WARNING: This script will rewrite git history!${NC}"
echo -e "${YELLOW}This operation cannot be undone easily.${NC}"
echo ""
echo "This will remove the following hardcoded secrets from ALL commits:"
echo "  - ArgoCD password: X7Ff-siflLm4b7yo"
echo "  - ArgoCD password: SWCTPRjmtRPQ24VB"
echo "  - Grafana password: admin"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo -e "\n${GREEN}Step 1: Creating backup branch...${NC}"
git branch backup-before-scrub-$(date +%Y%m%d-%H%M%S)

echo -e "\n${GREEN}Step 2: Installing git-filter-repo (if needed)...${NC}"
if ! command -v git-filter-repo &> /dev/null; then
    echo "Installing git-filter-repo via pip..."
    pip3 install git-filter-repo
fi

echo -e "\n${GREEN}Step 3: Creating replacement file...${NC}"
cat > /tmp/git-secrets-replace.txt << 'EOF'
X7Ff-siflLm4b7yo==>***REMOVED***
SWCTPRjmtRPQ24VB==>***REMOVED***
adminPassword: admin==>adminPassword: ""
EOF

echo -e "\n${GREEN}Step 4: Running git-filter-repo to scrub secrets...${NC}"
git filter-repo --replace-text /tmp/git-secrets-replace.txt --force

echo -e "\n${GREEN}Step 5: Cleaning up...${NC}"
rm /tmp/git-secrets-replace.txt

echo -e "\n${GREEN}✅ Secrets have been scrubbed from git history!${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT NEXT STEPS:${NC}"
echo "1. Review the changes: git log --all --oneline"
echo "2. Force push to remote: git push origin --force --all"
echo "3. Force push tags: git push origin --force --tags"
echo "4. Notify all collaborators to re-clone the repository"
echo ""
echo -e "${RED}⚠️  All collaborators must delete their local clones and re-clone!${NC}"
echo ""
echo "Backup branch created: backup-before-scrub-*"
echo "You can restore from backup if needed: git reset --hard backup-before-scrub-*"
