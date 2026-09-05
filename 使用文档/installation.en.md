# Install as a Codex Skill

The repository root is the `math-modeling-library` Skill. Do not create a second copy of the method content.

## Option 1: clone into the skills directory

```powershell
$skillPath = Join-Path $env:USERPROFILE '.codex\skills\math-modeling-library'
git clone https://github.com/Strider002/math-modeling-library.git $skillPath
```

If the destination already exists, inspect it for uncommitted work before taking any action. Do not overwrite it.

## Option 2: keep one repository and create a junction

This is useful when the knowledge base lives on another drive:

```powershell
$repoPath = 'D:\数学建模\library'
$skillPath = Join-Path $env:USERPROFILE '.codex\skills\math-modeling-library'
New-Item -ItemType Junction -Path $skillPath -Target $repoPath
```

Create the junction only when `$skillPath` does not already exist.

## Verify the installation

```powershell
Get-Content -LiteralPath (Join-Path $skillPath 'SKILL.md') -TotalCount 8
& (Join-Path $skillPath 'tools\route_knowledge.ps1') -ListRoutes
```

Then test explicit invocation in Codex:

```text
Use $math-modeling-library to identify the minimum route for a time-series forecasting task.
```

## Update

After confirming that the repository has no conflicting uncommitted changes:

```powershell
git -C $repoPath pull --ff-only
& (Join-Path $repoPath 'tools\validate_library.ps1') -LibraryRoot $repoPath
```

## Boundaries

- Matching modeling tasks may trigger the skill automatically.
- The knowledge base is read-only unless the user explicitly authorizes maintenance.
- Local papers and external code in `来源资料/` do not become trusted evidence merely because they are present.
