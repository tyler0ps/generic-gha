# Build-Push Workflow Testing with Act

This directory contains local testing setup for the `build-push.yaml` workflow using [act](https://github.com/nektos/act).

## Overview

The build-push workflow supports three trigger types:
1. **Tag push** (production) - Triggered by semantic version tags
2. **Workflow dispatch** (manual) - Manual trigger with optional version
3. **Push to main** (staging) - Triggered by changes to services on main branch

## Prerequisites

- [act](https://github.com/nektos/act) installed
- [Task](https://taskfile.dev) installed
- Docker running

## Test Cases

### 1. Tag-Based Triggers (Production Builds)

Simulates pushing a version tag to trigger a production build.

```bash
# Test Go service tag
task trigger-tag-golang

# Test Node service tag
task trigger-tag-node

# Test Python service tag
task trigger-tag-python

# Run all tag tests
task test-tags
```

**Event Payloads:**
- [tag.json](tag.json) - `services/go/api-golang@1.0.1`
- [tag-node.json](tag-node.json) - `services/node/api-node@2.1.0`
- [tag-python.json](tag-python.json) - `services/python/load-generator-python@1.2.3`

**Expected Behavior:**
- Environment: `production`
- Services: Extracted from tag name (e.g., `services/go/api-golang`)
- Version: Uses production versioning strategy

### 2. Manual Triggers (Workflow Dispatch)

Simulates manual workflow dispatch with and without explicit version.

```bash
# Test with explicit version provided
task trigger-manual-with-version

# Test with auto-generated version
task trigger-manual-no-version

# Run all manual trigger tests
task test-manual
```

**Event Payloads:**
- [workflow-dispatch.json](workflow-dispatch.json) - With version `local-act` for `services/go/api-golang`
- [workflow-dispatch-no-version.json](workflow-dispatch-no-version.json) - Without version for `services/react/client-react`

**Expected Behavior:**
- Environment: `staging`
- Services: From input parameter
- Version:
  - With version: Uses provided version
  - Without version: Auto-generates using `git describe`

### 3. Push to Main Branch (Staging Builds)

Simulates pushing changes to main branch that affect services.

```bash
task trigger-push-main
```

**Event Payload:**
- [push-main.json](push-main.json) - Changes to `services/go/api-golang`

**Expected Behavior:**
- Environment: `staging`
- Services: Detected by `dorny/paths-filter` based on changed files
- Version: Auto-generates extended version using `git describe`

## Run All Tests

Execute all test scenarios sequentially:

```bash
task test-all
```

This will run:
1. Tag event test (production)
2. Manual trigger with version
3. Manual trigger without version
4. Push to main (staging)

## Test Scenarios Coverage

| Scenario | Trigger Type | Environment | Version Strategy | Event File |
|----------|-------------|-------------|------------------|------------|
| Production deployment | Tag | production | From tag name | tag.json |
| Manual prod-like build | Workflow dispatch | staging | Manual input | workflow-dispatch.json |
| Auto-versioned manual | Workflow dispatch | staging | Auto-generated | workflow-dispatch-no-version.json |
| Staging deployment | Push to main | staging | Extended auto | push-main.json |
| Multi-service prod | Tag | production | From tag name | tag-node.json, tag-python.json |

## Customizing Tests

### Modify Event Payloads

Edit the JSON files to test different scenarios:

```json
// workflow-dispatch.json - Change service or version
{
    "inputs": {
        "service": "services/python/load-generator-python",
        "version": "v2.0.0-test"
    }
}

// tag.json - Change tag version
{
    "ref": "refs/tags/services/go/api-golang@2.0.0",
    "ref_type": "tag"
}
```

### Environment Variables

Modify in [Taskfile.yaml](Taskfile.yaml):

```yaml
env:
  ACT_CONTAINER_ARCH: linux/arm64  # or linux/amd64
  ACT_PLATFORM: ubuntu-latest=catthehacker/ubuntu:act-latest
```

## Troubleshooting

### Act Cache Issues
```bash
# Clear act cache
rm -rf ~/.cache/act
```

### Platform Issues
```bash
# For M1/M2 Macs, use arm64
ACT_CONTAINER_ARCH=linux/arm64

# For Intel Macs/Linux, use amd64
ACT_CONTAINER_ARCH=linux/amd64
```

### Verbose Output
Add `-v` flag to any task:
```bash
task trigger-tag-golang -- -v
```

## Notes

- The workflow uses `dorny/paths-filter` which requires the `.github/utils/file-filters.yaml` file
- Docker build steps are commented out by default to speed up testing
- The `ACT` environment variable is set by act and used to skip Docker Hub login during local testing
