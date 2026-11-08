# Contributing Guidelines

Thank you for contributing to **Jadwalin**! To keep the repository clean and maintainable, please follow these branching and commit conventions.

---

## 1. Branching Strategy

| Branch | Description | Target PR |
|---|---|---|
| `main` | Production-ready, stable code only. Tagged with version numbers. | Never direct commit |
| `develop` | Primary integration branch for active development. | `main` (for releases) |
| `feature/<name>` | New features (e.g. `feature/ai-krs-import`). | `develop` |
| `fix/<name>` | Bug fixes (e.g. `fix/timeline-drag-overlap`). | `develop` |
| `hotfix/<name>` | Critical production fixes branched from `main`. | `main` & `develop` |
| `chore/<name>` | Maintenance, deps, docs, refactor without feature changes. | `develop` |

### Branch Naming Rules
- Use lowercase with hyphens: `feature/calendar-view`, `fix/chat-scroll-bug`.
- Do not use underscores or uppercase letters.
- Keep branch names short and descriptive.

---

## 2. Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```text
<type>(<optional scope>): <description in imperative mood>

[optional body]

[optional footer(s)]
```

### Types
- `feat`: A new feature (user-facing).
- `fix`: A bug fix.
- `docs`: Documentation only changes (`README.md`, comments).
- `style`: Changes that do not affect code logic (formatting, white-space, semicolon).
- `refactor`: Code change that neither fixes a bug nor adds a feature.
- `perf`: A code change that improves performance.
- `test`: Adding missing tests or correcting existing tests.
- `chore`: Build process, dependencies, tooling changes (`pubspec`, gitignore, env).

### Good Examples
- `feat(chat): support swipe-to-delete chat history with confirmation`
- `fix(timeline): resolve drag offset calculation on high-DPI screens`
- `chore(deps): bump flutter SDK to 3.8.1`
- `docs(readme): add build_runner setup guide`

### Bad Examples
- `update stuff` ❌ (no type, vague)
- `feat: Fixed a bug` ❌ (wrong type for fix, past tense)
- `WIP` ❌ (uninformative)

---

## 3. Pull Request Checklist

Before submitting a PR to `develop`:
- [ ] Run `flutter analyze` — ensure **0 issues found**.
- [ ] Run `flutter test` (if tests exist).
- [ ] Verify no secrets (`.env`, `env.g.dart`) are staged.
- [ ] Ensure commit messages follow Conventional Commits.
- [ ] Use the PR template provided in `.github/PULL_REQUEST_TEMPLATE.md`.
