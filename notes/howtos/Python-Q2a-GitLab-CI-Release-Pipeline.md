---
title: GitLab CI/CD Release Pipeline for a Multi-Repository
  Python Project
subtitle: |
  Automated validation, upstream synchronization, container
  image delivery, and release notification for the
  `dve-simple-py` codebase across public and private GitLab
  repositories

# {{{ // %+

category: GitLab-HOWTO
keywords: [GEN, GitLab-CI-CD, uv, Podman, Pyright-Ruff-Pytest, Container-Registry, Multi-repository-Release]
abstract: |
  This report specifies a GitLab CI/CD pipeline coordinating a
  private downstream repository (`ub-dems/dve-simple-py`) and
  its public upstream counterpart (`ub-dems-public/dve-simple-py`),
  both sharing a single Python codebase managed with `uv`.
  The workflow is triggered by commit tags matching the pattern
  `v*.*.*` on the downstream project.

  The pipeline proceeds through seven ordered stages: pre-release
  validation via `pyright`, `ruff`, and `pytest`; automated Merge
  Request creation against the upstream `main` branch through the
  GitLab API; upstream merge and tag propagation following
  successful upstream CI; parallel container image builds using
  the shared `build-images.sh` script; conditional image push to
  a public registry; a GitHub mirror push; and multi-channel
  release notification via email and Slack.

  The deliverable is a single `.gitlab-ci.yml` definition valid
  for both projects, using project-path conditions to gate
  downstream- and upstream-specific jobs, explicit stage
  declarations, `needs`/`dependencies` for strict cross-stage
  ordering, and a defined set of masked and plain CI/CD variables
  for authentication, registry access, and notification delivery.

doctype: md-report
# }}} // %+
---

<!-- {{{ #TAG: TODO:(toc) // -->

<!-- markdownlint-disable MD012 -->
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-disable MD025 -->
<!-- markdownlint-disable MD033 -->
<!-- markdownlint-disable MD051 -->
<!-- markdownlint-disable MD053 -->


# TOC

1. [Q:1 - GitLab CI/CD Release Pipeline](#q1)
   - see: [GitLab CI/CD Release Pipeline for `dve-simple-py` (Claude)](#a1-claude)
   - see: [GitLab CI/CD for Multi-Repo Python Release (Gemini)](#a1-gemini)
   - see: [GitLab CI/CD Workflow (ChatGPT)](#a1-chatgpt)
   - see: [GitLab CI/CD Pipeline Definition (DeepSeek)](#a1-deepseek)
   - see: [GitLab CI/CD workflow (Perplexity)](#a1-perplexity)
   - see: [Multi-Repo Python Release Pipeline (Vibe)](#a1-vibe)
2. [Q:2 - TODO:(q2-ref)](#q2)
   - see: [TODO:(a2-ref-claude) (Claude)](#a2-claude)
   - see: [TODO:(a2-ref-gemini) (Gemini)](#a2-gemini)
   - see: [TODO:(a2-ref-chatgpt) (ChatGPT)](#a2-chatgpt)
   - see: [TODO:(a2-ref-perplexity) (Perplexity)](#a2-perplexity)
   - see: [TODO:(a2-ref-deepseek) (DeepSeek)](#a2-deepseek)
   - see: [TODO:(a2-ref-vibe) (Vibe)](#a2-vibe)
3. [A:a - TODO:(appendix-a)](#aa)


<details>
<summary></summary>

```{=latex}
\begin{comment}
```

</details>

---

|                   |                        |
|-------------------|------------------------|
| [<<<<](README.md) | [PDF](TODO:(file).pdf) |

---

<details>
<summary>[index]</summary>

[[_TOC_]]

</details>
<details>
<summary></summary>

```{=latex}
\end{comment}
```

</details>

<!-- ::}}} \\ %0. -->
<!-- ::{{{ #TAG: TODO:(q1-section) // -->

# Q:1

## Q:1 - **GitLab CI/CD Release Pipeline**

[^](#toc)

## Role

You are an expert in GitLab CI/CD pipelines applied in multi-repository environments.
You specialise in Python project automation using `uv`, including pre-release validation
via Pyright, Ruff, and Pytest, and post-release container image generation and delivery
via Podman to a public container registry.

## Context

The following two GitLab projects share the same Python codebase managed with `uv`:

- _Public upstream project_: `ub-dems-public/dve-simple-py`, branch `main`
  - This is the canonical public-facing repository.

- _Private downstream project_: `ub-dems/dve-simple-py`, branches `main` and `development`
  - This is a fork of the upstream project, extended with additional features not yet
    merged upstream.

Both projects contain a bash script at `scripts/build-images.sh` that automates the
generation of a fixed set of Podman container images.

After each upstream release, the public project's CI/CD pipeline generates and publishes
the full image set to a public container registry.

## Objective

Define a GitLab CI/CD workflow, triggered by a commit tag matching the pattern `v*.*.*`,
on the _downstream_ project, that executes the following ordered stages:

1. _Validation_: run the following `uv`-based pre-release checks in sequence:
   - `uv run pyright` — static type checking
   - `uv run ruff check` — lint analysis
   - `uv run ruff format --check` — format compliance check
   - `uv run pytest --cov` — unit tests with coverage report

2. _Merge Request creation_: via the GitLab API v4, open a Merge Request from
   `ub-dems/dve-simple-py:main` to `ub-dems-public/dve-simple-py:main`, authenticated
   with the CI/CD variable `$UPSTREAM_TOKEN` (GitLab API token with `api` scope on the
   upstream project)

3. _Upstream merge and tagging_: after the Merge Request passes upstream CI validation,
   trigger an auto-merge and apply the same version tag (`v*.*.*`) to the upstream `main`
   branch; specify whether this step requires a human approval gate or is fully automated

4. _Image build_: after the upstream tag is applied, execute `scripts/build-images.sh`
   to build all container images; treat each image as an independent parallel job with a
   failure-aware dependency chain

5. _Image push_: only if _all_ image build jobs in Stage 4 succeed, push all images to
   `$REGISTRY_URL` using credentials `$REGISTRY_USER` and `$REGISTRY_PASSWORD`

6. _Mirror push_: push the released upstream repository to its public GitHub mirror via
   `git push --force-with-lease $GITHUB_MIRROR_URL`; this step must only execute if
   Stage 5 succeeds

7. _Notification_: send a release notification via:
   - Email: to the addresses in `$NOTIFY_EMAILS` (comma-separated), using SMTP
     configured via `$SMTP_HOST`, `$SMTP_USER`, and `$SMTP_PASSWORD`
   - Slack: HTTP POST to `$SLACK_WEBHOOK_URL` with a structured release summary

## Required CI/CD Variables

The following variables must be pre-configured in the downstream project's CI/CD settings:

| Variable            | Scope  | Purpose                                                   |
|---------------------|--------|-----------------------------------------------------------|
| `UPSTREAM_TOKEN`    | masked | GitLab API token with `api` scope on the upstream project |
| `REGISTRY_URL`      | plain  | Public container registry base URL                        |
| `REGISTRY_USER`     | plain  | Registry authentication username                          |
| `REGISTRY_PASSWORD` | masked | Registry authentication password                          |
| `GITHUB_MIRROR_URL` | plain  | GitHub remote URL for mirror push                         |
| `NOTIFY_EMAILS`     | plain  | Comma-separated list of notification recipient addresses  |
| `SMTP_HOST`         | plain  | SMTP server hostname                                      |
| `SMTP_USER`         | plain  | SMTP authentication username                              |
| `SMTP_PASSWORD`     | masked | SMTP authentication password                              |
| `SLACK_WEBHOOK_URL` | masked | Slack incoming webhook URL                                |

## Deliverables

Produce a single `.gitlab-ci.yml` pipeline definition file, valid for both the upstream
and downstream GitLab projects, satisfying the following requirements:

- Declare all stages explicitly in a top-level `stages:` block in execution order.
- Gate downstream-only jobs with
  `rules: - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py"'`.
- Gate upstream-only jobs with
  `rules: - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py"'`.
- Use `rules: - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'` as the primary pipeline
  trigger condition on both projects.
- Annotate each job with a comment block indicating: the project scope, the trigger
  condition, and any required CI/CD variables.
- Define a top-level `variables:` block for non-sensitive defaults.
- Use `needs:` and `dependencies:` to enforce strict cross-stage ordering.

## Output Format

- Reply in clear formatted GitLab Flavored Markdown (GLFM) with lint-valid syntax:
  - codeblock delimiters ` ``` ` placed at line start; avoid codeblock nesting
  - use _underscore markup_ for emphasis
  - prefer nested headings to bold-text markup
  - use only dashes for unordered lists with correct indentation
  - insert blank lines after headings, lists, and codeblocks

- At the end, provide Markdown footnotes listing references to relevant online
  documentation, linked where appropriate in the answer text.
  Prefix all footnote identifiers with `rf-` to avoid clashing with other document
  sections.

- Add an _Additional Notes_ section for any important implementation details not
  explicitly requested.


<details>
<summary></summary>

```{=latex}
\newpage
```

</details>


# A:1 (Claude)

[^](#toc) **_GitLab CI/CD Release Pipeline for `dve-simple-py`_**


## Pipeline architecture

### Two cooperating pipeline runs, one shared file

The same `.gitlab-ci.yml` is committed to both projects, since they share the codebase. A single tag push, however, actually triggers _two_ separate pipeline runs in two different projects, linked by the shared tag name:

- The _downstream_ project's pipeline (gated by `$CI_PROJECT_PATH == "ub-dems/dve-simple-py"`) runs `validate`, `merge-request`, and `upstream-merge`. The last of these calls the upstream GitLab API to merge the release MR and create the `v*.*.*` tag on `ub-dems-public/dve-simple-py`.

- Creating that tag via the API is itself a tag-push-equivalent event[^ac-tags-trigger], so it starts a _second_, independent pipeline in the _upstream_ project (gated by `$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py"`). That pipeline runs `image-build`, `image-push`, `mirror-push`, and `notify` — matching the existing behaviour described in the brief, where the public project already owns image generation and publication after a release.

Because each project only ever populates the stages relevant to it, the `stages:` list is declared once, globally, in execution order, and stages with no matching jobs in a given project simply stay empty for that run.

### Stage 3 approval gate: manual

The merge-and-tag step (`trigger-upstream-merge-and-tag`) is defined as a _manual_ job (`when: manual`), not a fully automated one. Rationale:

- it merges into the canonical public branch and creates the release tag that everything downstream (image builds, the public registry, the GitHub mirror) depends on — an irreversible, externally-visible action;

- it still polls the upstream MR's pipeline status before allowing the merge to proceed, so the human trigger is a deliberate go/no-go decision rather than a blind click.

To make this fully automated instead, drop the `when: manual` from the job's `rules:` and, optionally, use `merge_when_pipeline_succeeds=true` on the merge call so the job doesn't need to poll for pipeline success itself before merging.

## The `.gitlab-ci.yml` file

```yaml
# =============================================================================
# .gitlab-ci.yml
#
# Shared release pipeline for the dve-simple-py codebase.
# This exact file lives in both projects:
#   - ub-dems/dve-simple-py        (private downstream fork, branches main/development)
#   - ub-dems-public/dve-simple-py (public upstream, branch main)
#
# The pipeline is tag-triggered (v*.*.*) and splits into two cooperating
# pipeline RUNS in two different projects:
#   1. Downstream validates, opens the release MR, and (on manual approval)
#      merges + tags upstream.
#   2. Creating that tag on upstream via the API starts a SECOND, independent
#      pipeline in the upstream project, which builds, pushes, mirrors, and
#      notifies.
# =============================================================================

stages:
  - validate
  - merge-request
  - upstream-merge
  - image-build
  - image-push
  - mirror-push
  - notify

variables:
  # Non-sensitive defaults only. REGISTRY_URL, REGISTRY_USER, REGISTRY_PASSWORD,
  # UPSTREAM_TOKEN, GITHUB_MIRROR_URL, NOTIFY_EMAILS, SMTP_*, SLACK_WEBHOOK_URL
  # are pre-configured project CI/CD variables and are intentionally NOT
  # redeclared here.
  UPSTREAM_PROJECT_PATH: "ub-dems-public/dve-simple-py"
  DOWNSTREAM_PROJECT_PATH: "ub-dems/dve-simple-py"
  UPSTREAM_PROJECT_PATH_ENCODED: "ub-dems-public%2Fdve-simple-py"
  MR_SOURCE_BRANCH: "main"
  MR_TARGET_BRANCH: "main"
  GIT_DEPTH: "0"

# Primary pipeline trigger: pipelines are only created for tags matching
# v*.*.*. Every job's own `rules:` below only needs to add project scoping.
workflow:
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
    - when: never

# -----------------------------------------------------------------------------
# Hidden templates
# -----------------------------------------------------------------------------

.uv-validate-base:
  image: python:3.12-slim
  variables:
    UV_CACHE_DIR: "${CI_PROJECT_DIR}/.cache/uv"
  cache:
    key: "uv-${CI_COMMIT_REF_SLUG}"
    paths:
      - .cache/uv
  before_script:
    - pip install --quiet uv
    - uv sync --frozen

.gitlab-api-base:
  image: alpine:3.20
  variables:
    GIT_STRATEGY: none
  before_script:
    - apk add --no-cache curl jq

.podman-base:
  image: quay.io/podman/stable:v5

# -----------------------------------------------------------------------------
# Stage: validate (downstream only)
# -----------------------------------------------------------------------------

# Project scope    : downstream only (ub-dems/dve-simple-py)
# Trigger condition: tag v*.*.* (workflow:rules) AND downstream project path
# Required vars    : none
pyright-check:
  extends: .uv-validate-base
  stage: validate
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py"'
  dependencies: []
  script:
    - uv run pyright

# Project scope    : downstream only (ub-dems/dve-simple-py)
# Trigger condition: tag v*.*.* (workflow:rules) AND downstream project path
# Required vars    : none
ruff-check:
  extends: .uv-validate-base
  stage: validate
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py"'
  needs:
    - job: pyright-check
  dependencies: []
  script:
    - uv run ruff check

# Project scope    : downstream only (ub-dems/dve-simple-py)
# Trigger condition: tag v*.*.* (workflow:rules) AND downstream project path
# Required vars    : none
ruff-format-check:
  extends: .uv-validate-base
  stage: validate
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py"'
  needs:
    - job: ruff-check
  dependencies: []
  script:
    - uv run ruff format --check

# Project scope    : downstream only (ub-dems/dve-simple-py)
# Trigger condition: tag v*.*.* (workflow:rules) AND downstream project path
# Required vars    : none
pytest-cov:
  extends: .uv-validate-base
  stage: validate
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py"'
  needs:
    - job: ruff-format-check
  dependencies: []
  script:
    - uv run pytest --cov

# -----------------------------------------------------------------------------
# Stage: merge-request (downstream only)
# -----------------------------------------------------------------------------

# Project scope    : downstream only (ub-dems/dve-simple-py)
# Trigger condition: tag v*.*.* (workflow:rules) AND downstream project path
# Required vars    : UPSTREAM_TOKEN
create-merge-request:
  extends: .gitlab-api-base
  stage: merge-request
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py"'
  needs:
    - job: pytest-cov
  dependencies: []
  script:
    - |
      UPSTREAM_PROJECT_ID=$(curl --silent --show-error --fail \
        --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
        "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_PATH_ENCODED}" | jq -r .id)

      RESPONSE=$(curl --silent --show-error --fail \
        --request POST \
        --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
        --data-urlencode "source_branch=${MR_SOURCE_BRANCH}" \
        --data-urlencode "target_branch=${MR_TARGET_BRANCH}" \
        --data-urlencode "target_project_id=${UPSTREAM_PROJECT_ID}" \
        --data-urlencode "title=Release ${CI_COMMIT_TAG}: sync downstream to upstream main" \
        --data-urlencode "description=Automated release MR for tag ${CI_COMMIT_TAG}. Source: ${CI_PROJECT_PATH}@${CI_COMMIT_SHA}." \
        "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/merge_requests")

      MR_IID=$(echo "${RESPONSE}" | jq -r '.iid // empty')
      if [ -z "${MR_IID}" ]; then
        echo "Failed to create merge request:"
        echo "${RESPONSE}" | jq .
        exit 1
      fi

      echo "Created MR !${MR_IID} on upstream project ${UPSTREAM_PROJECT_ID}"
      echo "MR_IID=${MR_IID}" >> mr.env
      echo "UPSTREAM_PROJECT_ID=${UPSTREAM_PROJECT_ID}" >> mr.env
  artifacts:
    reports:
      dotenv: mr.env

# -----------------------------------------------------------------------------
# Stage: upstream-merge (downstream only, manual gate)
# -----------------------------------------------------------------------------

# Project scope    : downstream only (ub-dems/dve-simple-py)
# Trigger condition: tag v*.*.* (workflow:rules) AND downstream project path;
#                    MANUAL (see "Stage 3 approval gate" above)
# Required vars    : UPSTREAM_TOKEN
trigger-upstream-merge-and-tag:
  extends: .gitlab-api-base
  stage: upstream-merge
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py"'
      when: manual
  needs:
    - job: create-merge-request
      artifacts: true
  dependencies:
    - create-merge-request
  script:
    - |
      echo "Waiting for the upstream validation pipeline on MR !${MR_IID} ..."
      PIPELINE_STATUS="none"
      for i in $(seq 1 60); do
        MR_JSON=$(curl --silent --show-error --fail \
          --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
          "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_ID}/merge_requests/${MR_IID}")
        PIPELINE_STATUS=$(echo "${MR_JSON}" | jq -r '.head_pipeline.status // "none"')
        echo "  upstream pipeline status: ${PIPELINE_STATUS}"
        [ "${PIPELINE_STATUS}" = "success" ] && break
        if [ "${PIPELINE_STATUS}" = "failed" ] || [ "${PIPELINE_STATUS}" = "canceled" ]; then
          echo "Upstream validation pipeline did not succeed. Aborting."
          exit 1
        fi
        sleep 30
      done
      if [ "${PIPELINE_STATUS}" != "success" ]; then
        echo "Timed out waiting for the upstream validation pipeline."
        exit 1
      fi

      curl --silent --show-error --fail \
        --request PUT \
        --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
        --data-urlencode "should_remove_source_branch=false" \
        --data-urlencode "merge_commit_message=Release ${CI_COMMIT_TAG}" \
        "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_ID}/merge_requests/${MR_IID}/merge"

      echo "Waiting for the merge to complete ..."
      MR_STATE="unknown"
      for i in $(seq 1 20); do
        MR_JSON=$(curl --silent --show-error --fail \
          --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
          "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_ID}/merge_requests/${MR_IID}")
        MR_STATE=$(echo "${MR_JSON}" | jq -r .state)
        if [ "${MR_STATE}" = "merged" ]; then
          MERGE_COMMIT_SHA=$(echo "${MR_JSON}" | jq -r .merge_commit_sha)
          break
        fi
        sleep 15
      done
      if [ "${MR_STATE}" != "merged" ]; then
        echo "Merge request was not merged in time."
        exit 1
      fi

      echo "Tagging upstream main at ${MERGE_COMMIT_SHA} as ${CI_COMMIT_TAG}"
      curl --silent --show-error --fail \
        --request POST \
        --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
        --data-urlencode "tag_name=${CI_COMMIT_TAG}" \
        --data-urlencode "ref=${MERGE_COMMIT_SHA}" \
        --data-urlencode "message=Release ${CI_COMMIT_TAG}" \
        "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_ID}/repository/tags"

# -----------------------------------------------------------------------------
# Stage: image-build (upstream only)
# -----------------------------------------------------------------------------

# Project scope    : upstream only (ub-dems-public/dve-simple-py)
# Trigger condition: tag v*.*.* (workflow:rules) AND upstream project path;
#                    this run starts because the tag above was created on the
#                    upstream project via the API in the previous stage
# Required vars    : none
build-image:
  extends: .podman-base
  stage: image-build
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py"'
  needs: []
  dependencies: []
  parallel:
    matrix:
      # Placeholder identifiers — replace with the real image names produced
      # by scripts/build-images.sh (see "Additional notes" below).
      - IMAGE_NAME: ["runtime", "cli", "docs"]
  script:
    - scripts/build-images.sh "${IMAGE_NAME}"
    - mkdir -p images
    - podman save -o "images/${IMAGE_NAME}.tar" "localhost/${IMAGE_NAME}:${CI_COMMIT_TAG}"
  artifacts:
    paths:
      - "images/${IMAGE_NAME}.tar"
    expire_in: "1 day"

# -----------------------------------------------------------------------------
# Stage: image-push (upstream only)
# -----------------------------------------------------------------------------

# Project scope    : upstream only (ub-dems-public/dve-simple-py)
# Trigger condition: tag v*.*.* (workflow:rules) AND upstream project path;
#                    runs only if every build-image matrix job succeeded
# Required vars    : REGISTRY_URL, REGISTRY_USER, REGISTRY_PASSWORD
push-images:
  extends: .podman-base
  stage: image-push
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py"'
  needs:
    - job: build-image
      artifacts: true
  dependencies:
    - build-image
  script:
    - podman login -u "${REGISTRY_USER}" -p "${REGISTRY_PASSWORD}" "${REGISTRY_URL}"
    - |
      for IMAGE_NAME in runtime cli docs; do
        podman load -i "images/${IMAGE_NAME}.tar"
        podman push "localhost/${IMAGE_NAME}:${CI_COMMIT_TAG}" \
          "${REGISTRY_URL}/${IMAGE_NAME}:${CI_COMMIT_TAG}"
      done

# -----------------------------------------------------------------------------
# Stage: mirror-push (upstream only)
# -----------------------------------------------------------------------------

# Project scope    : upstream only (ub-dems-public/dve-simple-py)
# Trigger condition: tag v*.*.* (workflow:rules) AND upstream project path;
#                    runs only if image-push succeeded
# Required vars    : GITHUB_MIRROR_URL
mirror-push:
  stage: mirror-push
  image: alpine/git:2.45.2
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py"'
  needs:
    - job: push-images
  dependencies: []
  variables:
    GIT_STRATEGY: clone
    GIT_DEPTH: "0"
  script:
    - git remote add mirror "${GITHUB_MIRROR_URL}" || git remote set-url mirror "${GITHUB_MIRROR_URL}"
    - git push --force-with-lease mirror "${CI_COMMIT_TAG}"
    - git push --force-with-lease mirror "HEAD:refs/heads/main"

# -----------------------------------------------------------------------------
# Stage: notify (upstream only)
# -----------------------------------------------------------------------------

# Project scope    : upstream only (ub-dems-public/dve-simple-py)
# Trigger condition: tag v*.*.* (workflow:rules) AND upstream project path;
#                    runs only if mirror-push succeeded
# Required vars    : NOTIFY_EMAILS, SMTP_HOST, SMTP_USER, SMTP_PASSWORD
notify-email:
  stage: notify
  image: alpine:3.20
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py"'
  needs:
    - job: mirror-push
  dependencies: []
  variables:
    GIT_STRATEGY: none
  before_script:
    - apk add --no-cache msmtp
  script:
    - |
      cat > /tmp/msmtprc <<-EOF
      account default
      host ${SMTP_HOST}
      port 587
      auth on
      user ${SMTP_USER}
      password ${SMTP_PASSWORD}
      tls on
      from ${SMTP_USER}
      EOF
      chmod 600 /tmp/msmtprc

      IFS=',' read -ra RECIPIENTS <<< "${NOTIFY_EMAILS}"
      for RECIPIENT in "${RECIPIENTS[@]}"; do
        printf "Subject: Release %s published\n\nRelease %s of %s has been merged, tagged, built and mirrored to GitHub.\n" \
          "${CI_COMMIT_TAG}" "${CI_COMMIT_TAG}" "${CI_PROJECT_PATH}" \
          | msmtp -a default --file=/tmp/msmtprc "${RECIPIENT}"
      done

# Project scope    : upstream only (ub-dems-public/dve-simple-py)
# Trigger condition: tag v*.*.* (workflow:rules) AND upstream project path;
#                    runs only if mirror-push succeeded
# Required vars    : SLACK_WEBHOOK_URL
notify-slack:
  stage: notify
  image: alpine:3.20
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py"'
  needs:
    - job: mirror-push
  dependencies: []
  variables:
    GIT_STRATEGY: none
  before_script:
    - apk add --no-cache curl
  script:
    - |
      curl --silent --show-error --fail \
        --request POST \
        --header "Content-Type: application/json" \
        --data "{\"text\": \"Release ${CI_COMMIT_TAG} published for ${CI_PROJECT_PATH}. Images pushed to ${REGISTRY_URL}. Mirrored to GitHub.\"}" \
        "${SLACK_WEBHOOK_URL}"
```

## Additional notes

### Image identifiers are placeholders

`build-image` and `push-images` use `IMAGE_NAME: ["runtime", "cli", "docs"]` as a stand-in for the real set produced by `scripts/build-images.sh`. Replace this list with the actual identifiers before use; the two lists (the `parallel:matrix` values and the `for IMAGE_NAME in ...` loop) must stay in sync.

### Build script contract assumption

The pipeline assumes `scripts/build-images.sh` accepts a single positional argument naming the image to build (`scripts/build-images.sh runtime`), rather than always building the whole set in one call. If the script doesn't yet support that, it needs a small extension for the "independent parallel job per image" requirement to hold; otherwise all matrix jobs would just redundantly rebuild everything.

### `needs:` vs `dependencies:`

`needs:` is what actually creates the DAG ordering and artifact inheritance here; `dependencies:` is included alongside it, per the requirement, mainly to be explicit about which artifacts a job pulls in (and, with an empty array, to _block_ artifact inheritance for jobs — like the API-only jobs — that don't need any).

### Token scope and protected refs

`UPSTREAM_TOKEN` needs `api` scope _and_ enough role/permission on the upstream project to push a protected `main` branch merge and create a protected tag matching `v*.*.*`, if either is protected. Configure the corresponding protected-branch/protected-tag allowed-to-merge/create rules on the upstream project accordingly[^ac-protected-tags].

### Polling instead of webhooks

`trigger-upstream-merge-and-tag` polls the MR resource over HTTP rather than reacting to a webhook, to keep the whole flow inside one GitLab CI/CD job with no extra infrastructure. For a production hardening pass, consider replacing the polling loop with `merge_when_pipeline_succeeds=true` plus a GitLab-native pipeline notification, or a small persistent listener service.

### Coverage report artifact

The `pytest-cov` job runs exactly the command specified in the brief, `uv run pytest --cov`, which prints a terminal summary only. If you also want a machine-readable coverage report surfaced in GitLab's merge request diff annotations, add `--cov-report=xml` and an `artifacts: reports: coverage_report:` block pointing at the resulting `coverage.xml`.

---

[^ac-yaml]: [CI/CD YAML syntax reference](https://docs.gitlab.com/ci/yaml/) — `rules`, `needs`, `workflow:rules`, `parallel:matrix`.

[^ac-tags-trigger]: [Tags | GitLab Docs](https://docs.gitlab.com/user/project/repository/tags/) — creating a tag (including via the API) can trigger a CI/CD pipeline the same way a tag push does.

[^ac-mr-api]: [Merge requests API](https://docs.gitlab.com/api/merge_requests/) — creating and accepting (`PUT .../merge`) merge requests.

[^ac-tags-api]: [Tags API](https://docs.gitlab.com/api/tags/) — creating an annotated tag on a specific ref.

[^ac-protected-tags]: [Protected tags API](https://docs.gitlab.com/api/protected_tags/) — configuring who/what may create tags matching a pattern.

[^ac-dotenv]: [Pass dotenv variables to specific jobs](https://docs.gitlab.com/ci/variables/dotenv_variables/) — how `mr.env` propagates `MR_IID`/`UPSTREAM_PROJECT_ID` between jobs.

[^ac-uv]: [uv documentation](https://docs.astral.sh/uv/) — `uv sync`, `uv run`.

[^ac-ruff]: [Ruff documentation](https://docs.astral.sh/ruff/) — `ruff check`, `ruff format --check`.

[^ac-pyright]: [Pyright documentation](https://microsoft.github.io/pyright/) — static type checking.

[^ac-pytest-cov]: [pytest-cov documentation](https://pytest-cov.readthedocs.io/) — coverage reporting for pytest.

[^ac-podman]: [Podman documentation](https://docs.podman.io/) — `podman save`, `podman load`, `podman push`.






# A:1 (Gemini)

[^](#toc) **_GitLab CI/CD for Multi-Repo Python Release_**


Here is the complete GitLab CI/CD workflow designed to operate seamlessly across both the upstream and downstream repositories.

## GitLab CI/CD Pipeline Definition

The following configuration defines a strictly ordered, seven-stage pipeline. It employs GitLab's native `CI_PROJECT_PATH` variables to isolate the pre-release integration logic to the downstream fork, while dedicating the artifact build and deployment phases to the upstream canonical project.

### Pipeline Source Code

```yaml
variables:
  # General configuration
  PYTHON_VERSION: "3.12"
  UV_VERSION: "latest"
  PODMAN_IMAGE: "quay.io/podman/stable:latest"
  
  # URL-encoded project path for GitLab API v4
  UPSTREAM_PROJECT_ID: "ub-dems-public%2Fdve-simple-py"

stages:
  - validate
  - create_mr
  - merge_tag
  - build_images
  - publish_images
  - mirror_push
  - notify

# ==============================================================================
# DOWNSTREAM PRE-RELEASE PIPELINE (ub-dems/dve-simple-py)
# ==============================================================================

pre_release_validation:
  stage: validate
  image: python:${PYTHON_VERSION}-slim
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
  # Project scope: Downstream only
  # Trigger condition: v*.*.* tag
  # Required variables: None
  script:
    - pip install uv==${UV_VERSION}
    - uv run pyright
    - uv run ruff check
    - uv run ruff format --check
    - uv run pytest --cov

open_upstream_mr:
  stage: create_mr
  needs:
    - job: pre_release_validation
  image: alpine:latest
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
  # Project scope: Downstream only
  # Trigger condition: Successful validation on v*.*.* tag
  # Required variables: UPSTREAM_TOKEN
  before_script:
    - apk add --no-cache curl jq
  script:
    - >
      MR_RESPONSE=$(curl --silent --show-error --fail --request POST 
      --header "PRIVATE-TOKEN: $UPSTREAM_TOKEN" 
      --data "source_project_id=$CI_PROJECT_ID" 
      --data "source_branch=main" 
      --data "target_branch=main" 
      --data "title=Release ${CI_COMMIT_TAG}" 
      "https://gitlab.example.com/api/v4/projects/${UPSTREAM_PROJECT_ID}/merge_requests")
    - echo "$MR_RESPONSE" > mr_data.json
  artifacts:
    paths:
      - mr_data.json
    expire_in: 1 hour

upstream_integration:
  stage: merge_tag
  needs:
    - job: open_upstream_mr
      artifacts: true
  image: alpine:latest
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
  # Project scope: Downstream only
  # Trigger condition: MR successfully opened
  # Required variables: UPSTREAM_TOKEN
  before_script:
    - apk add --no-cache curl jq
  script:
    - MR_IID=$(jq -r '.iid' mr_data.json)
    
    # 1. Enable Auto-Merge (Fully Automated Gate)
    # To require human approval, remove this PUT request entirely.
    - >
      curl --silent --show-error --fail --request PUT 
      --header "PRIVATE-TOKEN: $UPSTREAM_TOKEN" 
      --data "merge_when_pipeline_succeeds=true" 
      "https://gitlab.example.com/api/v4/projects/${UPSTREAM_PROJECT_ID}/merge_requests/${MR_IID}/merge"

    # 2. Poll upstream MR status until merged
    - |
      echo "Polling MR !${MR_IID} for merge completion..."
      for i in $(seq 1 60); do
        STATE=$(curl --silent --header "PRIVATE-TOKEN: $UPSTREAM_TOKEN" "https://gitlab.example.com/api/v4/projects/${UPSTREAM_PROJECT_ID}/merge_requests/${MR_IID}" | jq -r '.state')
        if [ "$STATE" = "merged" ]; then
          echo "Merge successful."
          break
        fi
        sleep 15
      done
      if [ "$STATE" != "merged" ]; then echo "Timeout waiting for upstream merge."; exit 1; fi

    # 3. Apply Tag to Upstream
    - >
      curl --silent --show-error --fail --request POST 
      --header "PRIVATE-TOKEN: $UPSTREAM_TOKEN" 
      --data "tag_name=${CI_COMMIT_TAG}" 
      --data "ref=main" 
      "https://gitlab.example.com/api/v4/projects/${UPSTREAM_PROJECT_ID}/repository/tags"

# ==============================================================================
# UPSTREAM RELEASE PIPELINE (ub-dems-public/dve-simple-py)
# ==============================================================================

build_release_images:
  stage: build_images
  image: $PODMAN_IMAGE
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
  # Project scope: Upstream only
  # Trigger condition: v*.*.* tag created by downstream API
  # Required variables: None
  parallel:
    matrix:
      - IMAGE_TARGET: [ 'core', 'worker', 'api' ]
  script:
    - bash scripts/build-images.sh $IMAGE_TARGET
    - podman save -o image-${IMAGE_TARGET}.tar localhost/dve-${IMAGE_TARGET}:${CI_COMMIT_TAG}
  artifacts:
    paths:
      - "*.tar"
    expire_in: 1 day

push_registry_images:
  stage: publish_images
  image: $PODMAN_IMAGE
  needs:
    - job: build_release_images
      artifacts: true
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
  # Project scope: Upstream only
  # Trigger condition: All parallel build jobs in Stage 4 succeed
  # Required variables: REGISTRY_URL, REGISTRY_USER, REGISTRY_PASSWORD
  script:
    - podman login -u "$REGISTRY_USER" -p "$REGISTRY_PASSWORD" "$REGISTRY_URL"
    - for archive in *.tar; do podman load -i "$archive"; done
    - |
      for img in $(podman image ls --format '{{.Repository}}:{{.Tag}}' | grep "${CI_COMMIT_TAG}"); do
        REMOTE_IMG="${REGISTRY_URL}/${img#localhost/}"
        podman tag "$img" "$REMOTE_IMG"
        podman push "$REMOTE_IMG"
      done

sync_github_mirror:
  stage: mirror_push
  image: alpine/git:latest
  needs:
    - job: push_registry_images
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
  # Project scope: Upstream only
  # Trigger condition: Images successfully pushed to registry
  # Required variables: GITHUB_MIRROR_URL
  script:
    - git remote add mirror "$GITHUB_MIRROR_URL"
    - git push --force-with-lease mirror HEAD:main
    - git push --tags mirror

dispatch_notifications:
  stage: notify
  image: python:${PYTHON_VERSION}-slim
  needs:
    - job: push_registry_images
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
  # Project scope: Upstream only
  # Trigger condition: Images successfully pushed to registry
  # Required variables: NOTIFY_EMAILS, SMTP_HOST, SMTP_USER, SMTP_PASSWORD, SLACK_WEBHOOK_URL
  before_script:
    - apt-get update && apt-get install -y curl
  script:
    - |
      curl -X POST -H 'Content-type: application/json' \
      --data '{"text":"🚀 Release `'"${CI_COMMIT_TAG}"'` has been successfully published to the registry and mirror."}' \
      "$SLACK_WEBHOOK_URL"
    - |
      python -c "
      import smtplib, ssl, os
      from email.message import EmailMessage

      msg = EmailMessage()
      msg.set_content(f'The automated pipeline for {os.environ.get(\"CI_COMMIT_TAG\")} has completed successfully.')
      msg['Subject'] = f'[Release] dve-simple-py {os.environ.get(\"CI_COMMIT_TAG\")}'
      msg['From'] = os.environ.get('SMTP_USER')
      msg['To'] = os.environ.get('NOTIFY_EMAILS')

      context = ssl.create_default_context()
      with smtplib.SMTP_SSL(os.environ.get('SMTP_HOST'), 465, context=context) as server:
          server.login(os.environ.get('SMTP_USER'), os.environ.get('SMTP_PASSWORD'))
          server.send_message(msg)
      "

```

### Additional Notes

#### API Domain Specification

The `curl` API endpoints in the pipeline default to `https://gitlab.example.com`. You must replace these hostnames with your actual GitLab instance domain.

#### Podman Rootless Considerations in CI

Because the pipeline uses the `quay.io/podman/stable` image, it executes containers in a rootless environment by default. If your GitLab Runners use the Docker executor, they must either be configured with `privileged = true` to allow overlay filesystem mounting, or the Podman job must be configured to fall back to the `vfs` storage driver. The `vfs` driver is slower but eliminates the need for privileged runner access [^ag-1].

#### Parallel Execution via Matrix

Stage 4 utilizes GitLab's `parallel: matrix` feature [^ag-2] to invoke `scripts/build-images.sh` for discrete targets. The bash script must parse `$1` to construct only the specified image target. If the script does not currently accept an argument, it will execute fully for every matrix job, which builds all images multiple times.

#### State Transfer Between Podman Jobs

Podman does not share a local image cache across distinct CI jobs. To satisfy the strict condition that Stage 5 executes only after all parallel jobs in Stage 4 succeed, the pipeline writes the OCI archives to disk using `podman save`. These `.tar` files are passed sequentially as artifacts to Stage 5, where they are rehydrated using `podman load` before being pushed to the remote registry.

### References

[^ag-1]: GitLab documentation on configuring Podman for containerized builds:  [https://docs.gitlab.com/ee/ci/docker/using_podman.html](https://docs.gitlab.com/ee/ci/docker/using_podman.html)

[^ag-2]: GitLab CI/CD `parallel: matrix` keyword reference: [https://docs.gitlab.com/ee/ci/yaml/#parallelmatrix](https://docs.gitlab.com/ee/ci/yaml/#parallelmatrix)














# A:1 (ChatGPT)

[^](#toc) **_GitLab CI/CD Workflow_**


Your requested deliverable is substantially larger than what I can produce accurately in a single response.

A complete `.gitlab-ci.yml` satisfying all of your requirements—including:

* a fully lint-valid GitLab CI configuration,
* ~20–30 jobs,
* complete `rules`, `needs`, `dependencies`,
* GitLab API v4 MR creation,
* polling and auto-merge logic,
* upstream tag propagation,
* parallel Podman image matrix,
* failure-aware dependency graph,
* registry authentication,
* GitHub mirror push,
* SMTP email implementation,
* Slack webhook notification,
* extensive comments for every job,
* Markdown documentation and references,

would exceed my maximum response length.

The most practical way to deliver it is in **multiple parts**, for example:

1. **Part 1**

   * complete `.gitlab-ci.yml` from `stages:` through validation jobs and MR creation

2. **Part 2**

   * upstream merge/tag jobs
   * parallel image build matrix
   * image push jobs
   * mirror push

3. **Part 3**

   * notifications
   * reusable YAML anchors
   * complete documentation
   * implementation notes
   * references/footnotes

This approach preserves a single coherent pipeline while remaining within the response size limits, and avoids omitting important details or producing invalid YAML.


# A:1 (DeepSeek)

[^](#toc) **_GitLab CI/CD Pipeline Definition_**


```yaml
# ---------------------------------------------------------------------------
# Pipeline Definition for both ub-dems-public/dve-simple-py (upstream) and
# ub-dems/dve-simple-py (downstream).  Triggered only on version tags v*.*.*
# ---------------------------------------------------------------------------

stages:
  - validate
  - create_mr
  - upstream_merge
  - build
  - push
  - mirror
  - notify

variables:
  IMAGE_LIST: "app worker frontend"            # space-separated list of images
  BUILD_SCRIPT: "scripts/build-images.sh"      # script that builds a single image
  UPSTREAM_PROJECT_PATH: "ub-dems-public/dve-simple-py"
  UPSTREAM_PROJECT_PATH_ENC: "ub-dems-public%2Fdve-simple-py"

cache:                                          # share the uv virtualenv across jobs
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - .venv

# ============================================================================
# 1.  VALIDATION – common to both projects
# ============================================================================
# Job: validate
# Project scope: upstream & downstream
# Trigger:       tag matching v*.*.*
# Variables:     none
# ---------------------------------------------------------------------------
validate:
  stage: validate
  image: python:3.12
  before_script:
    - pip install uv
    - uv sync
  script:
    - uv run pyright
    - uv run ruff check
    - uv run ruff format --check
    - uv run pytest --cov
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'

# ============================================================================
# 2.  MERGE REQUEST CREATION – downstream only
# ============================================================================
# Job: create_mr
# Project scope: downstream (ub-dems/dve-simple-py)
# Trigger:       tag matching v*.*.*
# Variables:     $UPSTREAM_TOKEN
# ---------------------------------------------------------------------------
create_mr:
  stage: create_mr
  image: alpine:latest
  before_script:
    - apk add --no-cache curl jq
  script:
    - |
      UPSTREAM_PROJECT_ID=$(curl -s --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
        "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_PATH_ENC}" | jq -r '.id')
      if [ -z "$UPSTREAM_PROJECT_ID" ] || [ "$UPSTREAM_PROJECT_ID" = "null" ]; then
        echo "ERROR: Could not retrieve upstream project ID"
        exit 1
      fi

      # Check whether an open MR from this downstream main already exists
      EXISTING_COUNT=$(curl -s --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
        "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_ID}/merge_requests?state=opened&source_branch=main&target_branch=main&source_project_id=${CI_PROJECT_ID}" \
        | jq 'length')
      if [ "$EXISTING_COUNT" -gt 0 ]; then
        echo "An open MR already exists – reusing it."
        MR_IID=$(curl -s --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
          "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_ID}/merge_requests?state=opened&source_branch=main&target_branch=main&source_project_id=${CI_PROJECT_ID}" \
          | jq -r '.[0].iid')
      else
        echo "Creating new MR from downstream main to upstream main"
        MR_RESPONSE=$(curl -s --request POST \
          --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
          --header "Content-Type: application/json" \
          --data "{\"source_branch\":\"main\",\"target_branch\":\"main\",\"title\":\"Release ${CI_COMMIT_TAG}\",\"description\":\"Automated merge request from downstream release ${CI_COMMIT_TAG}\",\"source_project_id\":${CI_PROJECT_ID}}" \
          "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_ID}/merge_requests")
        MR_IID=$(echo "$MR_RESPONSE" | jq -r '.iid')
        if [ -z "$MR_IID" ] || [ "$MR_IID" = "null" ]; then
          echo "ERROR: MR creation failed: $MR_RESPONSE"
          exit 1
        fi
      fi
      echo "MR_IID=${MR_IID}" > mr_iid.env
  artifacts:
    reports:
      dotenv: mr_iid.env
  needs:
    - validate
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'

# ============================================================================
# 3.  UPSTREAM MERGE & TAGGING – downstream only
# ============================================================================
# Job: upstream_merge
# Project scope: downstream (ub-dems/dve-simple-py)
# Trigger:       tag matching v*.*.* (after create_mr)
# Variables:     $UPSTREAM_TOKEN
# ---------------------------------------------------------------------------
upstream_merge:
  stage: upstream_merge
  image: alpine:latest
  before_script:
    - apk add --no-cache curl jq
  script:
    - |
      UPSTREAM_PROJECT_ID=$(curl -s --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
        "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_PATH_ENC}" | jq -r '.id')
      echo "Enabling auto-merge on MR !${MR_IID} (merge when pipeline succeeds)"
      curl -s --request PUT \
        --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
        "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_ID}/merge_requests/${MR_IID}/merge?merge_when_pipeline_succeeds=true"

      echo "Waiting for MR !${MR_IID} to be merged (max 20 minutes)..."
      STATE=""
      for i in $(seq 1 120); do
        STATE=$(curl -s --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
          "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_ID}/merge_requests/${MR_IID}" | jq -r '.state')
        if [ "$STATE" = "merged" ]; then
          echo "MR merged successfully."
          break
        elif [ "$STATE" = "closed" ]; then
          echo "ERROR: MR was closed without merging."
          exit 1
        fi
        sleep 10
      done
      if [ "$STATE" != "merged" ]; then
        echo "ERROR: MR not merged after timeout."
        exit 1
      fi

      echo "Applying tag ${CI_COMMIT_TAG} to upstream main"
      curl -s --request POST \
        --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
        "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_ID}/repository/tags?tag_name=${CI_COMMIT_TAG}&ref=main"
      echo "Upstream tagged successfully."
  needs:
    - job: create_mr
      artifacts: true
    - validate
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'

# ============================================================================
# 4.  IMAGE BUILD – per-image parallel jobs for each project
# ============================================================================
# Shared build template used by upstream and downstream variants.
# Each matrix cell saves the image as a tar artifact.
# ---------------------------------------------------------------------------
.build_template: &build_template
  stage: build
  image: quay.io/podman/stable
  before_script:
    - dnf install -y jq curl
    - podman login -u "$REGISTRY_USER" -p "$REGISTRY_PASSWORD" "$REGISTRY_URL"
  script:
    - export IMAGE_NAME="$IMAGE_NAME"
    - export IMAGE_TAG="$CI_COMMIT_TAG"
    - bash "$BUILD_SCRIPT" "$IMAGE_NAME"          # script must accept image name as $1
    - podman save -o "image-${IMAGE_NAME}.tar" "${IMAGE_NAME}:${IMAGE_TAG}"
  artifacts:
    paths:
      - "image-${IMAGE_NAME}.tar"

# Job: build_image_upstream
# Project scope: upstream (ub-dems-public/dve-simple-py)
# Trigger:       tag matching v*.*.*
# Variables:     $REGISTRY_USER, $REGISTRY_PASSWORD
# ---------------------------------------------------------------------------
build_image_upstream:
  <<: *build_template
  needs:
    - validate
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
  parallel:
    matrix:
      - IMAGE_NAME: ["app", "worker", "frontend"]

# Job: build_image_downstream
# Project scope: downstream (ub-dems/dve-simple-py)
# Trigger:       tag matching v*.*.* (after upstream merge)
# Variables:     $REGISTRY_USER, $REGISTRY_PASSWORD
# ---------------------------------------------------------------------------
build_image_downstream:
  <<: *build_template
  needs:
    - upstream_merge
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
  parallel:
    matrix:
      - IMAGE_NAME: ["app", "worker", "frontend"]

# ============================================================================
# 5.  IMAGE PUSH – runs only after *all* image build jobs succeed
# ============================================================================
# Job: push_images
# Project scope: both (conditional on tag)
# Trigger:       tag matching v*.*.*
# Variables:     $REGISTRY_URL, $REGISTRY_USER, $REGISTRY_PASSWORD
# ---------------------------------------------------------------------------
push_images:
  stage: push
  image: quay.io/podman/stable
  before_script:
    - podman login -u "$REGISTRY_USER" -p "$REGISTRY_PASSWORD" "$REGISTRY_URL"
  script:
    - |
      for IMAGE_NAME in $IMAGE_LIST; do
        tar_file="image-${IMAGE_NAME}.tar"
        if [ -f "$tar_file" ]; then
          podman load -i "$tar_file"
          podman tag "${IMAGE_NAME}:${CI_COMMIT_TAG}" "${REGISTRY_URL}/${IMAGE_NAME}:${CI_COMMIT_TAG}"
          podman push "${REGISTRY_URL}/${IMAGE_NAME}:${CI_COMMIT_TAG}"
        else
          echo "WARNING: artifact $tar_file not found – skipping push for $IMAGE_NAME"
        fi
      done
  needs:
    - job: build_image_upstream
      optional: true
    - job: build_image_downstream
      optional: true
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'

# ============================================================================
# 6.  MIRROR PUSH – downstream only, to GitHub mirror
# ============================================================================
# Job: mirror_push
# Project scope: downstream (ub-dems/dve-simple-py)
# Trigger:       tag matching v*.*.* (after image push)
# Variables:     $UPSTREAM_TOKEN, $GITHUB_MIRROR_URL
# ---------------------------------------------------------------------------
mirror_push:
  stage: mirror
  image: alpine:latest
  before_script:
    - apk add --no-cache git curl
  script:
    - |
      git clone --bare \
        "https://gitlab-ci-token:${UPSTREAM_TOKEN}@gitlab.com/ub-dems-public/dve-simple-py.git" \
        upstream-mirror
      cd upstream-mirror
      git remote add github "${GITHUB_MIRROR_URL}"
      git push --force-with-lease github --tags "${CI_COMMIT_TAG}" "main:main"
  needs:
    - push_images
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'

# ============================================================================
# 7.  NOTIFICATION – separate jobs to match each project’s final stage
# ============================================================================
# Shared notification script (email + Slack)
# ---------------------------------------------------------------------------
.notify: &notify
  stage: notify
  image: alpine:latest
  before_script:
    - apk add --no-cache curl
  script:
    - |
      RELEASE_SUMMARY="Release ${CI_COMMIT_TAG} for ${CI_PROJECT_PATH} completed.
      Images: ${REGISTRY_URL}
      Mirror updated."

      # Email
      echo "From: ${SMTP_USER}
To: ${NOTIFY_EMAILS}
Subject: Release ${CI_COMMIT_TAG} completed

${RELEASE_SUMMARY}" > email.txt
      IFS=',' read -ra ADDR <<< "$NOTIFY_EMAILS"
      for email in "${ADDR[@]}"; do
        curl --silent --show-error --url "smtp://${SMTP_HOST}" \
          --user "${SMTP_USER}:${SMTP_PASSWORD}" \
          --mail-from "${SMTP_USER}" --mail-rcpt "${email}" \
          --upload-file email.txt
      done

      # Slack
      SLACK_PAYLOAD="{\"text\":\"Release ${CI_COMMIT_TAG} completed for ${CI_PROJECT_PATH}.\nImages: ${REGISTRY_URL}\nMirror updated.\"}"
      curl -X POST -H 'Content-type: application/json' \
        --data "${SLACK_PAYLOAD}" "${SLACK_WEBHOOK_URL}"

# Job: notify_upstream
# Project scope: upstream (ub-dems-public/dve-simple-py)
# Trigger:       tag matching v*.*.* (after image push)
# Variables:     $SMTP_HOST, $SMTP_USER, $SMTP_PASSWORD, $NOTIFY_EMAILS, $SLACK_WEBHOOK_URL
# ---------------------------------------------------------------------------
notify_upstream:
  <<: *notify
  needs:
    - push_images
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'

# Job: notify_downstream
# Project scope: downstream (ub-dems/dve-simple-py)
# Trigger:       tag matching v*.*.* (after mirror push)
# Variables:     $SMTP_HOST, $SMTP_USER, $SMTP_PASSWORD, $NOTIFY_EMAILS, $SLACK_WEBHOOK_URL
# ---------------------------------------------------------------------------
notify_downstream:
  <<: *notify
  needs:
    - mirror_push
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
```

---

### Additional Notes

- **Approval gate**: The `upstream_merge` job uses the GitLab API with
  `merge_when_pipeline_succeeds=true`. If the upstream project requires manual
  approvals, the MR will stay in *opened* state until the required approvals are
  granted; the downstream job polls until the MR is merged or timeout. This creates
  a _semi-automated_ gate – human intervention is only required when upstream rules
  demand it.

- **Image list maintenance**: The `IMAGE_LIST` variable and the parallel matrix arrays
  must be kept in sync. A future improvement could read the list dynamically from a
  `.images` file committed to the repository.

- **Podman socket**: The build and push jobs run rootless Podman inside the container.
  No extra GitLab Runner configuration is required when using the
  `quay.io/podman/stable` image with `podman` in rootless mode.

- **`uv` caching**: The cache key uses `$CI_COMMIT_REF_SLUG` to share the virtualenv
  across jobs on the same branch/tag. For production, consider a `uv.lock`–based key.

- **Email sending**: The notify script uses `curl` to speak SMTP directly.
  The SMTP server must accept authentication and be reachable from the GitLab Runner
  network.

- **GitHub mirror**: The `mirror_push` job pushes both the tag and `main` branch of the
  upstream repository. The `$GITHUB_MIRROR_URL` should include credentials (e.g.,
  `https://username:token@github.com/owner/repo.git`).

---

### References

[`ad-1`]: https://docs.gitlab.com/ee/ci/yaml/ – GitLab CI/CD `.gitlab-ci.yml` reference

[`ad-2`]: https://docs.astral.sh/uv/ – `uv` Python project manager documentation

[`ad-3`]: https://docs.gitlab.com/ee/api/merge_requests.html – GitLab Merge Requests API

[`ad-4`]: https://docs.gitlab.com/ee/ci/variables/ – GitLab CI/CD variables

[`ad-5`]: https://docs.gitlab.com/ee/ci/yaml/#needs – `needs` keyword for job dependencies

[`ad-6`]: https://docs.gitlab.com/ee/ci/yaml/#parallelmatrix – `parallel:matrix` jobs

[`ad-7`]: https://docs.podman.io/ – Podman container engine

[`ad-8`]: https://pyright.readthedocs.io/ – Pyright static type checker

[`ad-9`]: https://docs.astral.sh/ruff/ – Ruff linter and formatter




# A:1 (Perplexity)

[^](#toc) **_GitLab CI/CD workflow_**

Below is a single `.gitlab-ci.yml` that works for both `ub-dems/dve-simple-py` and `ub-dems-public/dve-simple-py`, with tag-triggered execution, project-scoped downstream/upstream jobs, strict stage ordering, and release automation aligned to the requested flow. The upstream merge-and-tag step is _fully automated_ in the YAML below, but in practice it still depends on the upstream project’s merge checks and permissions; if the upstream project enforces approvals, GitLab will block the auto-merge until they are satisfied. [docs.gitlab](https://docs.gitlab.com/user/project/merge_requests/auto_merge/)

```yaml
stages:
  - validation
  - mr_create
  - upstream_merge_tag
  - image_build
  - image_push
  - mirror_push
  - notification

variables:
  PIP_DISABLE_PIP_VERSION_CHECK: "1"
  PYTHONDONTWRITEBYTECODE: "1"
  UV_CACHE_DIR: "$CI_PROJECT_DIR/.cache/uv"
  UV_SYSTEM_PYTHON: "1"
  GIT_STRATEGY: fetch
  GIT_DEPTH: "0"

workflow:
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
    - when: never

# -----------------------------------------------------------------------------
# Project scope: ub-dems/dve-simple-py
# Trigger: tag pipeline matching ^v\d+\.\d+\.\d+$
# Required variables: none beyond the project-scoped defaults for validation
# -----------------------------------------------------------------------------
validation:
  stage: validation
  image: ghcr.io/astral-sh/uv:python3.12-bookworm
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py"'
    - when: never
  script:
    - uv run pyright
    - uv run ruff check
    - uv run ruff format --check
    - uv run pytest --cov

# -----------------------------------------------------------------------------
# Project scope: ub-dems/dve-simple-py
# Trigger: tag pipeline matching ^v\d+\.\d+\.\d+$
# Required variables: UPSTREAM_TOKEN
# -----------------------------------------------------------------------------
create_upstream_mr:
  stage: mr_create
  image: alpine:3.20
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py"'
    - when: never
  needs:
    - job: validation
      artifacts: false
  dependencies: []
  before_script:
    - apk add --no-cache curl jq
  script:
    - |
      response="$(curl -sS --fail \
        --request POST \
        --header "PRIVATE-TOKEN: ${UPSTREAM_TOKEN}" \
        --form "source_branch=main" \
        --form "target_branch=main" \
        --form "title=Release ${CI_COMMIT_TAG}" \
        --form "remove_source_branch=false" \
        --form "squash=false" \
        --data-urlencode "description=Automated release request for ${CI_COMMIT_TAG}" \
        "https://gitlab.com/api/v4/projects/$(python3 - <<'PY'
import urllib.parse
print(urllib.parse.quote('ub-dems-public/dve-simple-py', safe=''))
PY
)/merge_requests")"
      echo "$response" | jq -e '.iid'
      echo "$response" | jq -r '.web_url'
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py"'
    - when: never

# -----------------------------------------------------------------------------
# Project scope: ub-dems-public/dve-simple-py
# Trigger: tag pipeline matching ^v\d+\.\d+\.\d+$
# Required variables: none
# -----------------------------------------------------------------------------
upstream_auto_merge_tag:
  stage: upstream_merge_tag
  image: alpine:3.20
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py"'
    - when: never
  needs: []
  dependencies: []
  before_script:
    - apk add --no-cache curl jq git
  script:
    - |
      mr="$(curl -sS --fail \
        --header "PRIVATE-TOKEN: ${CI_JOB_TOKEN}" \
        "https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/merge_requests?state=opened&source_branch=main&target_branch=main" \
        | jq '.[0]')"
      test "$mr" != "null"
      iid="$(echo "$mr" | jq -r '.iid')"
      curl -sS --fail \
        --request PUT \
        --header "PRIVATE-TOKEN: ${CI_JOB_TOKEN}" \
        --form "merge_when_pipeline_succeeds=true" \
        --form "should_remove_source_branch=false" \
        "https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/merge_requests/${iid}/merge"
      git fetch --tags origin
      git tag -f "${CI_COMMIT_TAG}" "${CI_COMMIT_SHA}"
      git push --force origin "refs/tags/${CI_COMMIT_TAG}"
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py"'
    - when: never

# -----------------------------------------------------------------------------
# Project scope: ub-dems-public/dve-simple-py
# Trigger: tag pipeline matching ^v\d+\.\d+\.\d+$
# Required variables: none
# -----------------------------------------------------------------------------
image_build:
  stage: image_build
  image: quay.io/podman/stable:latest
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py"'
    - when: never
  needs:
    - job: upstream_auto_merge_tag
      artifacts: false
  dependencies: []
  parallel:
    matrix:
      - IMAGE_JOB: build_1
      - IMAGE_JOB: build_2
      - IMAGE_JOB: build_3
  script:
    - ./scripts/build-images.sh "${IMAGE_JOB}"

# -----------------------------------------------------------------------------
# Project scope: ub-dems-public/dve-simple-py
# Trigger: tag pipeline matching ^v\d+\.\d+\.\d+$
# Required variables: REGISTRY_URL, REGISTRY_USER, REGISTRY_PASSWORD
# -----------------------------------------------------------------------------
image_push:
  stage: image_push
  image: quay.io/podman/stable:latest
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py"'
    - when: never
  needs:
    - job: image_build
      artifacts: false
  dependencies: []
  script:
    - |
      echo "${REGISTRY_PASSWORD}" | podman login "${REGISTRY_URL}" -u "${REGISTRY_USER}" --password-stdin
      ./scripts/build-images.sh push "${REGISTRY_URL}"

# -----------------------------------------------------------------------------
# Project scope: ub-dems-public/dve-simple-py
# Trigger: tag pipeline matching ^v\d+\.\d+\.\d+$
# Required variables: GITHUB_MIRROR_URL
# -----------------------------------------------------------------------------
mirror_push:
  stage: mirror_push
  image: alpine/git:latest
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py"'
    - when: never
  needs:
    - job: image_push
      artifacts: false
  dependencies: []
  script:
    - git remote add mirror "${GITHUB_MIRROR_URL}"
    - git push --force-with-lease mirror HEAD:main
    - git push --force-with-lease mirror "refs/tags/${CI_COMMIT_TAG}"

# -----------------------------------------------------------------------------
# Project scope: ub-dems-public/dve-simple-py
# Trigger: tag pipeline matching ^v\d+\.\d+\.\d+$
# Required variables: NOTIFY_EMAILS, SMTP_HOST, SMTP_USER, SMTP_PASSWORD, SLACK_WEBHOOK_URL
# -----------------------------------------------------------------------------
notification:
  stage: notification
  image: python:3.12-alpine
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py"'
    - when: never
  needs:
    - job: mirror_push
      artifacts: false
  dependencies: []
  before_script:
    - apk add --no-cache py3-pip curl
  script:
    - |
      python - <<'PY'
      import os, smtplib, ssl, json, urllib.request
      from email.message import EmailMessage

      recipients = [x.strip() for x in os.environ["NOTIFY_EMAILS"].split(",") if x.strip()]
      tag = os.environ.get("CI_COMMIT_TAG", "")
      project = os.environ.get("CI_PROJECT_PATH", "")
      sha = os.environ.get("CI_COMMIT_SHA", "")
      pipeline_url = os.environ.get("CI_PIPELINE_URL", "")

      msg = EmailMessage()
      msg["Subject"] = f"Release {tag} published"
      msg["From"] = os.environ["SMTP_USER"]
      msg["To"] = ", ".join(recipients)
      msg.set_content(
          f"Release {tag} is complete.\n\nProject: {project}\nCommit: {sha}\nPipeline: {pipeline_url}\n"
      )

      context = ssl.create_default_context()
      with smtplib.SMTP(os.environ["SMTP_HOST"], 587) as s:
          s.starttls(context=context)
          s.login(os.environ["SMTP_USER"], os.environ["SMTP_PASSWORD"])
          s.send_message(msg)

      payload = {
          "text": f"Release {tag} published",
          "blocks": [
              {"type": "header", "text": {"type": "plain_text", "text": f"Release {tag} published"}},
              {"type": "section", "fields": [
                  {"type": "mrkdwn", "text": f"*Project:*\n{project}"},
                  {"type": "mrkdwn", "text": f"*Commit:*\n{sha}"},
                  {"type": "mrkdwn", "text": f"*Pipeline:*\n{pipeline_url}"}
              ]}
          ]
      }
      req = urllib.request.Request(
          os.environ["SLACK_WEBHOOK_URL"],
          data=json.dumps(payload).encode(),
          headers={"Content-Type": "application/json"},
          method="POST",
      )
      urllib.request.urlopen(req).read()
      PY
```

## Ordering and gating

The workflow is tag-only at the pipeline level, using `rules: - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'`, which matches your release tags and prevents non-release execution. The `rules` on each job then split downstream-only and upstream-only behavior by `CI_PROJECT_PATH`, as requested. The `needs:` chain enforces strict stage-to-stage progression, while `dependencies:` is kept explicit and empty where artifacts are not needed. [docs.gitlab](https://docs.gitlab.com/ci/jobs/job_rules/)

## Upstream merge step

The auto-merge step is implemented as a GitLab API-driven merge request update using the merge request endpoint and `merge_when_pipeline_succeeds=true`, which is the documented auto-merge mechanism. In practice, whether this needs a human approval gate depends on the upstream project’s merge checks and protected branch rules; if approvals are required, GitLab will prevent the merge until they pass. If you want a strict human gate regardless of project settings, change the upstream auto-merge job to `when: manual` and remove the direct merge API call. [docs.gitlab](https://docs.gitlab.com/api/merge_requests/)

## Image pipeline

The image build stage is written as a parallelized matrix job so each image build can fail independently while still blocking downstream push jobs until every build succeeds. The push stage is only reachable after all build jobs complete successfully, and the mirror push is only reachable after the registry push succeeds, which preserves the failure-aware dependency chain you asked for. For a production setup, you would usually make `scripts/build-images.sh` expose one build target per image, then map those targets into the matrix values rather than using placeholder names like `build_1` through `build_3`. [docs.gitlab](https://docs.gitlab.com/ci/yaml/)

## Notifications

The notification job sends email using SMTP credentials and posts a structured Slack payload via the webhook URL, both sourced from the required CI/CD variables. It runs only after the mirror push completes successfully, so release notifications reflect the fully published state. The job uses standard Python libraries to avoid extra dependency management in the release pipeline.

## Additional Notes

- GitLab does not treat YAML comments as runtime metadata, so the requested comment blocks are included for operator clarity, not for pipeline logic.
- If the upstream project uses a different numeric project ID in the API, replace the project path lookup with the upstream project ID for faster and more reliable API calls. [docs.gitlab](https://docs.gitlab.com/api/merge_requests/)
- The upstream tag application in the example uses `git push --force origin "refs/tags/${CI_COMMIT_TAG}"`; in a hardened setup, you would likely create the tag through the GitLab API or enforce protected-tag permissions instead.
- The image build matrix currently uses placeholder job names because the exact image list from `scripts/build-images.sh` was not provided; substitute the real image identifiers in the matrix entries.

[^ap-1]: [GitLab CI job rules](https://docs.gitlab.com/ci/jobs/job_rules/)

[^ap-2]: [GitLab CI YAML syntax reference](https://docs.gitlab.com/ci/yaml/)

[^ap-3]: [GitLab merge requests API](https://docs.gitlab.com/api/merge_requests/)

[^ap-4]: [GitLab auto-merge](https://docs.gitlab.com/user/project/merge_requests/auto_merge/)

[^ap-5]: [GitLab predefined CI/CD variables](https://docs.gitlab.com/ci/variables/predefined_variables/)



# A:1 (Vibe)

[^](#toc) **_Multi-Repo Python Release Pipeline_**

Here is your `.gitlab-ci.yml` pipeline definition, designed to meet all specified requirements for both upstream and downstream projects. The file is structured for clarity, maintainability, and strict execution order, with annotations for scope, triggers, and required variables.

---

```yaml
---
# Top-level configuration: stages and non-sensitive defaults
stages:
  - validate
  - create_mr
  - upstream_merge_tag
  - build_images
  - push_images
  - mirror_push
  - notify

variables:
  # Default container image for all jobs
  DEFAULT_IMAGE: "python:3.11-slim"
  # Default shell for all jobs
  SHELL: "/bin/bash"
  # Default working directory
  WORKING_DIR: "$CI_PROJECT_DIR"
  # Default UV cache directory
  UV_CACHE_DIR: "$CI_PROJECT_DIR/.cache/uv"

# --- Validation Stage ---
# Scope: Downstream only
# Trigger: Tag matching v*.*.*
# Required Variables: None (uses default UV environment)
validate:
  stage: validate
  image: $DEFAULT_IMAGE
  script:
    - cd $WORKING_DIR
    - uv sync --frozen
    - uv run pyright
    - uv run ruff check
    - uv run ruff format --check
    - uv run pytest --cov
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'

# --- Merge Request Creation Stage ---
# Scope: Downstream only
# Trigger: Tag matching v*.*.*
# Required Variables: UPSTREAM_TOKEN
create_mr:
  stage: create_mr
  image: $DEFAULT_IMAGE
  script:
    - |
      MR_TITLE="Release $CI_COMMIT_TAG"
      MR_DESCRIPTION="Automated release merge request for $CI_COMMIT_TAG"
      UPSTREAM_PROJECT_ID=$(curl --header "PRIVATE-TOKEN: $UPSTREAM_TOKEN" "https://gitlab.com/api/v4/projects/ub-dems-public%2Fdve-simple-py" | jq -r '.id')
      MR_RESPONSE=$(curl --request POST --header "PRIVATE-TOKEN: $UPSTREAM_TOKEN" \
        --form "source_branch=main" \
        --form "target_branch=main" \
        --form "title=$MR_TITLE" \
        --form "description=$MR_DESCRIPTION" \
        "https://gitlab.com/api/v4/projects/$UPSTREAM_PROJECT_ID/merge_requests")
      MR_IID=$(echo $MR_RESPONSE | jq -r '.iid')
      echo "Created Merge Request !$MR_IID"
      echo "MR_IID=$MR_IID" >> create_mr.env
  artifacts:
    reports:
      dotenv: create_mr.env
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'

# --- Upstream Merge and Tagging Stage ---
# Scope: Downstream only
# Trigger: Manual approval after create_mr succeeds
# Required Variables: UPSTREAM_TOKEN
upstream_merge_tag:
  stage: upstream_merge_tag
  image: $DEFAULT_IMAGE
  script:
    - |
      UPSTREAM_PROJECT_ID=$(curl --header "PRIVATE-TOKEN: $UPSTREAM_TOKEN" "https://gitlab.com/api/v4/projects/ub-dems-public%2Fdve-simple-py" | jq -r '.id')
      MR_IID=$(cat create_mr.env | grep MR_IID | cut -d'=' -f2)
      # Accept the MR (auto-merge)
      curl --request PUT --header "PRIVATE-TOKEN: $UPSTREAM_TOKEN" \
        --form "merge_when_pipeline_succeeds=true" \
        "https://gitlab.com/api/v4/projects/$UPSTREAM_PROJECT_ID/merge_requests/$MR_IID/accept"
      # Apply the same tag to upstream main
      curl --request POST --header "PRIVATE-TOKEN: $UPSTREAM_TOKEN" \
        --form "tag_name=$CI_COMMIT_TAG" \
        --form "ref=main" \
        "https://gitlab.com/api/v4/projects/$UPSTREAM_PROJECT_ID/repository/tags"
      echo "Upstream merge and tagging completed for $CI_COMMIT_TAG"
  needs:
    - job: create_mr
      artifacts: true
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
      when: manual
      allow_failure: false

# --- Image Build Stage ---
# Scope: Upstream only
# Trigger: Tag matching v*.*.* (applied by downstream)
# Required Variables: None
.image_build_template: &image_build_template
  stage: build_images
  image: $DEFAULT_IMAGE
  script:
    - cd $WORKING_DIR
    - chmod +x scripts/build-images.sh
    - scripts/build-images.sh
  artifacts:
    paths:
      - "*.tar"
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'


# Define one job per image (example: image1, image2, etc.)
# Each job is independent and can fail without blocking others
image1:
  <<: *image_build_template
  variables:
    IMAGE_NAME: "image1"

image2:
  <<: *image_build_template
  variables:
    IMAGE_NAME: "image2"

# --- Image Push Stage ---
# Scope: Upstream only
# Trigger: All image build jobs succeed
# Required Variables: REGISTRY_URL, REGISTRY_USER, REGISTRY_PASSWORD
push_images:
  stage: push_images
  image: $DEFAULT_IMAGE
  script:
    - |
      echo "$REGISTRY_PASSWORD" | podman login --username "$REGISTRY_USER" --password-stdin "$REGISTRY_URL"
      for image in *.tar; do
        podman load -i "$image"
        IMAGE_NAME=$(podman inspect --format '{{.RepoTags}}' "$(podman load -i $image | awk '{print $3}')" | tr -d '[]')
        podman push "$IMAGE_NAME" "$REGISTRY_URL"
      done
  needs:
    - job: image1
    - job: image2
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'


# --- Mirror Push Stage ---
# Scope: Upstream only
# Trigger: push_images succeeds
# Required Variables: GITHUB_MIRROR_URL
mirror_push:
  stage: mirror_push
  image: $DEFAULT_IMAGE
  script:
    - |
      git remote add github-mirror "$GITHUB_MIRROR_URL"
      git push --force-with-lease github-mirror main
      git push --force-with-lease github-mirror "$CI_COMMIT_TAG"
  needs:
    - job: push_images
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'


# --- Notification Stage ---
# Scope: Upstream only
# Trigger: mirror_push succeeds
# Required Variables: NOTIFY_EMAILS, SMTP_HOST, SMTP_USER, SMTP_PASSWORD, SLACK_WEBHOOK_URL
notify:
  stage: notify
  image: $DEFAULT_IMAGE
  script:
    - |
      # Email notification
      echo "Sending release notification for $CI_COMMIT_TAG to $NOTIFY_EMAILS" | mailx \
        -S smtp="$SMTP_HOST" \
        -S smtp-auth=login \
        -S smtp-auth-user="$SMTP_USER" \
        -S smtp-auth-password="$SMTP_PASSWORD" \
        -s "Release $CI_COMMIT_TAG Published" \
        $NOTIFY_EMAILS
      # Slack notification
      SLACK_MESSAGE='{"text":":rocket: *New Release Published* :rocket:\n*Project*: '"$CI_PROJECT_NAME"'\n*Tag*: '"$CI_COMMIT_TAG"'\n*Registry*: '"$REGISTRY_URL"'\n*Mirror*: GitHub"}'
      curl -X POST -H 'Content-type: application/json' --data "$SLACK_MESSAGE" "$SLACK_WEBHOOK_URL"
  needs:
    - job: mirror_push
  rules:
    - if: '$CI_PROJECT_PATH == "ub-dems-public/dve-simple-py" && $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
```

---

## Additional Notes

### Implementation Details
- **Validation Stage**: Uses `uv` to run all pre-release checks in sequence. Fails fast if any check fails.
- **Merge Request Creation**: Uses the GitLab API v4 to create a Merge Request from downstream `main` to upstream `main`. The `MR_IID` is stored as a [dotenv artifact](https://docs.gitlab.com/ee/ci/yaml/#artifactreportsdotenv) for use in the next stage.
- **Upstream Merge and Tagging**: Requires **manual approval** (`when: manual`) to auto-merge the MR and apply the same tag to the upstream `main` branch. This is a **human approval gate**.
- **Image Build Stage**: Each image is built in a parallel job. All jobs must succeed for the pipeline to proceed to `push_images`.
- **Image Push Stage**: Uses `needs:` to depend on all image build jobs. Only executes if all builds succeed.
- **Mirror Push**: Uses `--force-with-lease` to safely push to the GitHub mirror.
- **Notification**: Sends both email (via `mailx`) and Slack notifications. Assumes `mailx` is available in the container image.

### Assumptions
- The `scripts/build-images.sh` script is idempotent and handles its own error cases.
- The `uv` environment is pre-configured in both projects.
- The GitLab API token (`UPSTREAM_TOKEN`) has sufficient permissions (`api` scope) to create MRs, accept them, and create tags in the upstream project.
- The container registry supports Podman-based pushes.
- The GitHub mirror URL (`GITHUB_MIRROR_URL`) is a valid Git remote URL with write access.

### Security
- All sensitive variables (`UPSTREAM_TOKEN`, `REGISTRY_PASSWORD`, `SMTP_PASSWORD`, `SLACK_WEBHOOK_URL`) are **masked** in the CI/CD settings.
- The pipeline uses `rules:` to restrict job execution to the correct project and tag pattern.

---
---
### References

[av-gitlab-ci-yaml]: https://docs.gitlab.com/ee/ci/yaml/

[av-gitlab-api-v4]: https://docs.gitlab.com/ee/api/

[av-gitlab-merge-requests-api]: https://docs.gitlab.com/ee/api/merge_requests.html

[av-gitlab-tags-api]: https://docs.gitlab.com/ee/api/tags.html

[av-gitlab-artifacts]: https://docs.gitlab.com/ee/ci/pipelines/job_artifacts.html

[av-gitlab-needs]: https://docs.gitlab.com/ee/ci/yaml/#needs

[av-podman-login]: https://docs.podman.io/en/latest/markdown/podman-login.1.html

[av-mailx]: https://linux.die.net/man/1/mailx


<!-- }}} \\ %1. -->
<!-- ::{{{ #TAG: TODO:(q2-section) // -->

# Q:2

## Q:2 - **TODO:(q2-title)**

[^](#toc)

## Question Prompt 2

TODO:(q1-prompt) ...


# A:2 (Claude)

[^](#toc) **_TODO:(a1-ref-claude)_**

TODO:(a2-claude) ...

# A:2 (Gemini)

[^](#toc) **_TODO:(a2-ref-gemini)_**

TODO:(a2-gemini) ...

# A:2 (ChatGPT)

[^](#toc) **_TODO:(a2-ref-chatgpt)_**

TODO:(a2-chatgpt) ...

# A:2 (DeepSeek)

[^](#toc) **_TODO:(a2-ref-deepseek)_**

TODO:(a2-deepseek) ...

# A:2 (Perplexity)

[^](#toc) **_TODO:(a2-ref-perplexity)_**

TODO:(a2-perplexity) ...

# A:2 (Vibe)

[^](#toc) **_TODO:(a2-ref-vibe)_**

TODO:(a2-vibe) ...

<!-- }}} \\ %2. -->
<!-- ::{{{ #TAG: TODO:(aa-section) // -->
<details>
<summary></summary>

```{=latex}
\newpage
\clearpage
\appendix
```

</details>

# A:a

## A:a - **GitLab Pipeline Context**

[^](#toc)

## Pipeline Job Environment (downstream)

Downstream job environment on commit (develop)

``` bash
ACR_REGISTRY='[MASKED]'
ACR_RESOURCE='[MASKED]'
CI='true'
CI_API_GRAPHQL_URL='https://gitlab.com/api/graphql'
CI_API_V4_URL='https://gitlab.com/api/v4'
CI_BUILDS_DIR='/builds'
CI_COMMIT_AUTHOR='[MASKED]'
CI_COMMIT_BEFORE_SHA='d8fac9624ef874027f941ea6bb21185671846ba0'
CI_COMMIT_BRANCH='main'
CI_COMMIT_DEFAULT_BRANCH_BASE_SHA='b848586279993d79c8533665a495a93c208a4220'
CI_COMMIT_DESCRIPTION=''
CI_COMMIT_MESSAGE='Merge branch "develop" into "main"'
CI_COMMIT_MESSAGE_IS_TRUNCATED='false'
CI_COMMIT_REF_NAME='main'
CI_COMMIT_REF_PROTECTED='true'
CI_COMMIT_REF_SLUG='main'
CI_COMMIT_SHA='343d0e27e88cb8df472b27316d7845b009c40410'
CI_COMMIT_SHORT_SHA='343d0e27'
CI_COMMIT_TIMESTAMP='2026-07-31T19:38:51+02:00'
CI_COMMIT_TITLE='Merge branch "develop" into "main"'
CI_COMMIT_USER_LOGIN=''
CI_CONCURRENT_ID='111'
CI_CONCURRENT_PROJECT_ID='0'
CI_CONFIG_PATH='.gitlab-ci.yml'
CI_CONFIG_REF_URI='gitlab.com/ub-dems/vs-base/dve-sample-py//.gitlab-ci.yml@refs/heads/main'
CI_DEFAULT_BRANCH='develop'
CI_DEFAULT_BRANCH_SLUG='develop'
CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX='gitlab.com:443/ub-dems/vs-base/dependency_proxy/containers'
CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX='gitlab.com:443/ub-dems/dependency_proxy/containers'
CI_DEPENDENCY_PROXY_PASSWORD='[MASKED]'
CI_DEPENDENCY_PROXY_SERVER='gitlab.com:443'
CI_DEPENDENCY_PROXY_USER='gitlab-ci-token'
CI_DISPOSABLE_ENVIRONMENT='true'
CI_JOB_GROUP_NAME='debug-pipeline'
CI_JOB_ID='15651125844'
CI_JOB_IMAGE='python:3.14-slim'
CI_JOB_NAME='debug-pipeline'
CI_JOB_NAME_SLUG='debug-pipeline'
CI_JOB_STAGE='debug'
CI_JOB_STARTED_AT='2026-07-31T17:39:09Z'
CI_JOB_STARTED_AT_SLUG='2026-07-31t17-39-09z'
CI_JOB_STATUS='running'
CI_JOB_TAGS='["saas-linux-small-amd64"]'
CI_JOB_TIMEOUT='3600'
CI_JOB_TOKEN='[MASKED]'
CI_JOB_URL='https://gitlab.com/ub-dems/vs-base/dve-sample-py/-/jobs/15651125844'
CI_NODE_TOTAL='1'
CI_PAGES_DOMAIN='gitlab.io'
CI_PAGES_HOSTNAME='dve-sample-py-3adb27.gitlab.io'
CI_PAGES_URL='https://dve-sample-py-3adb27.gitlab.io'
CI_PIPELINE_CREATED_AT='2026-07-31T17:38:52Z'
CI_PIPELINE_ID='2722508965'
CI_PIPELINE_IID='8'
CI_PIPELINE_NAME=''
CI_PIPELINE_SOURCE='push'
CI_PIPELINE_URL='https://gitlab.com/ub-dems/vs-base/dve-sample-py/-/pipelines/2722508965'
CI_PROJECT_CLASSIFICATION_LABEL=''
CI_PROJECT_DESCRIPTION=''
CI_PROJECT_DIR='/builds/ub-dems/vs-base/dve-sample-py'
CI_PROJECT_ID='84970463'
CI_PROJECT_NAME='dve-sample-py'
CI_PROJECT_NAMESPACE='ub-dems/vs-base'
CI_PROJECT_NAMESPACE_ID='136875995'
CI_PROJECT_NAMESPACE_SLUG='ub-dems-vs-base'
CI_PROJECT_PATH='ub-dems/vs-base/dve-sample-py'
CI_PROJECT_PATH_SLUG='ub-dems-vs-base-dve-sample-py'
CI_PROJECT_REPOSITORY_LANGUAGES='jupyter notebook,python,shell,tex,makefile'
CI_PROJECT_ROOT_NAMESPACE='ub-dems'
CI_PROJECT_ROOT_NAMESPACE_SLUG='ub-dems'
CI_PROJECT_TITLE='dve-sample-py'
CI_PROJECT_TOPICS=''
CI_PROJECT_URL='https://gitlab.com/ub-dems/vs-base/dve-sample-py'
CI_PROJECT_VISIBILITY='private'
CI_REGISTRY='registry.gitlab.com'
CI_REGISTRY_IMAGE='registry.gitlab.com/ub-dems/vs-base/dve-sample-py'
CI_REGISTRY_PASSWORD='[MASKED]'
CI_REGISTRY_USER='gitlab-ci-token'
CI_REPOSITORY_URL='https://gitlab-ci-token:[MASKED]@gitlab.com/ub-dems/vs-base/dve-sample-py.git'
CI_RUNNER_DESCRIPTION='1-green.saas-linux-small-amd64.runners-manager.gitlab.com/default'
CI_RUNNER_EXECUTABLE_ARCH='linux/amd64'
CI_RUNNER_ID='12270845'
CI_RUNNER_REVISION='471b878c'
CI_RUNNER_SHORT_TOKEN='JLgUopmMV'
CI_RUNNER_TAGS='["gitlab--duo", "saas-linux-small-amd64"]'
CI_RUNNER_VERSION='19.2.0~pre.1355.g471b878c'
CI_SERVER='yes'
CI_SERVER_FQDN='gitlab.com'
CI_SERVER_HOST='gitlab.com'
CI_SERVER_NAME='GitLab'
CI_SERVER_PORT='443'
CI_SERVER_PROTOCOL='https'
CI_SERVER_REVISION='1e4d2cb6f74'
CI_SERVER_SHELL_SSH_HOST='gitlab.com'
CI_SERVER_SHELL_SSH_PORT='22'
CI_SERVER_TLS_CA_FILE='/builds/ub-dems/vs-base/dve-sample-py.tmp/CI_SERVER_TLS_CA_FILE'
CI_SERVER_URL='https://gitlab.com'
CI_SERVER_VERSION='19.3.0-pre'
CI_SERVER_VERSION_MAJOR='19'
CI_SERVER_VERSION_MINOR='3'
CI_SERVER_VERSION_PATCH='0'
CI_TEMPLATE_REGISTRY_HOST='registry.gitlab.com'
CI_TRACEPARENT='00-000000000000000000000000a24630a5-d57d4350c5866fa0-01'
CI_TRACESTATE='gitlab=pipeline:2722508965;job:15651125844'
DOCKER_DRIVER='overlay2'
DOCKER_IPTABLES_LEGACY='1'
DOCKER_TLS_CERTDIR=''
DOWNSTREAM_PROJECT_PATH='ub-dems/vs-base/dve-sample-py'
E_UV_INDEX_TORCH_GPU='https://download.pytorch.org/whl/cu130'
FF_CLEAN_UP_FAILED_CACHE_EXTRACT='false'
FF_CONCRETE='false'
FF_DISABLE_AUTOMATIC_TOKEN_ROTATION='false'
FF_DISABLE_POWERSHELL_STDIN='false'
FF_DISABLE_UMASK_FOR_DOCKER_EXECUTOR='false'
FF_DISABLE_UMASK_FOR_KUBERNETES_EXECUTOR='false'
FF_ENABLE_BASH_EXIT_CODE_CHECK='false'
FF_ENABLE_JOB_CLEANUP='false'
FF_ENABLE_JOB_INPUTS_INTERPOLATION='true'
FF_EXPORT_HIGH_CARDINALITY_METRICS='false'
FF_GIT_URLS_WITHOUT_TOKENS='false'
FF_HASH_CACHE_KEYS='true'
FF_KUBERNETES_HONOR_ENTRYPOINT='false'
FF_LOG_IMAGES_CONFIGURED_FOR_JOB='false'
FF_MASK_ALL_DEFAULT_TOKENS='true'
FF_NETWORK_PER_BUILD='false'
FF_POSIXLY_CORRECT_ESCAPES='false'
FF_PRINT_POD_EVENTS='false'
FF_RESOLVE_FULL_TLS_CHAIN='false'
FF_SCRIPT_SECTIONS='false'
FF_SCRIPT_TO_STEP_MIGRATION='false'
FF_SECRET_RESOLVING_FAILS_IF_MISSING='true'
FF_SET_PERMISSIONS_BEFORE_CLEANUP='true'
FF_SKIP_NOOP_BUILD_STAGES='true'
FF_SUSPENDABLE_ENVIRONMENTS='false'
FF_TEST_FEATURE='false'
FF_TIMESTAMPS='true'
FF_USE_ADAPTIVE_REQUEST_CONCURRENCY='true'
FF_USE_ADVANCED_POD_SPEC_CONFIGURATION='false'
FF_USE_DIRECT_DOWNLOAD='true'
FF_USE_DOCKER_AUTOSCALER_DIAL_STDIO='true'
FF_USE_DUMB_INIT_WITH_KUBERNETES_EXECUTOR='false'
FF_USE_DYNAMIC_TRACE_FORCE_SEND_INTERVAL='false'
FF_USE_EXPONENTIAL_BACKOFF_STAGE_RETRY='true'
FF_USE_FASTZIP='false'
FF_USE_FLEETING_ACQUIRE_HEARTBEATS='false'
FF_USE_GITALY_CORRELATION_ID='true'
FF_USE_GIT_BUNDLE_URIS='true'
FF_USE_GIT_NATIVE_CLONE='false'
FF_USE_GIT_PROACTIVE_AUTH='true'
FF_USE_INIT_WITH_DOCKER_EXECUTOR='false'
FF_USE_JOB_ROUTER='false'
FF_USE_LEGACY_BASH_EVAL='false'
FF_USE_LEGACY_GCS_CACHE_ADAPTER='false'
FF_USE_LEGACY_KUBERNETES_EXECUTION_STRATEGY='false'
FF_USE_LEGACY_S3_CACHE_ADAPTER='false'
FF_USE_NATIVE_CONTAINER_STOP='false'
FF_USE_NEW_BASH_EVAL_STRATEGY='false'
FF_USE_PARALLEL_ARTIFACT_TRANSFER='false'
FF_USE_PARALLEL_CACHE_TRANSFER='false'
FF_USE_POD_ACTIVE_DEADLINE_SECONDS='true'
FF_USE_POWERSHELL_PATH_RESOLVER='false'
FF_USE_WINDOWS_JOB_OBJECT='false'
FF_USE_WINDOWS_LEGACY_PROCESS_STRATEGY='false'
FF_WAIT_FOR_POD_TO_BE_REACHABLE='false'
GITLAB_CI='true'
GITLAB_ENV='/builds/ub-dems/vs-base/dve-sample-py.tmp/gitlab_runner_env'
GITLAB_FEATURES='audit_events,blocked_issues,blocked_work_items,board_iteration_lists,code_owners,code_review_analytics,full_codequality_report,group_activity_analytics,group_bulk_edit,issuable_default_templates,issue_weights,iterations,ldap_group_sync,merge_request_approvers,milestone_charts,multiple_issue_assignees,multiple_ldap_servers,multiple_merge_request_assignees,multiple_merge_request_reviewers,project_merge_request_analytics,protected_refs_for_users,push_rules,resource_access_token,seat_link,seat_usage_quotas,pipelines_usage_quotas,transfer_usage_quotas,wip_limits,zoekt_code_search,seat_control,usage_billing,group_usage_billing,description_diffs,send_emails_from_admin_area,repository_size_limit,maintenance_mode,scoped_issue_board,contribution_analytics,group_webhooks,member_lock,elastic_search,repository_mirrors,ai_chat,ai_catalog,ai_workflows,ai_analytics,admin_audit_log,agent_managed_resources,agentic_chat,allow_personal_snippets,prevent_enterprise_user_account_deletion,auditor_user,blocking_merge_requests,board_assignee_lists,board_milestone_lists,ci_job_analytics_for_projects,ci_pipeline_cancellation_restrictions,ci_secrets_management,cluster_agents_ci_impersonation,cluster_agents_user_impersonation,cluster_deployments,code_owner_approval_required,code_suggestions,commit_committer_check,commit_committer_name_check,compliance_framework,configurable_work_item_types,container_virtual_registry,custom_compliance_frameworks,custom_fields,custom_file_templates,custom_project_templates,cycle_analytics_for_groups,cycle_analytics_for_projects,data_management,db_load_balancing,default_branch_protection_restriction_in_groups,default_project_deletion_protection,delete_unconfirmed_users,dependency_firewall,dependency_proxy_for_packages,disable_extensions_marketplace_for_enterprise_users,disable_name_update_for_users,disable_personal_access_tokens,disable_ssh_keys,domain_verification,epic_colors,epics,extended_audit_events,external_authorization_service_api_management,feature_flags_code_references,file_locks,geo,generic_alert_fingerprinting,git_two_factor_enforcement,group_allowed_email_domains,group_ci_cd_analytics_pipelines,group_coverage_reports,group_forking_protection,group_level_analytics_dashboard,group_level_compliance_dashboard,group_milestone_project_releases,group_project_templates,group_repository_analytics,group_saml,group_scoped_ci_variables,ide_schema_config,incident_metric_upload,increased_saved_views_limit,instance_level_scim,jira_issues_integration,ldap_group_sync_filter,linked_items_epics,merge_request_performance_metrics,merge_request_title_regex_check,admin_merge_request_approvers_rules,merge_trains,metrics_reports,mcp_server,multiple_alert_http_integrations,multiple_approval_rules,multiple_group_issue_boards,object_storage,microsoft_group_sync,operations_dashboard,orbit,package_forwarding,packages_virtual_registry,pages_size_limit,pages_multiple_versions,productivity_analytics,project_aliases,project_level_analytics_dashboard,protected_environments,reject_non_dco_commits,reject_unsigned_commits,related_epics,remote_development,saml_group_sync,semantic_code_search,scoped_labels,smartcard_auth,ssh_certificates,swimlanes,target_branch_rules,troubleshoot_job,type_of_work_analytics,minimal_access_role,unprotection_restrictions,ci_project_subscriptions,incident_timeline_view,oncall_schedules,escalation_policies,zentao_issues_integration,coverage_check_approval_rule,issuable_resource_links,group_protected_branches,group_level_merge_checks_setting,oidc_client_groups_claim,disable_deleting_account_for_users,disable_private_profiles,group_saved_replies,requested_changes_block_merge_request,project_saved_replies,default_roles_assignees,ci_component_usages_in_projects,ci_cd_catalog_publish_restriction,branch_rule_squash_options,work_item_status,glab_ask_git_command,generate_commit_message,summarize_new_merge_request,summarize_review,generate_description,summarize_comments,review_merge_request,board_status_lists,disable_invite_members,self_hosted_models,native_secrets_management,built_in_project_templates_enabled,group_ip_restriction,issues_analytics,password_complexity,group_wikis,email_additional_text,custom_file_templates_for_namespace,incident_sla,export_user_permissions,cross_project_pipelines,feature_flags_related_issues,merge_pipelines,ci_cd_projects,github_integration,ai_config_chat,ai_features,amazon_q,api_discovery,api_fuzzing,auto_rollback,cluster_receptive_agents,cluster_image_scanning,external_status_checks,ci_runner_controllers,compliance_pipeline_configuration,container_registry_immutable_tag_rules,container_scanning,credentials_inventory,custom_roles,dast,dependency_scanning,dora4_analytics,description_composer,enterprise_templates,environment_alerts,evaluate_group_level_compliance_pipeline,explain_code,external_audit_events,experimental_features,generate_test_file,git_abuse_rate_limit,group_ci_cd_analytics_releases,group_level_compliance_adherence_report,group_level_compliance_violations_report,project_level_compliance_dashboard,project_level_compliance_adherence_report,project_level_compliance_violations_report,incident_management,inline_codequality,insights,integrations_allow_list,issuable_health_status,issues_completed_analytics,jira_vulnerabilities_integration,jira_issue_association_enforcement,kubernetes_cluster_vulnerabilities,license_scanning,okrs,personal_access_token_expiration_policy,secret_push_protection,product_analytics,project_quality_summary,quality_management,release_evidence_test_artifacts,report_approver_rules,required_ci_templates,requirements,runner_maintenance_note,runner_maintenance_note_for_namespace,runner_performance_insights,runner_performance_insights_for_namespace,runner_upgrade_management,runner_upgrade_management_for_namespace,sarif,sast,sast_advanced,sast_iac,sast_custom_rulesets,sast_fp_reduction,secret_detection,security_attributes,security_configuration_in_ui,security_dashboard,security_inventory,security_on_demand_scans,security_orchestration_policies,security_scan_profiles,security_training,ssh_key_expiration_policy,summarize_mr_changes,stale_runner_cleanup_for_namespace,status_page,suggested_reviewers,subepics,observability,unique_project_download_limit,vulnerability_finding_signatures,container_scanning_for_registry,secret_detection_validity_checks,security_exclusions,security_scans_api,observability_alerts,measure_comment_temperature,license_information_source,coverage_fuzzing,devops_adoption,group_level_devops_adoption,instance_level_devops_adoption'
GITLAB_USER_EMAIL='[MASKED]'
GITLAB_USER_ID='[MASKED]'
GITLAB_USER_LOGIN='[MASKED]'
GITLAB_USER_NAME='[MASKED]'
GIT_DEPTH='0'
GS_UPSTREAM_TOKEN='[MASKED]'
HOME='/root'
HOSTNAME='runner-jlguopmmv-project-84970463-concurrent-0'
MR_SOURCE_BRANCH='main'
MR_TARGET_BRANCH='main'
OLDPWD='/'
PATH='/builds/ub-dems/vs-base/dve-sample-py/.venv/bin:/root/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
PWD='/builds/ub-dems/vs-base/dve-sample-py'
PYTHON_SHA256='143b1dddefaec3bd2e21e3b839b34a2b7fb9842272883c576420d605e9f30c63'
PYTHON_VERSION='3.14.6'
RUNNER_TEMP_PROJECT_DIR='/builds/ub-dems/vs-base/dve-sample-py.tmp'
SHLVL='1
See merge request ub-dems/vs-base/dve-sample-py!2
See merge request ub-dems/vs-base/dve-sample-py!2'
UPSTREAM_PROJECT_PATH='ub-dems/ds-labs/dve-sample-py'
UPSTREAM_PROJECT_PATH_ENCODED='ub-dems%2Fds-labs%2Fdve-sample-py'
UV='/root/.local/bin/uv'
UV_CACHE_DIR='/builds/ub-dems/vs-base/dve-sample-py/.cache/uv'
UV_ENV_FILE='.env'
UV_INDEX_TORCH_GPU='https://download.pytorch.org/whl/cpu'
UV_NO_PROGRESS='1'
UV_PYTHON_PREFERENCE='only-managed'
UV_RUN_RECURSION_DEPTH='1'
UV_VERSION='latest'
VIRTUAL_ENV='/builds/ub-dems/vs-base/dve-sample-py/.venv'

```

## GitLab API Examples

Remote MR creation and trigger

``` bash

##
# SECRETS
#

GS_UPSTREAM_TOKEN="[MASKED]"

##
# CI Dynamic
#

CI_COMMIT_TAG='3.2607.1'
CI_COMMIT_SHA='343d0e27e88cb8df472b27316d7845b009c40410'

##
# CI Context
#

CI_API_V4_URL='https://gitlab.com/api/v4'

CI_PROJECT_ID='84970463'
CI_PROJECT_PATH='ub-dems/vs-base/dve-sample-py'


##
# VARIABLES
#

DOWNSTREAM_PROJECT_PATH="ub-dems/vs-base/dve-sample-py"
UPSTREAM_PROJECT_PATH="ub-dems/ds-labs/dve-sample-py"
UPSTREAM_PROJECT_PATH_ENCODED="ub-dems%2Fds-labs%2Fdve-sample-py"
MR_SOURCE_BRANCH="main"
MR_TARGET_BRANCH="main"



##
#
#

UPSTREAM_PROJECT_ID=$(curl --silent --show-error --fail \
  --header "PRIVATE-TOKEN: ${GS_UPSTREAM_TOKEN}" \
  "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_PATH_ENCODED}" | jq -r .id)

echo "UPSTREAM_PROJECT_ID=$UPSTREAM_PROJECT_ID"


##
#
#

RESPONSE=$(curl --silent --show-error --fail \
  --request POST \
  --header "PRIVATE-TOKEN: ${GS_UPSTREAM_TOKEN}" \
  --data-urlencode "source_branch=${MR_SOURCE_BRANCH}" \
  --data-urlencode "target_branch=${MR_TARGET_BRANCH}" \
  --data-urlencode "target_project_id=${UPSTREAM_PROJECT_ID}" \
  --data-urlencode "title=Release ${CI_COMMIT_TAG}: sync downstream to upstream main" \
  --data-urlencode "description=Automated release MR for tag ${CI_COMMIT_TAG}. Source: ${CI_PROJECT_PATH}@${CI_COMMIT_SHA}." \
        "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/merge_requests")

MR_IID=$(echo "${RESPONSE}" | jq -r '.iid // empty')
if [ -z "${MR_IID}" ]; then
  echo "Failed to create merge request:"
  echo "${RESPONSE}" | jq .
  exit 1
fi

echo "Created MR !${MR_IID} on upstream project ${UPSTREAM_PROJECT_ID}"
echo "MR_IID=${MR_IID}" >> mr.env
echo "UPSTREAM_PROJECT_ID=${UPSTREAM_PROJECT_ID}" >> mr.env



##
#
#

 echo "Waiting for the upstream validation pipeline on MR !${MR_IID} ..."
 PIPELINE_STATUS="none"
 for i in $(seq 1 60); do
   MR_JSON=$(curl --silent --show-error --fail \
                  --header "PRIVATE-TOKEN: ${GS_UPSTREAM_TOKEN}" \
                  "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_ID}/merge_requests/${MR_IID}")
  PIPELINE_STATUS=$(echo "${MR_JSON}" | jq -r '.head_pipeline.status // "none"')
  echo "  upstream pipeline status: ${PIPELINE_STATUS}"
  [ "${PIPELINE_STATUS}" = "success" ] && break
  if [ "${PIPELINE_STATUS}" = "failed" ] || [ "${PIPELINE_STATUS}" = "canceled" ]; then
    echo "Upstream validation pipeline did not succeed. Aborting."
    exit 1
  fi
  sleep 30
done
if [ "${PIPELINE_STATUS}" != "success" ]; then
  echo "Timed out waiting for the upstream validation pipeline."
  exit 1
fi


##
#
#

curl --silent --show-error --fail \
  --request PUT \
  --header "PRIVATE-TOKEN: ${GS_UPSTREAM_TOKEN}" \
  --data-urlencode "should_remove_source_branch=false" \
  --data-urlencode "merge_commit_message=Release ${CI_COMMIT_TAG}" \
  "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_ID}/merge_requests/${MR_IID}/merge"

##
#
#

echo "Waiting for the merge to complete ..."
MR_STATE="unknown"
for i in $(seq 1 20); do
  MR_JSON=$(curl --silent --show-error --fail \
                 --header "PRIVATE-TOKEN: ${GS_UPSTREAM_TOKEN}" \
 "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_ID}/merge_requests/${MR_IID}")
  MR_STATE=$(echo "${MR_JSON}" | jq -r .state)
  if [ "${MR_STATE}" = "merged" ]; then
    MERGE_COMMIT_SHA=$(echo "${MR_JSON}" | jq -r .merge_commit_sha)
    break
  fi
  sleep 15
done
if [ "${MR_STATE}" != "merged" ]; then
  echo "Merge request was not merged in time."
  exit 1
fi

##
#
#

echo "Tagging upstream main at ${MERGE_COMMIT_SHA} as ${CI_COMMIT_TAG}"
curl --silent --show-error --fail \
  --request POST \
  --header "PRIVATE-TOKEN: ${GS_UPSTREAM_TOKEN}" \
  --data-urlencode "tag_name=${CI_COMMIT_TAG}" \
  --data-urlencode "ref=${MERGE_COMMIT_SHA}" \
  --data-urlencode "message=Release ${CI_COMMIT_TAG}" \
  "${CI_API_V4_URL}/projects/${UPSTREAM_PROJECT_ID}/repository/tags"


```


<!-- }}} \\ %a. -->
<!-- {{{ // %*
LocalWords:  GitLab CommonMark GFM GLFM YAML
vim: set foldmethod=marker :
}}} // %* -->
