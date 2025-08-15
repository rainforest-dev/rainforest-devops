# Test GitHub Actions Runners

## Test Workflow
Create a simple workflow in your repository to test the runners:

```yaml
name: Test Self-Hosted Runner
on: 
  workflow_dispatch:
  
jobs:
  test:
    runs-on: self-hosted
    steps:
      - name: Test runner
        run: |
          echo "Testing self-hosted runner"
          echo "Runner labels: self-hosted, linux, x64, prod"
          whoami
          uname -a
```

## Expected Behavior
1. When workflow is triggered, ARC will scale up a runner pod
2. Runner will execute the job
3. After completion, runner pod will be terminated
4. No persistent runners (minRunners = 0)

## Current Configuration
- **minRunners**: 0 (scale to zero when idle)
- **maxRunners**: 5 (max concurrent runners)
- **Runner Image**: ghcr.io/actions/actions-runner:latest
- **Labels**: self-hosted, linux, x64, prod