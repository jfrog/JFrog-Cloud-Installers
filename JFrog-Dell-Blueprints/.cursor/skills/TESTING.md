# E2E Testing Strategy

## Architecture

Two test layers with different triggers and costs:

| Layer | Marker | Trigger | Runner | Cost | Time |
|---|---|---|---|---|---|
| Mock E2E | `mock_e2e` | Every PR | `ubuntu-latest` | $0 | <30s |
| E2E Tests | `e2e` | Manual (via workflow_dispatch) | `self-hosted` | ~$3 | ~30 min |

### Mock E2E

Deterministic tests using `ScriptedApiBackend` + `MockToolBackend`.
Zero API calls.  Proves the pluggable agent loop works correctly.

- **File:** `e2e_tests/test_mock_smoke.py`
- **Run:** `pytest -m mock_e2e`

### Skill E2E (REMOVED)

**Status**: Deprecated and removed as of 2026-04-17.

Per-skill e2e tests were removed because they were never run in CI
and duplicated coverage provided by e2e tests.

For e2e testing of skills, see **E2E Tests** section.

### E2E Tests

Full install-to-usage chain via Claude Code CLI in Docker.
Validates skill installation, native skill discovery, and agent execution.

- **Files:** `e2e_tests/platform/`
- **Test Cases:** `e2e_tests/platform/cases/*.yaml` (organized by plugin)
- **Run:** `pytest -m e2e`

## Adding E2E Tests for a New Plugin

Add test cases to the appropriate YAML file in `e2e_tests/platform/cases/`:

1. Choose the right file:
   - `core.yaml` - Knowledge search, linting, Docker plugin
   - `helm.yaml` - Helm plugin tests
   - `kubernetes.yaml` - Kubernetes plugin tests
   - `terraform.yaml` - Terraform plugin tests
   - `ansible.yaml` - Ansible plugin tests
   - `nativeedge.yaml` - NativeEdge plugin tests
   - `off-topic.yaml` - Guardrail tests

2. Add your test case following this format:

```yaml
- id: unique_test_id
  category: plugin_knowledge  # or blueprint_generation, etc.
  prompt: "Your test prompt"
  deterministic_checks:
    response_contains:
      - "expected string"
    response_not_contains:
      - "unexpected string"
    min_length: 100  # optional
    max_latency_ms: 60000
  eval:
    criteria:
      - "What the LLM judge should check"
    min_score: 0.7
```

3. Run locally:

```bash
pytest -m e2e -k "your_test_id" -v
```

## Cost Tracking

E2E tests automatically track and report token usage and estimated costs at the end of each test run.

The test summary includes a **Cost Summary** section showing:
- Per-test input/output token counts
- Number of API rounds/turns per test
- Estimated cost per test (based on Sonnet 4 Bedrock pricing: $3/M input, $15/M output)
- Total tokens and estimated cost across all tests

Example output:
```
-------------------------------- Cost Summary ----------------------------------
  Total: 45,231 input + 12,456 output tokens  |  Est. $0.3223
  Pricing: $3/M input, $15/M output (Sonnet 4 Bedrock)

  Test ID                        In Tok   Out Tok  Rounds    Est.$  Note
  ----------------------------  --------  --------  ------  --------  ----
  helm_full_structure              8,234     2,145       3   $0.0569  (claude -p)
  k8s_resource_from_yaml          12,456     3,234       4   $0.0861
  ...
```

**Note**: Platform tests (using Claude Code CLI) may show more accurate costs including prompt caching.

## Key Files

| File | Purpose |
|---|---|
| `conftest.py` | Fixtures: `bpa_client_factory`, `bpa_client`, `judge`, `runner`; Cost tracking hooks |
| `e2e_tests/agent/` | Pluggable agent loop: protocols, runtime, backends |
| `e2e_tests/test_mock_smoke.py` | Mock smoke tests (4 cases) |
| `e2e_tests/platform/` | E2E tests (Dockerfiles, test cases, runner) |
| `e2e_tests/platform/cases/` | E2E test cases organized by plugin (7 YAML files) |
| `pyproject.toml` | Pytest markers: `mock_e2e`, `e2e` |
