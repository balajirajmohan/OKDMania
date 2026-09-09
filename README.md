# OKDMania

Four-week production-scale POC: evaluate [OKD](https://okd.io/) on AWS as an enterprise platform, GitOps-deploy the [OpenTelemetry Demo](https://opentelemetry.io/docs/demo/), then prove security, observability, and self-healing.

This README is the **single tracker**. Every architecture, tool, and process call is logged here. Progress is ticked here. Do not keep a parallel spreadsheet or Slack-only decision.

| | |
|---|---|
| **Current week** | Week 0 — bootstrap (cluster not started) |
| **Current focus** | Team picks tools (T01–T22). Infra decisions D007–D015 still Proposed. |
| **Cluster** | Not installed |
| **Last updated** | 2026-09-09 · Balaji BR |
| **Repo** | https://github.com/balajirajmohan/OKDMania |

---

## Where we are

```
Week 0 ████████░░░░░░░░░░░░  bootstrap / decisions
Week 1 ░░░░░░░░░░░░░░░░░░░░  OKD + AWS infra
Week 2 ░░░░░░░░░░░░░░░░░░░░  workload + GitOps
Week 3 ░░░░░░░░░░░░░░░░░░░░  security + observability
Week 4 ░░░░░░░░░░░░░░░░░░░░  chaos + assessment
```

| Stream | Status | Blocker |
|---|---|---|
| Decisions | Scope locked. Tools are **options**, not picks yet | Fill **Team pick** on T01–T22 |
| GitHub repo | Empty besides this README | Invite `deepan011`, `umeshkumaarjj-dev` |
| AWS account / DNS | Unknown | Need Route 53 zone + quotas |
| OKD cluster | Not started | Depends on DNS + IAM |
| Argo CD | Not started | Depends on cluster |
| OTel Demo | Not started | Depends on GitOps |
| Security gates | Not started | Depends on repo + CI |
| Chaos | Not started | Depends on workload baseline |

**Next concrete actions**

- [ ] Confirm public Route 53 hosted zone (authoritative NS)
- [ ] Confirm AWS region, account, and instance quotas
- [ ] Invite GitHub users `deepan011` and `umeshkumaarjj-dev`
- [ ] Export Confluence task page into `docs/` (login-gated from tooling)
- [ ] For each T01–T22 row, write the **Team pick** (or `Skip`) and lock the matching D-id
- [ ] Review infra **Proposed** rows D007–D015; lock or supersede
- [ ] Decide 24/7 cluster vs destroy-at-night (cost)

---

## How to use this file

1. **Where we are** is updated on every meaningful change (same PR as the work).
2. **Decision log** is append-only. Never delete a row. To change a call, set the old row to `Superseded` and add a new ID that points at it.
3. **Tool options (T01–T22)** are the menu. Research rec is not a decision. A tool is chosen only when **Team pick** is filled and the matching D-row is set to `Locked`.
4. Pick **one primary** per layer. A complementary pair is allowed only where the table says `pair OK` (example: gitleaks + TruffleHog).
5. Tick checkboxes `- [ ]` → `- [x]` when the work is in `main`, not when someone started it.
6. Status words only: `Locked` · `Proposed` · `Open` · `Superseded` · `Done` · `Blocked` · `Skipped`.
7. Reference IDs in PRs (`Implements T12-A`, `Locks D019`).
8. If a discussion happens in a call or Slack, it is not a decision until it has a row here.

---

## Team

| Person | GitHub | Track |
|---|---|---|
| Balaji BR | [balajirajmohan](https://github.com/balajirajmohan) | Platform / AWS, tracker owner |
| Srikanth K | — | Scope, platform |
| Vignesh | [deepan011](https://github.com/deepan011) | CI + supply chain |
| Umesh | [umeshkumaarjj-dev](https://github.com/umeshkumaarjj-dev) | GitOps + app |

---

## Decision log

Scope from the 2026-09-09 working session and Confluence write-up **OKD - Openshift OSS** (Srikanth K / Balaji BR). Tool and install details proposed from OKD 4.21 docs, OpenTelemetry Demo docs, Argo CD docs, and CNCF landscape.

| ID | Date | Topic | Decision | Status | Owner | Why | Rejected / not now |
|---|---|---|---|---|---|---|---|
| D001 | 2026-09-09 | Platform | Evaluate **OKD** (OpenShift OSS), not vanilla K8s or EKS as the SUT | Locked | Srikanth | Written POC objective | Distro bake-off |
| D002 | 2026-09-09 | Cloud | Run the cluster on **AWS** | Locked | Srikanth | Scope: provision AWS then install OKD | GCP / Azure / bare metal for this POC |
| D003 | 2026-09-09 | Duration | **Four weeks**, then a written assessment | Locked | Srikanth | Confluence scope | Open-ended lab |
| D004 | 2026-09-09 | Workload | **OpenTelemetry Demo** as the multi-service app | Locked | Team | Polyglot, OTLP, loadgen, feature flags | Synthetic nginx; custom greenfield app |
| D005 | 2026-09-09 | GitOps family | Use an **Argo CD** family tool (flavor still open in T01) | Locked | Srikanth | Week 2 scope named Argo CD | Flux as *primary* unless team supersedes D005 |
| D006 | 2026-09-09 | Outcome | Technical assessment: what works, toil, production recommendation | Locked | Srikanth | POC is evaluation, not a forever prod cluster | Silent “it works on my cluster” |
| D007 | 2026-09-09 | OKD version | **4.21** (current release) | Proposed | Balaji | [okd.io](https://okd.io/) lists 4.21 current, 4.22 engineering candidate | 4.22 EC as the cluster of record |
| D008 | 2026-09-09 | Install method | **Terraform VPC/DNS/IAM** + **openshift-install IPI** into that VPC | Proposed | Balaji | Matches “Terraform then install”; installer already owns machines | Full UPI; SNO; Assisted Installer |
| D009 | 2026-09-09 | IAM mode | **Mint** for week 1; document **STS + ccoctl** as stretch | Proposed | Balaji | STS is more production-like but can blow week 1 | STS as a week-1 gate |
| D010 | 2026-09-09 | Topology | HA: **3 control plane + 3 workers**, 3 AZs, public API + public `*.apps` | Proposed | Balaji | Production-scale POC, not single-node | SNO; private-only API (unless security requires it) |
| D011 | 2026-09-09 | Size | Masters **m6i.xlarge**; workers **m6i.2xlarge**; 120 GB gp3 | Proposed | Balaji | Demo + Kafka + Loki will thrash official worker minimum | Default `m6i.large` workers |
| D012 | 2026-09-09 | DNS | Authoritative **public Route 53** zone required before install | Proposed | Balaji | IPI hard requirement for `api.` and `*.apps.` | DIY DNS / nip.io |
| D013 | 2026-09-09 | Region | Prefer **ap-south-1** if team is IST; confirm in D012 PR | Open | Team | Latency for console/oc | — |
| D014 | 2026-09-09 | CNI / LB | Keep **OVN-Kubernetes** + **Ingress Operator (HAProxy)** + AWS NLB | Proposed | Balaji | Replacing CNI invalidates the OKD eval | Cilium/Calico as CNI; extra mesh in W1–W2 |
| D015 | 2026-09-09 | Service discovery | **CoreDNS + Services + Routes** only | Proposed | Balaji | Kubernetes DNS is the product | Consul / extra registry |
| D016 | 2026-09-09 | GitOps flavor | Team pick from **T01** | Open | Umesh | See option board | Dual Argo+Flux |
| D017 | 2026-09-09 | App packaging | Team pick from **T01 packaging** row (Kustomize vs HelmRelease) | Open | Umesh | OTel chart cannot in-place Helm-upgrade | Long-lived `helm install` on the cluster |
| D018 | 2026-09-09 | Logs + traces | Team pick from **T14** and **T15** | Open | Team | Do not dual-run demo backends as SoT | Datadog as primary |
| D019 | 2026-09-09 | Policy | Team pick from **T12** | Open | Team | See option board | jsPolicy (unmaintained) |
| D020 | 2026-09-09 | Runtime detect | Team pick from **T13** | Open | Team | See option board | Replacing SCC with an eBPF tool |
| D021 | 2026-09-09 | Secrets | Team pick from **T10** and **T11** | Open | Vignesh | See option board | Secrets as plain YAML in Git |
| D022 | 2026-09-09 | Supply chain | Team pick from **T03–T09** | Open | Vignesh | See option board | Commercial-only SAST as the only gate |
| D023 | 2026-09-09 | Chaos | Team pick from **T18** | Open | Team | See option board | Click-ops-only experiments |
| D024 | 2026-09-09 | AI RCA | Team pick from **T19** | Open | Team | See option board | Sending kubeadmin/secrets to a public model |
| D025 | 2026-09-09 | Native-first | Prefer OKD built-ins; add CNCF only at seams | Locked | Balaji | Otherwise we are not evaluating OKD | Replacing Routes, CMO, Machine API, OAuth |
| D026 | 2026-09-09 | Tracker | This README is the decision + status system | Locked | Balaji | Team asked for tracking in the README | Side spreadsheet / Notion as SoT |
| D027 | 2026-09-09 | Cost posture | **Open** — 24/7 vs destroy-at-night (~$1.4k–2k/month if left up) | Open | Team | Control plane is not cheap | Silent always-on with no budget alarm |

---

## Tool options — team pick

Research rec is a starting point, not a lock. Fill **Team pick** with `A`, `B`, `C`, `Skip`, or a pair like `A+B` where marked. Then lock the matching D-row.

Native OKD layers (not a bake-off unless you supersede D014/D015/D025): OVN-Kubernetes, HAProxy Routes + AWS NLB, CoreDNS, OAuth, Cluster Monitoring, CRI-O/SCOS, Machine API HPA/autoscaler.

| ID | Layer | Options | Research rec | Team pick | D-id | Week |
|---|---|---|---|---|---|---|
| T01 | GitOps | A OpenShift GitOps · B upstream Argo CD · C Flux | **A** | | D016 | 2 |
| T02 | CI | A GitHub Actions · B OpenShift Pipelines/Tekton · C Jenkins | **A** (B stretch) | | D022 | 0 / 3 |
| T03 | SAST | A Semgrep · B CodeQL · C SonarQube CE | **A+B** (pair OK) | | D022 | 3 |
| T04 | DAST | A OWASP ZAP · B Nuclei · C Nikto | **A** (B optional pair) | | D022 | 3 |
| T05 | Image scan | A Trivy · B Grype · C Clair | **A** | | D022 | 3 |
| T06 | SBOM | A Syft · B Trivy SBOM · C Tern | **A** (or B if T05=A) | | D022 | 3 |
| T07 | Signing | A Cosign/Sigstore · B Notation · C GPG | **A** | | D022 | 3 |
| T08 | Dockerfile | A Hadolint · B Dockle · C Trivy config | **A** | | D022 | 0 |
| T09 | YAML / IaC | A kubeconform+Checkov · B Trivy config · C KICS | **A** | | D022 | 0 / 3 |
| T10 | Secrets in git | A gitleaks · B TruffleHog · C detect-secrets | **A+B** (pair OK) | | D021 | 0 |
| T11 | Secrets runtime | A ESO+AWS SM · B Sealed Secrets · C Vault/OpenBao · D SOPS | **A** | | D021 | 2 |
| T12 | Policy | A Kyverno · B Gatekeeper/OPA · C Kubewarden | **A** | | D019 | 3 |
| T13 | Runtime | A Falco · B Tetragon · C Tracee | **A** | | D020 | 3 |
| T14 | Logs | A Loki+Vector · B OpenSearch · C Fluent Bit+Loki | **A** | | D018 | 3 |
| T15 | Traces | A Jaeger · B Grafana Tempo · C Zipkin | **A** or **B** | | D018 | 3 |
| T16 | Metrics | A OKD CMO · B kube-prometheus extra · C VictoriaMetrics | **A** | | D018 | 1 |
| T17 | Registry | A OKD internal · B Harbor · C Quay/ECR | **A** (C if org registry exists) | | D025 | 1 |
| T18 | Chaos | A LitmusChaos · B Chaos Mesh · C AWS FIS · D Chaos Toolkit | **A** or **B** | | D023 | 4 |
| T19 | AI RCA | A k8sgpt · B HolmesGPT · C Robusta OSS | **A** then B if time | | D024 | 4 |
| T20 | Coverage | A language runners+GHA artifact · B Codecov · C Sonar coverage | **A** | | D022 | 3 |
| T21 | App scale | A HPA+MachineAutoscaler · B KEDA · C Karpenter | **A** | | D010 | 2 / 4 |
| T22 | Mesh (stretch) | A none · B OpenShift Service Mesh · C Linkerd | **A** for W1–W3 | | D014 | stretch |

---

### T01 GitOps

Both Argo CD and Flux are CNCF **graduated**. D005 already names Argo CD as the family; T01 is which distribution. Flux is the challenge option if the team supersedes D005.

| Opt | Tool | CNCF | OKD fit | Why pick | Why not |
|---|---|---|---|---|---|
| A | OpenShift GitOps Operator (Argo CD) | Argo graduated | Best — OperatorHub, console Environments, OpenShift RBAC/SSO | Lowest friction on OKD; cluster-scoped instance | Tracks Red Hat cadence, not latest upstream |
| B | Upstream Argo CD manifests | Argo graduated | Good — extra SCC/Route work | Latest Argo; same UI/AppProject model | You lose console integration; more YAML |
| C | Flux v2 (GitOps Toolkit) | Flux graduated | Good | Smaller footprint, real HelmRelease, built-in image automation, no extra UI attack surface | No first-class UI; D005 would need supersede; weaker self-service for mixed teams |

**Research rec:** A. POC is an OKD evaluation with a UI-heavy week-2 demo. Use B only if GitOps Operator is missing from OperatorHub. C only if the team wants a Flux finding vs Argo.

Packaging (ties to D017): Argo renders Helm to Git (Kustomize) because the OTel Demo chart cannot in-place upgrade. Flux could use HelmRelease instead — another reason T01 and D017 must be picked together.

---

### T02 CI

CI builds and scans; GitOps deploys. Do not make Jenkins/Tekton also the CD tool.

| Opt | Tool | Why pick | Why not |
|---|---|---|---|
| A | GitHub Actions | Repo is already GitHub; 20k+ actions; CodeQL is native; fastest week 0 | Minutes cost; less “in-cluster CI” story |
| B | OpenShift Pipelines (Tekton) | CNCF; default OpenShift CI; pipelines never leave the cluster | Verbose CRDs; extra operator; slower to first green pipeline |
| C | Jenkins | Huge plugin set | Legacy ops burden; not a CNCF story |

**Research rec:** A for the POC. Add B in week 3 as a stretch “in-cluster pipeline” finding if time.

---

### T03 SAST  · pair OK

OTel Demo is polyglot (Java, Go, .NET, JS, Python, Ruby, PHP, Rust, C++, Kotlin).

| Opt | Tool | Strength | Weakness |
|---|---|---|---|
| A | Semgrep OSS | Seconds in CI; YAML custom rules; 30+ languages | Community rules shallower than CodeQL dataflow |
| B | CodeQL | Deep semantic / taint analysis; free on public GitHub | Slower; language set narrower; GHAS cost on private repos |
| C | SonarQube Community | Quality gates, duplication, coverage dashboard | Heavier server; Community security rules thinner than paid |

**Research rec:** A+B. Semgrep on every PR; CodeQL on PR/schedule. Skip C unless you want a quality dashboard finding.

---

### T04 DAST  · pair OK (A+B)

Target is the shop Route, not localhost.

| Opt | Tool | Strength | Weakness |
|---|---|---|---|
| A | ZAP (OWASP / Checkmarx) | Full crawler + passive/active scan; SPA/Ajax; API scan | Full active scan is slow (30–90 min) |
| B | Nuclei | Fast template CVEs/misconfig; CI-friendly | Weak crawler; pair with Katana for SPAs |
| C | Nikto | Server hygiene, headers, junk files | Noisy; not app-logic DAST |

**Research rec:** A baseline (passive) on every staging deploy. Optional B as a fast extra job. C is skip unless you want a one-shot hygiene check.

---

### T05 Image scan

| Opt | Tool | Strength | Weakness |
|---|---|---|---|
| A | Trivy | One binary: image + fs + IaC + secrets + SBOM + k8s; Operator exists | Can be noisier; Java DB download can slow CI |
| B | Grype (+ Syft) | Precise matching, EPSS/KEV; SBOM-first | Vulns only — no IaC/secrets |
| C | Clair | Registry-side, layer-aware; native to Quay | Service + Postgres; weak outside Quay |

**Research rec:** A for a 4-week POC (covers T05+T06+T09 if you want fewer binaries). B as second opinion on critical images. C only if T17=C Quay.

---

### T06 SBOM

| Opt | Tool | Notes |
|---|---|---|
| A | Syft | Best SBOM-first; SPDX + CycloneDX; feeds Grype |
| B | Trivy SBOM | Fine if T05=A; fewer tools |
| C | Tern | Deep but slow; overkill here |

**Research rec:** A if you want a durable SBOM artifact; B if you already picked Trivy.

---

### T07 Image signing

| Opt | Tool | Trust model | Why pick |
|---|---|---|---|
| A | Cosign (Sigstore, graduated) | Keyless OIDC + Rekor, or keys | Default cloud-native; Kyverno `verifyImages` |
| B | Notation (Notary Project) | Enterprise X.509 / HSM / CA | If compliance demands your PKI |
| C | GPG | Classic | Poor CI and admission story |

**Research rec:** A. Keyless from GitHub OIDC. B only if the org already runs a signing CA.

---

### T08 Dockerfile

| Opt | Tool | Notes |
|---|---|---|
| A | Hadolint | Dockerfile best-practice linter; pre-commit |
| B | Dockle | CIS-ish image hardening after build |
| C | Trivy config | Already there if T05=A |

**Research rec:** A at pre-commit. B or C after image build.

---

### T09 YAML / IaC

kubeval is **deprecated**. Schema check ≠ security check — layer them.

| Opt | Tool | Role |
|---|---|---|
| A | kubeconform + Checkov | Schema first, then Terraform+Helm+K8s policies (graph checks) |
| B | Trivy config | One binary with T05; fewer policies than Checkov |
| C | KICS | Widest IaC formats; Rego queries; good if T12=B |

**Research rec:** A. Fast fail on invalid YAML, then Checkov on `infra/` and `gitops/`.

---

### T10 Secrets in git  · pair OK

| Opt | Tool | Strength | Weakness |
|---|---|---|---|
| A | gitleaks | Fast, offline, pre-commit; 150+ patterns | No live verification |
| B | TruffleHog | `--only-verified` hits provider APIs; history sweeps | AGPL; slower; verification calls out |
| C | detect-secrets | Baseline file for brownfield | This repo is empty — no baseline needed |

**Research rec:** A+B. gitleaks on commit/PR; TruffleHog verified on schedule / first history audit.

---

### T11 Secrets at runtime

| Opt | Tool | Source of truth | Why pick | Why not |
|---|---|---|---|---|
| A | External Secrets Operator + AWS Secrets Manager | AWS SM | AWS POC; rotation/audit outside Git; CNCF sandbox | Needs Reloader (or similar) to bounce pods |
| B | Sealed Secrets | Encrypted blob in Git | Simple, no AWS SM | Cluster-keyed; restore/new cluster is painful |
| C | Vault or OpenBao + VSO | Vault | Dynamic DB creds, PKI | Extra control plane; Vault BSL vs OpenBao fork |
| D | SOPS (age/KMS) | Encrypted files in Git | Flux-native; no operator | Rotation is a Git commit |

**Research rec:** A. Skip C unless you want a Vault finding. B is the backup if AWS SM is blocked.

---

### T12 Policy (admission)

jsPolicy is unmaintained — not listed.

| Opt | Tool | Language | CNCF | Why pick | Why not |
|---|---|---|---|---|---|
| A | Kyverno | YAML (+ CEL) | Incubating | Validate/mutate/generate; native Cosign verify; K8s-native | Not reusable outside K8s; Helm needs SCC `null` on OpenShift |
| B | OPA Gatekeeper | Rego | OPA graduated | Same Rego in CI, APIs, Terraform | Steep; mutation weaker; no native generate/Cosign |
| C | Kubewarden | WASM (Go/Rust) | Sandbox | Strong isolation of policies | Smaller ecosystem for a 4-week POC |

**Research rec:** A unless the org already writes Rego everywhere.

---

### T13 Runtime threat

These are complementary, not clones. Falco alerts; Tetragon can **kill in-kernel**; Tracee is forensics.

| Opt | Tool | Job | CNCF | Why pick | Why not |
|---|---|---|---|---|---|
| A | Falco | Detect + alert | Graduated | Largest rule library; Falcosidekick → Slack/Grafana | Observes, does not block |
| B | Tetragon | Observe + enforce | Cilium project | In-kernel SIGKILL; low overhead if Cilium-ish | Enforcing too early is dangerous; we are **not** replacing OVN with Cilium |
| C | Tracee | Forensics | Aqua OSS | Deep syscall timeline for IR | Heavier; weaker “day-2 SOC rules” story |

**Research rec:** A for week 3. Do not enable Tetragon kill policies until Falco is trusted. Does not replace SCC.

---

### T14 Logs

OpenShift Logging 6.x: **Vector** collector, **LokiStack** store, Elasticsearch/Kibana are legacy.

| Opt | Tool | Why pick | Why not |
|---|---|---|---|
| A | Loki Operator + Vector / ClusterLogForwarder | Native OKD path; label queries; cheap object storage | Weak full-text; ~30d short-term store |
| B | OpenSearch | Full-text, demo already ships it | Heavy RAM; duplicates demo stack; not the OKD logging strategy |
| C | Fluent Bit → Loki or S3 | Tiny collector | Vector is what OKD logging 6 uses |

**Research rec:** A. Keep demo OpenSearch **off** unless T14=B.

---

### T15 Traces

Instrument once with OTel Collector; backend is swappable.

| Opt | Tool | Why pick | Why not |
|---|---|---|---|
| A | Jaeger (v2, CNCF graduated) | Demo default; own UI; indexed tag search | Needs ES/Cassandra/memory — cost at volume |
| B | Grafana Tempo (CNCF incubating) | S3-backed, cheap; Grafana+Loki+Prometheus correlation | Weaker ad-hoc tag search without metrics/logs |
| C | Zipkin | Legacy B3 estates | Maintenance-mode for new work |

**Research rec:** A if you want the demo’s UI with less wiring. B if T14=A and you want one Grafana pane. Pick one, not both.

---

### T16 Metrics

| Opt | Tool | Notes |
|---|---|---|
| A | OKD Cluster Monitoring (Prometheus, Alertmanager, Grafana) | Enable **user workload** monitoring; this *is* the eval |
| B | Extra kube-prometheus-stack | Only if CMO cannot scrape the demo |
| C | VictoriaMetrics / Thanos | Long-term / HA metrics — stretch |

**Research rec:** A. Dual Prometheus is a week-3 failure mode.

---

### T17 Registry

| Opt | Tool | Notes |
|---|---|---|
| A | OKD internal registry on PVC/S3 | Built-in; ImageStreams; part of the OKD eval |
| B | Harbor (CNCF graduated) | Scanning, replication, tenancy — extra cluster |
| C | Quay or Amazon ECR | Quay+Clair is the Red Hat enterprise registry; ECR is AWS-native |

**Research rec:** A for the POC. CI can also push GHCR/ECR and ImageStream import. B/C as a documented gap vs production.

---

### T18 Chaos

Both Litmus and Chaos Mesh are CNCF incubating. Pick **one**.

| Opt | Tool | Why pick | Why not |
|---|---|---|---|
| A | LitmusChaos | ChaosHub, workflows, ChaosCenter, AWS experiment catalog, GitOps/CI | More moving parts |
| B | Chaos Mesh | Cleaner CRDs (PodChaos, NetworkChaos, TimeChaos, JVMChaos); DaemonSet inject; lighter | Weaker experiment marketplace |
| C | AWS FIS | Native AZ/API/EC2 faults | AWS bill + IAM; not K8s-app faults |
| D | Chaos Toolkit | JSON experiments, multi-cloud | Not K8s-native CRDs |

**Research rec:** A if you want a portal + AWS faults. B if you want GitOps YAML and JVM/time faults on the Java services. Optional C later for AZ simulation. Not Gremlin (commercial).

---

### T19 AI-assisted RCA

No secrets, kubeadmin, or raw kubeconfig in prompts. Prefer in-cluster or anonymizing modes.

| Opt | Tool | Job | CNCF | Why pick | Why not |
|---|---|---|---|---|---|
| A | k8sgpt | Deterministic analyzers, LLM explains | Sandbox | Fast, low hallucination, `analyze --explain`, anonymize | Not multi-step incident hunting |
| B | HolmesGPT | ReAct agent over Prometheus/Loki/alerts | Sandbox | Real RCA across signals (CNCF blog pattern) | Cost/latency; more prompt risk |
| C | Robusta OSS | Alert enrichment → Slack | — | Pairs with B | Extra stack |

**Research rec:** A as the week-4 baseline. B if you want alert-driven RCA. Common pattern is A for posture, B for incidents.

---

### T20 Coverage

| Opt | Tool | Notes |
|---|---|---|
| A | Per-language runners (JaCoCo, pytest-cov, go cover, …) + GHA artifact | Honest for a polyglot demo |
| B | Codecov / Coveralls | Pretty diffs; extra SaaS |
| C | Sonar coverage | Only if T03=C |

**Research rec:** A. Do not force one coverage SaaS onto 12 languages in four weeks.

---

### T21 Autoscaling

| Opt | Tool | Notes |
|---|---|---|
| A | HPA + ClusterAutoscaler / MachineAutoscaler / MachineHealthCheck | This is the OKD production pattern on AWS |
| B | KEDA | Event-driven (Kafka in the demo) — nice stretch |
| C | Karpenter | EKS-centric; fights Machine API on OKD |

**Research rec:** A. B if Kafka lag scaling is a finding. Skip C.

---

### T22 Service mesh (stretch)

Demo already has **Envoy frontend-proxy**. Mesh is not required to complete weeks 1–3.

| Opt | Tool | Notes |
|---|---|---|
| A | None | Default |
| B | OpenShift Service Mesh (Istio) | mTLS between demo services; heavy |
| C | Linkerd | Lighter CNCF graduated mesh |

**Research rec:** A until week 3 is green.

---

## Week tracker

### Week 0 — Bootstrap

**Goal:** Repo, access, blockers, locked decisions. No cluster yet.

- [ ] GitHub collaborators added (`deepan011`, `umeshkumaarjj-dev`)
- [ ] Route 53 zone exists and NS is delegated (D012)
- [ ] AWS account, region (D013), and quotas confirmed
- [ ] Cost posture decided (D027)
- [ ] T01–T22 **Team pick** filled (or Skip)
- [ ] All **Proposed** infra decisions (D007–D015) moved to Locked or Superseded
- [ ] Confluence task list exported to `docs/`
- [ ] Repo layout created (`infra/`, `cluster/`, `gitops/`, `.github/workflows/`, `docs/`)
- [ ] `.gitignore` covers `cluster/*/auth/`, kubeconfigs, `*.tfstate`, pull secrets

### Week 1 — OKD exploration and infrastructure

**Goal:** Healthy HA cluster. Console + `oc` work. Operators understood.

- [ ] Architecture notes: CVO, MCO, CNO, Ingress, Auth, Monitoring, SCC vs RBAC (`docs/okd-architecture.md`)
- [ ] Terraform envelope applied: VPC (3 AZ), public/private subnets, NAT, IGW, Route 53, S3, installer IAM (D008)
- [ ] `install-config.yaml` committed as a **template** (no pull secret / ssh key)
- [ ] `openshift-install create cluster` succeeded (D007 D010 D011)
- [ ] `oc get clusteroperators` all `Available=True`
- [ ] `api.<cluster>.<base>` and `*.apps.<cluster>.<base>` resolve
- [ ] kubeadmin password in AWS SM; GitHub (or HTPasswd) IdP working; second admin can log in
- [ ] Default StorageClass = EBS gp3; registry not on EmptyDir
- [ ] MachineSets, IngressController, Cluster Monitoring (user-workload flag) documented
- [ ] Week 1 findings in `docs/week-1.md`

### Week 2 — Enterprise workload and GitOps

**Goal:** Shop UI live via Route; Git is desired state.

- [ ] OpenShift GitOps or chosen T01 controller installed (D016)
- [ ] GitOps UI/SSO (if T01=A/B); AppProject limited to intended namespaces
- [ ] App-of-apps in `gitops/root/`
- [ ] OTel Demo rendered to Kustomize (D017); Helm not the live controller
- [ ] Demo Route: `https://shop.apps.<cluster>.<base>`
- [ ] Load generator producing traffic
- [ ] SCC exceptions documented (what needed `anyuid` / privileged and why)
- [ ] PVCs bound on gp3 (Kafka / Postgres / Valkey)
- [ ] Demo bundled Prometheus/Grafana/OpenSearch disabled or isolated unless T14/T16 picked them
- [ ] Runtime secrets from chosen T11 backend
- [ ] NetworkPolicy default-deny + allowlist on `otel-demo`
- [ ] HPA + PDBs on selected services
- [ ] Dev overlay auto-sync; staging overlay manual
- [ ] Week 2 findings in `docs/week-2.md`

### Week 3 — Security and observability

**Goal:** Gates block bad PRs; one incident is visible in metrics, logs, and traces.

- [ ] Project RBAC least-privilege; SCC audit table in `docs/scc-audit.md`
- [ ] T12 policies: no `:latest`, require resources, require signed images, deny hostPath
- [ ] T13 runtime alerting
- [ ] User-workload ServiceMonitors; Alertmanager → Slack/email
- [ ] Grafana dashboards for RED + key services
- [ ] T14 logging stack
- [ ] T15 traces via OTel Collector; one checkout failure correlated
- [ ] GHA: T02 + T03 + T05 + T07 + T08 + T09 + T10
- [ ] T04 against shop Route
- [ ] Coverage artifacts retained
- [ ] Week 3 findings in `docs/week-3.md`

### Week 4 — Resilience and AI-assisted operations

**Goal:** Measured MTTD/MTTR; written production recommendation; cluster teardown runbook.

- [ ] Baseline SLOs from loadgen (p95, error rate) captured
- [ ] T18 app experiments + OTel feature-flag failures
- [ ] Infra experiments: pod/node kill, MachineHealthCheck replace, autoscaler
- [ ] T19 RCA vs human RCA notes
- [ ] Scorecard 1–5: install, day-2, security, o11y, GitOps friction, cost, skills
- [ ] Production recommendation in `docs/assessment.md`
- [ ] Teardown: `openshift-install destroy cluster` then `terraform destroy`
- [ ] This README **Where we are** set to complete

---

## Risks (active)

| ID | Risk | Status | Mitigation |
|---|---|---|---|
| R001 | No Route 53 zone / NS not delegated | Open | Block install until `dig` works for `api` and `*.apps` |
| R002 | OTel Helm vs SCC | Open | Budget two days; record every SCC exception as a finding |
| R003 | Worker RAM (Kafka + Loki + demo) | Open | Start m6i.2xlarge × 3 (D011); add MachineSet replica if needed |
| R004 | AWS bill left running | Open | Destroy script + budget alarm; D027 |
| R005 | kubeadmin used forever | Open | IdP on week 1 day 4 |
| R006 | Too many CNCF tools | Open | T01–T22 is the allow-list; one primary per layer |
| R007 | Confluence tasks not in Git | Open | Export before week 1 starts |

---

## Target repo layout (not created yet)

```
infra/aws/                 Terraform VPC / DNS / IAM
cluster/poc/               install-config template; gitignore auth/
gitops/root/               Argo CD app-of-apps
gitops/platform/           GitOps, Kyverno, Falco, ESO, Loki, Collector
gitops/apps/otel-demo/     Kustomize overlays
.github/workflows/         SAST, image scan, DAST, SBOM
security/policies/         Kyverno ClusterPolicies
chaos/                     Litmus workflows
docs/                      Findings, confluence export, assessment
```

---

## References

- https://okd.io/
- https://docs.okd.io/4.21/welcome/index.html
- https://docs.okd.io/4.21/installing/installing_aws/ipi/installing-aws-customizations.html
- https://docs.okd.io/4.21/installing/installing_aws/ipi/installing-aws-vpc.html
- https://opentelemetry.io/docs/demo/
- https://opentelemetry.io/docs/demo/kubernetes-deployment/
- https://landscape.cncf.io/
- https://github.com/redhat-developer/gitops-operator
- Confluence: OKD - Openshift OSS (Srikanth K) — four-week scope
- Confluence tasks (login required): [Infrastructure and Deployment Tasks](https://codaglobal.atlassian.net/wiki/spaces/CTA/pages/8027373574/Infrastructure+and+Deployment+Tasks+for+OKD+and+CI+CD+Pipeline+Setup)
