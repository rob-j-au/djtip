# Git Hooks

This directory contains Git hooks that can be installed to improve code quality.

## Pre-commit Hook

The pre-commit hook automatically lints Ruby and YAML files before each commit.

### Features

- **Ruby Linting**: Runs RuboCop with auto-correction on staged `.rb` files
- **YAML Linting**: Runs yamllint on staged `.yml` and `.yaml` files
- **Auto-correction**: RuboCop automatically fixes issues where possible
- **Fail-safe**: Prevents commits if linting issues are found

### Installation

```bash
cp .git-hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Requirements

- RuboCop (installed via Gemfile)
- yamllint (install via `brew install yamllint` on macOS)

### Usage

Once installed, the hook runs automatically on every commit. If issues are found:

1. RuboCop will auto-correct what it can
2. You'll need to review and stage the corrections
3. Fix any remaining issues manually
4. Commit again

### Skipping the Hook

If you need to bypass the hook (not recommended):

```bash
git commit --no-verify
```
