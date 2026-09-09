# OKDMania

Learning-first production-scale POC: evaluate [OKD](https://okd.io/) on AWS **UPI** (we provision every machine), GitOps-deploy the [OpenTelemetry Demo](https://opentelemetry.io/docs/demo/), then prove security, observability, and self-healing. Calendar is a guide; **learning is the constraint**, not four weeks.

This README is the **single tracker**. Every architecture, tool, and process call is logged here. Progress is ticked here. Do not keep a parallel spreadsheet or Slack-only decision.

| | |
|---|---|
| **Current week** | Week 0 — bootstrap (cluster not started) |
| **Current focus** | **UPI locked (D031).** Team still picks T01–T22. Infra D007, D009–D015 Proposed. |
| **Cluster** | Not installed · method = AWS UPI (Terraform machines + Ignition) |
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
| GitHub repo | Empty besides this README | Invite `deepan011`, `umeshkumaarjj-dev`, `srikanth-karthi`, `sibisaravanan` |
| AWS account / DNS | Unknown | Need Route 53 zone + quotas |
| OKD cluster | Not started · **UPI** | Terraform stacks + Ignition + CSR approve; then Operators |
| Argo CD | Not started | Depends on cluster |
| OTel Demo | Not started | Depends on GitOps |
| Security gates | Not started | Depends on repo + CI |
| Chaos | Not started | Depends on workload baseline |

**Next concrete actions**

- [ ] Confirm public Route 53 hosted zone (authoritative NS)
- [ ] Confirm AWS region, account, and instance quotas
- [ ] Invite GitHub users `deepan011`, `umeshkumaarjj-dev`, `srikanth-karthi`, `sibisaravanan`
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

## Team — who does what

These are proposed ownership lanes so five people are not all on the installer. Challenge a lane in the decision log; until then, this is how work is split.

| Person | GitHub | Owns | Backup |
|---|---|---|---|
| Srikanth K | [srikanth-karthi](https://github.com/srikanth-karthi) | Scope, OKD architecture, Operator catalog, final assessment | Balaji |
| Balaji BR | [balajirajmohan](https://github.com/balajirajmohan) | AWS **UPI** (Terraform every stack), DNS, IAM, Ignition, this README tracker | Srikanth |
| Sibi | [sibisaravanan](https://github.com/sibisaravanan) | Platform hardening: `gitops/platform/`, SCC, policy, runtime, o11y, SLOs, TLS, multi-tenancy, chaos, AI RCA | Vignesh (CI side), Umesh (app) |
| Vignesh | [deepan011](https://github.com/deepan011) | CI, SAST/DAST, image/SBOM/sign, git secrets, coverage | Sibi |
| Umesh | [umeshkumaarjj-dev](https://github.com/umeshkumaarjj-dev) | GitOps, OTel Demo, Routes, app HPA/PDB | Sibi (SCC), Balaji (DNS/LB) |

### Srikanth — what you can do

You wrote the four-week scope. Stay on **what good looks like**, not every YAML file.

- **Now:** Invite yourself to the repo. Walk T01–T22 with the team and lock picks. Lock or reject remaining infra rows (version, size, region, cost). Export the Confluence task page into `docs/`.
- **Week 1:** Own `docs/okd-architecture.md` — CVO, MCO, CNO, Ingress, Auth, SCC vs RBAC, Cluster Monitoring. Pair with Balaji on first `oc get clusteroperators` after install. You sign off “cluster is healthy.”
- **Week 2–3:** Review GitOps AppProject and SCC exceptions; decide what is an OKD finding vs an app bug.
- **Week 4:** Own `docs/assessment.md` — scorecard, production recommendation, limitations. Pair with Sibi on MTTD/MTTR from chaos.
- **Tool votes you should drive:** T01, T16, T17, T22, D007–D015, D027.

### Balaji — what you can do

You own **every AWS object** and the **tracker staying true**. UPI means the installer does not spawn EC2 for you.

- **Now:** Add the four collaborators. Create repo layout (`infra/aws/upi/` modules, `cluster/`, `gitops/`, `.github/`, `docs/`) and `.gitignore` for kubeconfigs/tfstate/pull-secret/ignition. Confirm Route 53 zone + AWS quotas/region. Read [OKD AWS UPI](https://docs.okd.io/4.21/installing/installing_aws/upi/installing-aws-user-infra.html); use official CloudFormation as the *spec*, implement in Terraform.
- **Bring-up (will take more than a calendar week — that is the learning):** Terraform: VPC, subnets, NAT, SGs, IAM instance profiles, S3 (Ignition), NLBs (6443 API, 22623 machine-config, 80/443 apps), Route 53 `api` / `api-int` / `*.apps`. `openshift-install create install-config` → manifests → **remove MachineSets from manifests** so the cluster does not try to create machines → ignition. Launch bootstrap + 3 masters + 3 workers with correct Ignition. Approve CSRs. Wait `bootstrap-complete`. Destroy bootstrap. Then IdP, gp3, registry.
- **Day-2 (do not skip):** After the cluster is up, **create MachineSets** so later nodes are cluster-managed. UPI install does *not* give you this for free — official docs: control plane and initial compute are not governed by MachineSets. Without this, chaos “replace a worker” is just Terraform apply, not OKD.
- **Teardown:** reverse-order Terraform destroy (workers → masters → bootstrap leftover → NLBs → VPC). There is no `openshift-install destroy cluster` that owns your UPI stacks.
- **Tool votes you should drive:** T17, T21, D012–D013, D027, D031.

### Sibi — what you can do

You are the **strongest IC on this POC**. You do not wait for week 3. You own the platform *around* the shop: everything that makes OKD look like a place a bank could land. Umesh ships the app; you make the cluster refuse to be unsafe and prove it can heal.

#### Core (non-negotiable)

- **Now:** Lock T11–T16, T18, T19, T22. Scaffold `gitops/platform/` (policy, logging, collector, chaos — empty CRs are fine). Draft Kyverno/Gatekeeper policies in `security/policies/` before AWS exists. Write `docs/scc-model.md` from OKD docs (restricted-v2, anyuid, nonroot, privileged) so week 2 is not guesswork.
- **Week 1 (start day the cluster is up, not week 3):** `oc` daily. Enable user-workload monitoring. Inventory SCCs and default NetworkPolicy behavior. Cluster Monitoring Grafana: what is native vs missing. ResourceQuotas + LimitRanges on a sandbox project. Pair Balaji on registry/storage so PVCs are real.
- **Week 2:** Pair Umesh on **every** demo pod SCC. You own the audit table (`docs/scc-audit.md`) — service, SCC, why, can we drop it. Default-deny + allowlist NetworkPolicies. ExternalSecrets (or chosen T11) *platform* side: ClusterSecretStore, IAM. TLS: cert-manager + re-encrypt Route on the shop (Umesh consumes it).
- **Week 3:** You install and GitOps: policy engine, Falco (custom rules for shell-in-container, unexpected K8s API from a demo pod), Loki/Vector, production-shaped OTel Collector (redact, tail sampling, spanmetrics — not the demo default). One checkout failure in **metrics + logs + trace**. Alertmanager routed. SLO recording rules (p95, error rate) against loadgen.
- **Week 4:** Chaos is yours end-to-end: experiment catalog, GameDay script, MTTD/MTTR spreadsheet. k8sgpt vs your RCA; HolmesGPT only if k8sgpt is too shallow. Hand Srikanth numbers, not vibes.

#### Extra load (expected of you — do not skip)

This is the work that uses the extra capacity. Each item is a real production question the assessment needs.

| Extra | Deliverable | Why it is hard |
|---|---|---|
| E1 Multi-tenancy | Two projects (`otel-demo`, `otel-demo-team-b` or `platform-sandbox`): quota, limit range, NetworkPolicy isolation, who can `oc new-project` | OKD Projects ≠ Namespaces; this is the enterprise story |
| E2 Admission vs CI | Kyverno `verifyImages` (Cosign) so an unsigned image **cannot schedule** even if Vignesh’s GHA is bypassed | Closes the “I docker pushed to the node” hole |
| E3 Collector as a product | OTel Collector config in Git: OTLP in, redaction, spanmetrics, exporters to CMO + T14 + T15. Document drop rates | Demo chart Collector is not production |
| E4 Falco rules for this app | Custom rules: write to `/etc`, k8s secret list from a workload SA, unexpected outbound | Default rules are generic; you can do better |
| E5 SLOs + error budget | Grafana dashboard + Alertmanager: shop availability, checkout latency, burn rate. Used as chaos steady-state | Week 4 is science only if you defined green first |
| E6 MachineHealthCheck + PDB reality | Kill a worker / NotReady; show Machine API replace vs app PDB. Write what MachineAutoscaler did | Balaji owns scaling objects; you own the **experiment and write-up** |
| E7 DR note | etcd backup / restore drill **or** documented why we skipped and what prod would use (OADP) | Assessment without DR is incomplete |
| E8 OKD vs EKS/vanilla | `docs/okd-delta.md`: SCC, Routes, CMO, MCO, what broke the Helm chart | Srikanth’s rec needs your evidence |
| E9 Platform GitOps | All of the above as Argo/Flux apps under `gitops/platform/` — no click-ops Operators | If it is not in Git, you did not finish |

#### Stretch (if the above is done and you are still bored)

- **S1** AWS STS + `ccoctl` with Balaji (least-privilege CCO) — production IAM finding
- **S2** Tetragon: one **detect** policy, then one carefully scoped **enforce** (SIGKILL on a lab namespace only)
- **S3** KEDA ScaledObject on Kafka lag (demo has Kafka) vs HPA
- **S4** OpenShift Service Mesh mTLS on 2–3 demo services (not the whole shop)
- **S5** ACS/StackRox **or** Compliance Operator gap analysis (install if light; else paper)
- **S6** Argo Rollouts canary on frontend — only if T01 is Argo
- **S7** AdminNetworkPolicy / baseline deny at cluster scope
- **S8** Load beyond Locust: k6 or kube-burner against the Route; report saturation vs worker RAM

#### Tool votes you should drive

T11, T12, T13, T14, T15, T16 (user-workload), T18, T19, T21 (MHC experiments), T22, A2–A5.

Do not take Umesh’s app-of-apps or Vignesh’s GHA. Take the hard platform layer those two will otherwise skate past.

### Vignesh — what you can do

You own **laptop → PR → merge** security. The cluster should refuse unsigned/unscanned work because of you, not because someone clicked in a console.

- **Now:** Add `pre-commit` (gitleaks, hadolint, kubeconform). Scaffold `.github/workflows/` even before AWS exists — Actions do not need the cluster. First history scan of the repo.
- **Week 1:** Keep CI green on the Terraform/`install-config` template PRs (Checkov on `infra/`).
- **Week 2:** No secret YAML in `gitops/`. Wire chosen T11 from the app side with Umesh (ExternalSecret refs, not values).
- **Week 3:** Turn on chosen T03–T10 and T20 as **merge blockers**. Cosign sign is yours; Sibi **enforces** unsigned images at admission (E2). Coverage artifacts for the languages we actually build.
- **Week 4:** Keep gates on during chaos so “emergency hotfix” does not skip scanning. Help Sibi if policy (T12) needs a CI `kyverno apply --policy-report` check.
- **Tool votes you should drive:** T02, T03, T04, T05, T06, T07, T08, T09, T10, T20.

### Umesh — what you can do

You own **the shop going live from Git**. If it is not in Argo (or Flux), it does not exist.

- **Now:** Pick T01 (GitOps flavor) with Srikanth. Create `gitops/root/` and `gitops/apps/otel-demo/` skeletons. On a laptop, `helm template` the [OTel Demo chart](https://opentelemetry.io/docs/demo/kubernetes-deployment/) so week 2 is not the first time you see the manifests.
- **Week 1:** Get `oc` access from Balaji. Create the `otel-demo` project. Confirm default StorageClass before you need PVCs.
- **Week 2:** Install GitOps operator. App-of-apps **for the shop** (`gitops/apps/`). Render demo to Kustomize. OpenShift **Route** (not LoadBalancer). Loadgen traffic. HPA + PDBs. Dev auto-sync / staging manual. Pair Sibi on SCC — he owns the audit; you own a running store. Sibi owns `gitops/platform/`.
- **Week 3:** Keep the app healthy while Sibi adds NetworkPolicy and collectors (your Services must still route).
- **Week 4:** Hold SLOs during chaos; feature-flag failures in the demo are yours to interpret with Sibi.
- **Tool votes you should drive:** T01, D017, T21 (app HPA), T22 if mesh stretch happens.

### Pairing (do not silo)

| When | Pair | Why |
|---|---|---|
| Week 1 install | Balaji + Srikanth | Infra + “is this OKD healthy?” |
| Week 1 platform | Sibi + Balaji | Monitoring, SCC inventory, storage — Sibi does not sit idle |
| Week 2 SCC/Routes/TLS | Umesh + Sibi | Helm vs OKD; Sibi owns audit + cert-manager |
| Week 3 gates | Vignesh + Sibi | CI signs; cluster refuses unsigned |
| Week 4 GameDay | Sibi leads; Umesh (SLOs), Srikanth (rec), Balaji (nodes) | Chaos is a team sport with one conductor |
| Tracker | Balaji + whoever merged | README **Where we are** in the same PR |

---


## Decision log

Scope from the 2026-09-09 working session and Confluence write-up **OKD - Openshift OSS** (Srikanth K / Balaji BR). Tool and install details proposed from OKD 4.21 docs, OpenTelemetry Demo docs, Argo CD docs, and CNCF landscape.

| ID | Date | Topic | Decision | Status | Owner | Why | Rejected / not now |
|---|---|---|---|---|---|---|---|
| D001 | 2026-09-09 | Platform | Evaluate **OKD** (OpenShift OSS), not vanilla K8s or EKS as the SUT | Locked | Srikanth | Written POC objective | Distro bake-off |
| D002 | 2026-09-09 | Cloud | Run the cluster on **AWS** | Locked | Srikanth | Scope: provision AWS then install OKD | GCP / Azure / bare metal for this POC |
| D003 | 2026-09-09 | Duration | **Four weeks**, then a written assessment | Superseded | Srikanth | Confluence first pass | Open-ended lab |
| D004 | 2026-09-09 | Workload | **OpenTelemetry Demo** as the multi-service app | Locked | Team | Polyglot, OTLP, loadgen, feature flags | Synthetic nginx; custom greenfield app |
| D005 | 2026-09-09 | GitOps family | Use an **Argo CD** family tool (flavor still open in T01) | Locked | Srikanth | Week 2 scope named Argo CD | Flux as *primary* unless team supersedes D005 |
| D006 | 2026-09-09 | Outcome | Technical assessment: what works, toil, production recommendation | Locked | Srikanth | POC is evaluation, not a forever prod cluster | Silent “it works on my cluster” |
| D007 | 2026-09-09 | OKD version | **4.21** (current release) | Proposed | Balaji | [okd.io](https://okd.io/) lists 4.21 current, 4.22 engineering candidate | 4.22 EC as the cluster of record |
| D008 | 2026-09-09 | Install method | **Terraform VPC/DNS/IAM** + **openshift-install IPI** into that VPC | Superseded | Balaji | Speed; installer owns machines | Full UPI; SNO; Assisted Installer |
| D009 | 2026-09-09 | IAM mode | **Mint** for week 1; document **STS + ccoctl** as stretch | Proposed | Balaji | STS is more production-like but can blow bring-up | STS as a bring-up gate |
| D010 | 2026-09-09 | Topology | HA: **3 control plane + 3 workers**, 3 AZs, public API + public `*.apps` | Proposed | Balaji | Production-scale POC, not single-node | SNO; private-only API (unless security requires it) |
| D011 | 2026-09-09 | Size | Masters **m6i.xlarge**; workers **m6i.2xlarge**; 120 GB gp3 | Proposed | Balaji | Demo + Kafka + Loki will thrash official worker minimum | Default `m6i.large` workers |
| D012 | 2026-09-09 | DNS | Authoritative **public Route 53** zone: `api.`, `api-int.`, `*.apps.` | Proposed | Balaji | UPI: you create the records; they still must resolve | DIY DNS / nip.io |
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
| D028 | 2026-09-09 | Ownership | Lanes: Srikanth scope/assessment; Balaji AWS/tracker; Sibi platform hardening (`gitops/platform/`, sec, o11y, SLOs, chaos) + extras E1–E9; Vignesh CI; Umesh GitOps+app | Proposed | Balaji | Sibi is the strongest IC — extra load is expected, not stretch-only | Everyone on the installer; Sibi idle until week 3 |
| D029 | 2026-09-09 | AI posture | Do **A1 + A2 + A3** only. A4 optional. A5–A8 overkill for this POC | Proposed | Srikanth | Week 4 already names AI RCA; more AI hides the OKD eval | AI on every layer |
| D030 | 2026-09-09 | Duration | **Learning-first**; four weeks is a guide, not a gate | Locked | Team | UPI + E2E is the curriculum; calendar slips | Artificial IPI rush |
| D031 | 2026-09-09 | Install method | **AWS UPI**: Terraform (modeled on official CloudFormation) creates VPC, NLBs, IAM, bootstrap, 3 masters, 3 workers. `openshift-install` generates install-config, manifests, Ignition only. Then wait bootstrap, approve CSRs, delete bootstrap | Locked | Team | End-to-end learning: every AWS object, Ignition, ports 6443/22623, teardown | IPI (D008); SNO; Assisted |
| D032 | 2026-09-09 | UPI day-2 | After UPI cluster is healthy, **create MachineSets** so extra workers are cluster-managed | Proposed | Balaji | Official UPI: initial machines are *not* governed by MachineSets. Without this, MHC/autoscaler chaos is fake | Leave all nodes as snowflake EC2 forever |

---

## Tool options — team pick

Research rec is a starting point, not a lock. Fill **Team pick** with `A`, `B`, `C`, `Skip`, or a pair like `A+B` where marked. Then lock the matching D-row.

Native OKD layers (not a bake-off unless you supersede D014/D015/D025): OVN-Kubernetes, HAProxy Routes + AWS NLB, CoreDNS, OAuth, Cluster Monitoring, CRI-O/SCOS. Machine API for *new* workers after D032 — UPI initial nodes are snowflakes.

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
| A1–A8 | AI uses | See **AI utilization** | A1+A2+A3 | | D029 | 2 / 4 |

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

## AI utilization — do, optional, overkill

Srikanth’s scope already includes week 4 **AI-assisted incident analysis / RCA**. That is enough AI for a four-week OKD evaluation. More AI does not make the platform look better; it makes it harder to tell whether **OKD** worked.

Rule: AI may **explain** evidence. It must not **be** the control plane (no AI that applies GitOps, signs images, or changes SCC).

| ID | Where | Verdict | What to do | Why this is / isn’t overkill | Owner |
|---|---|---|---|---|---|
| A1 | Workload already in the demo | **Do** | Keep OTel Demo **Agent**, **Chatbot**, and **MCP** services. Treat them as “can OKD run an AI-shaped microservice?” — Routes, SCC, secrets for the model API, traces of LLM calls | Free. The demo ships this. You are not building an LLM platform | Umesh |
| A2 | Week 4 RCA (in scope) | **Do** | **k8sgpt** (`analyze --explain`, anonymize names). Side-by-side with Sibi’s human RCA after a chaos run. Score accuracy, time, hallucination | This *is* the week-4 deliverable. One binary, one afternoon. Overkill would be skipping the human comparison | Sibi |
| A3 | Drafting the assessment | **Do** | Use Cursor/ChatGPT on **sanitized** notes (operator status, MTTD/MTTR, SCC table) to draft `docs/assessment.md`. Srikanth edits and signs | Writing aid. Zero cluster risk. Overkill only if the draft ships without evidence | Srikanth |
| A4 | Alert / scan triage | **Optional** | If week 3 Trivy/Semgrep/Falco is a wall of noise: k8sgpt or a small LLM pass to **group and rank**, not to auto-close | Useful only after you have real alert volume. Installing it in week 1 is theater | Sibi + Vignesh |
| A5 | HolmesGPT / Robusta on every alert | **Overkill unless A2 is boring** | Multi-step agent over Prometheus+Loki. Do this only if k8sgpt is clearly too shallow *and* week 3 o11y is solid | Extra operator, extra prompt-injection surface, extra cost. Easy to fail the POC on the AI tool instead of OKD | Sibi |
| A6 | AI writes GitOps / Helm / Kyverno | **Overkill** | Humans review every manifest. Copilot in the IDE is fine; unreviewed AI apply is not | A bad SCC or Route takes the shop down. Git is the source of truth, not a chatbot | All |
| A7 | AI picks chaos experiments | **Overkill** | Use Litmus/Chaos Mesh catalogs + OTel **feature flags** (known failure modes). You need repeatable SLO math | Random AI faults are not science; you cannot report MTTD | Sibi |
| A8 | AI as merge gate (auto-approve, auto-fix CI) | **Overkill** | Semgrep/CodeQL/Trivy stay deterministic. An LLM may *comment* on a PR, never *pass* the check | Non-reproducible gates poison the supply-chain story | Vignesh |

**Team pick for D029:** `_unpicked_` → default rec is **A1 + A2 + A3 on, A4 if noisy, A5–A8 off**.

Hard constraints if any AI talks to the cluster:

- No `kubeadmin`, kubeconfig, pull secrets, or AWS keys in prompts
- Prefer k8sgpt anonymization / local or private model (Ollama) over dumping cluster objects to a public API
- Record in the assessment: what the tool got right, what it invented, time vs human

What AI will **not** fix: Route 53, SCC vs Helm, worker RAM, dual Prometheus. Those are the actual OKD findings.

---


## Week tracker

### Week 0 — Bootstrap

**Goal:** Repo, access, blockers, locked decisions. No cluster yet.

- [ ] GitHub collaborators added (`srikanth-karthi`, `sibisaravanan`, `deepan011`, `umeshkumaarjj-dev`)
- [ ] Route 53 zone exists and NS is delegated (D012)
- [ ] AWS account, region (D013), and quotas confirmed
- [ ] Cost posture decided (D027)
- [ ] T01–T22 **Team pick** filled (or Skip)
- [ ] All **Proposed** infra decisions (D007–D015) moved to Locked or Superseded
- [ ] Confluence task list exported to `docs/`
- [ ] Repo layout created (`infra/`, `cluster/`, `gitops/`, `.github/workflows/`, `docs/`)
- [ ] `.gitignore` covers `cluster/*/auth/`, kubeconfigs, `*.tfstate`, pull secrets

### Week 1 — OKD UPI infrastructure (expect this to spill)

**Goal:** You can draw every AWS object. Cluster Operators are Available. Console + `oc` work.

Official recipe: [Installing on AWS with user-provisioned infrastructure](https://docs.okd.io/4.21/installing/installing_aws/upi/installing-aws-user-infra.html). CloudFormation templates = spec. We implement **Terraform**.

- [ ] Architecture notes: CVO, MCO, CNO, Ingress, Auth, Monitoring, SCC vs RBAC (`docs/okd-architecture.md`)
- [ ] Terraform: VPC, 3 AZ public/private subnets, NAT, IGW, S3 (Ignition)
- [ ] Terraform: IAM instance profiles (bootstrap / master / worker)
- [ ] Terraform: SGs + **NLB 6443** (API) + **NLB 22623** (machine-config/Ignition, internal) + apps 80/443
- [ ] Route 53: `api.` `api-int.` `*.apps.` pointed at the right LBs (D012)
- [ ] `install-config.yaml` template committed (no pull secret / ssh key)
- [ ] Manifests generated; **MachineSets removed** so installer does not fight UPI machines
- [ ] Ignition configs: bootstrap, master, worker
- [ ] Bootstrap instance up; 3 control plane; 3 compute (FCOS/SCOS AMI, gp3, m6i as D011)
- [ ] CSRs approved; `openshift-install wait-for bootstrap-complete` then `wait-for install-complete`
- [ ] Bootstrap instance **destroyed**
- [ ] `oc get clusteroperators` all `Available=True`
- [ ] kubeadmin in AWS SM; GitHub/HTPasswd IdP; second admin can log in
- [ ] Default StorageClass = EBS gp3; registry not on EmptyDir
- [ ] **D032:** MachineSet created for additional workers (initial UPI nodes stay as-is)
- [ ] Week 1 findings in `docs/week-1.md` — include a resource map (Terraform name → OKD equivalent IPI would have created)

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
- [ ] Infra experiments: pod kill; worker terminate; **MachineSet-backed** node replace if D032 done (else Terraform recreate — document the delta)
- [ ] T19 RCA vs human RCA notes
- [ ] Scorecard 1–5: install, day-2, security, o11y, GitOps friction, cost, skills
- [ ] Production recommendation in `docs/assessment.md`
- [ ] Teardown: Terraform reverse-order destroy (no `openshift-install destroy` for UPI stacks)
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
| R008 | UPI bootstrap hang (DNS, 22623, tags, IAM, CSR) | Open | Checklist in week 1; pair debug; do not skip D032 |

---

## Target repo layout (not created yet)

```
infra/aws/upi/             Terraform: VPC, NLB, IAM, bootstrap, masters, workers
cluster/poc/               install-config, manifests, ignition (gitignore auth/)
gitops/root/               Argo CD app-of-apps
gitops/platform/           GitOps, Kyverno, Falco, ESO, Loki, Collector
gitops/apps/otel-demo/     Kustomize overlays
.github/workflows/         SAST, image scan, DAST, SBOM
security/policies/         Kyverno ClusterPolicies
chaos/                     Chaos experiments
docs/                      Findings, confluence export, resource map, assessment
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
