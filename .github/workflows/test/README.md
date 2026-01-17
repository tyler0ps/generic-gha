# Local GitHub Actions Testing with Act

This directory contains a Taskfile for testing GitHub Actions workflows locally using [act](https://github.com/nektos/act).

## Prerequisites

- **act**: Install via homebrew (`brew install act`) or via devbox
- **Docker**: Act runs workflows in Docker containers
- **Task**: Task runner (should already be installed in your devbox environment)

## Usage

Navigate to this directory:
```bash
cd .github/workflows/test
```

### Test Individual Services

Test a specific service:
```bash
task test:api-golang              # Test Go API service
task test:api-node                # Test Node API service
task test:client-react            # Test React client
task test:load-generator-python   # Test Python load generator
task test:api-golang-migrator     # Test database migrator
```

### Test All Services

Run the full workflow for all services:
```bash
task test:all
# or simply
task
```

### List Available Tasks

```bash
task --list
```

## How It Works

The workflow supports two modes:

### Manual Selection (workflow_dispatch)
- Each test task uses a dedicated event JSON file (e.g., `event-api-golang.json`)
- The event file specifies which service to test via the `inputs.service` parameter
- The `changes` job reads this input and sets up the matrix accordingly
- Only the selected service runs

### Automatic Detection (push/PR)
- Path filtering detects which files changed
- Only services with changes are tested
- Configured via [.github/utils/file-filters.yaml](../../utils/file-filters.yaml)

## Event Files

Each service has its own event file:
- `event-all.json` - Test all services
- `event-api-golang.json` - Test Go API
- `event-api-node.json` - Test Node API
- `event-client-react.json` - Test React client
- `event-load-generator-python.json` - Test Python service
- `event-api-golang-migrator.json` - Test database migrator

These files contain the `workflow_dispatch` inputs that simulate manual workflow triggers.

## Configuration

The Taskfile uses these variables (configurable in [Taskfile.yaml](Taskfile.yaml)):
- `ACT_CONTAINER_ARCH`: Container architecture (`linux/amd64` or `linux/arm64`)
- `ACT_PLATFORM`: Docker image for act (`catthehacker/ubuntu:act-latest`)
- `ACT_CACHE_PATH`: Cache directory (`~/.cache/act`)

## Troubleshooting

### Act Not Found
Install act:
```bash
brew install act
```

### Docker Not Running
Start Docker Desktop or Docker daemon before running tests.

### Slow First Run
The first run downloads Docker images and installs dependencies. Subsequent runs will be much faster due to caching.

### Architecture Mismatch
If you're on an M-series Mac and encountering issues:
- Change `ACT_CONTAINER_ARCH` to `linux/arm64` for native performance
- Or keep `linux/amd64` for closer parity with GitHub Actions runners (uses Rosetta 2 emulation)

### Port Conflicts
If you see port binding errors, stop any local services running on conflicting ports.

## What Gets Tested

Each service test runs:
1. **Checkout** - Clones the repository
2. **Setup Dependencies** - Installs language-specific tools (Go, Node, Python)
3. **Install Dependencies** - Runs `task install-ci` in the service directory
4. **Run Tests** - Executes `task test` in the service directory

## Benefits

- Test workflow changes before pushing to GitHub
- Debug workflow issues locally
- Faster feedback loop for CI/CD development
- No GitHub Actions minutes consumed
- Test individual services without running the full matrix
- Clean event-driven approach (no temporary files)

## GitHub UI Usage

The workflow can also be triggered manually in GitHub:
1. Go to **Actions** → **Run Tests**
2. Click **Run workflow**
3. Select a service from the dropdown (or choose "all")
4. Click **Run workflow**

This is useful for testing specific services without pushing code changes.
