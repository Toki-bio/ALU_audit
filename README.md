# ALU_audit

**Goal: a tool-assisted, complete audit of Alu subfamilies and Alu copies in the human T2T assembly (T2T-CHM13).**

Status (2026-11-11): starting notes. Nothing in this repository has been run yet. This file collects what already exists
in other Toki-bio repositories, what the literature leaves open, and a proposed order of work. Statements are marked as
**measured** (a number from one of the repositories, with its path), **literature** (with a link) or **proposed** (a plan,
not a result).

## 1. What "audit" means here

Two things, kept separate:

1. **Subfamilies.** Which Alu subfamilies does the T2T-CHM13 copy set support when it is analyzed with one method and one
   nomenclature, and how does that compare with the Dfam families, the 213 Price et al. 2004 consensuses and COSEG output?
2. **Copies.** Every Alu copy in T2T-CHM13 assigned to a subfamily (firm, soft or unassigned, never silently dropped),
   compared per copy with RepeatMasker, with every disagreement explained or left visibly open.

## 2. Why an audit is needed (literature)

- Alu subfamily discovery is largely COSEG-driven and was done lineage by lineage. COSEG numbers its subfamilies
  arbitrarily (subfamily0 ... subfamilyN), without regard to the stepwise accumulation of diagnostic mutations, and each
  primate genome got its own list (Storer et al. 2023, Genes 14:249, <https://doi.org/10.3390/genes14020249>).
- When the same insertion exists as two copies (segmental-duplication pairs, human-chimpanzee homologs) and each copy
  is annotated separately, more than 10 % of such replicate pairs get different subfamilies; for Alu in
  segmental-duplication pairs 12.4 % (Carey, Patterson, Wheeler 2021, Mobile DNA 12:4; the 2020 item is its preprint).
  **Corrected 2026-11-11:** this is not run-to-run variation of RepeatMasker, as the earlier wording here and in
  SINEderella `docs/COSEG_COMPARISON_DESIGN.md` said.
- Many "subfamilies" contain several source elements, so consensus-based ages need reassessment
  (Wacholder et al. 2014, <https://doi.org/10.1371/journal.pgen.1004482>).
- Active human subfamilies keep being added from population data, e.g. AluYb7a3, AluYb8b1 and AluYa4a1
  (Konkel et al. 2015, GBE 7:2608, <https://academic.oup.com/gbe/article/7/9/2608/592318>).
- Alu is about 10.09 % of T2T-CHM13 (308 Mbp) by the table in
  <https://pmc.ncbi.nlm.nih.gov/articles/PMC13604091>.
- **Identified 2026-11-11:** the 118,489 full-length AluY analysis is Halabian, Storer, Hoyt, Hartley, Brosius, O'Neill,
  Makalowski, "Exploring Alu-driven DNA transductions in the primate genomes", bioRxiv 2024,
  <https://doi.org/10.1101/2024.04.29.591526>. RepeatMasker gave 166,483 AluY in CHM13v2.0; 128,695 were full-length;
  118,489 remained after removing copies in segmental duplications. It studies 3' transductions, not subfamily structure.
- The Alu share above (10.09 %, 308 Mbp) is from Hoyt et al. 2022 Table 2 and refers to CHM13 v1.1, not v2.0.

## 3. The CpG problem (the main scientific risk)

- Many Alu diagnostic positions are CpG sites. CpG sites mutate fast and recurrently, so a set of copies sharing a CpG
  change may be a real source-gene lineage, parallel CpG decay, or gene conversion between copies. Sequence similarity
  alone cannot tell these apart.
- **Measured** (SINE-discriminator `cpg_divergence_review/README.md`, section 6): on human top-100 plates the median
  CpG : non-CpG substitution density ratio is **5.8** for young plates (7 of 14 plates), with 84-91 % of CpG-site changes
  being transitions. This reproduces the published Alu value of about 6 (Xing et al. 2004,
  <https://doi.org/10.1016/j.jmb.2004.09.058>). The same review lists the limits: the plate consensus is taken as the
  ancestral state, and gene conversion and multiple hits are ignored, so it is a descriptive measure, not a rate.
- **Literature, direct observation:** pedigree and trio sequencing now gives de novo mutations inside repeats, called on
  T2T-CHM13v2.0, which is the same reference as this audit.
  - 73 children from 42 families, 6,030 validated de novo SNVs; germline SNV rate is enriched in Alu (reported
    p = 9.93e-6 in the preprint) and not in L1; about 91.7 % of the genome was callable. No per-subfamily or CpG-split
    analysis was found in the preprint text
    (<https://www.nature.com/articles/s41467-026-70342-1>, preprint <https://doi.org/10.1101/2025.07.18.665621>).
  - Four-generation CEPH 1463 pedigree; de novo calls in its Supplementary Table 10
    (<https://www.nature.com/articles/s41586-025-08922-2>); open-consent data under CC BY 4.0 at
    <https://registry.opendata.aws/platinum-pedigree/>.
- **Proposed use:** per-site de novo data as a null model for recurrent mutation at diagnostic positions. Expected Alu
  de novo SNVs in the 73-child set: roughly 600-800 (own estimate from 6,030 x about 10 % plus enrichment; not a published
  number). That supports J/S/Y by CpG/non-CpG, not per-position resolution. Not verified: whether the supplementary
  tables give per-site coordinates, and whether the callable mask is published.

## 4. What already exists (inventory of 2026-11-11)

Public Toki-bio repositories were searched for Alu content at the commits given. Four private repositories
(sineclose, MSA-viewer-archive, Tuatara-tRNA-containing-minisatellites, zany-system_restore) were not searched.
All runs below are on **hg38**, none on T2T-CHM13.

| repository (commit) | path | what it holds |
|---|---|---|
| SubFam (53a3a47) | `benchmark/alu_hg38/` | Run of 2026-10-11: 30,000 full-length Alu copies (250-330 bp) from chr1, one seed, SubFam 1.4.1 `-n 50`: 600 chunk consensuses. All 74 Price 2004 consensuses expected at >= 50 copies are contained at >= 0.95 identity (61 at >= 0.98); 25 of 26 such Dfam 4.0 families. **137 rows have no Dfam family within 0.95, 94 have no Price consensus within 0.95.** Chunk purity against RepeatMasker names 0.472. |
| SubFam (53a3a47) | `benchmark/alu_konkel/` | 295-316 Konkel 2015 Y-lineage loci, SubFam against COSEG, single runs. COSEG split off Yb8 but never separated Ya5 from AluY (also at `-m 5`). SubFam `-n 20`: 15 rows contain the AluY, Ya5 and Yb8 consensuses exactly, but one lineage fills several chunks (completeness 0.36). COSEG scores higher on partition agreement (V 0.678 against 0.515). Labels are similarity-derived. |
| SINEderella (7a3a794) | `docs/COSEG_COMPARISON_DESIGN.md` | Full SINEderella-against-COSEG test design of 2026-10-08: arms A-E, four data sets, metrics and decision rule fixed in advance. **Design only, nothing run.** |
| SINEderella (7a3a794) | `docs/FAMILY_SUBFAMILY_ASSIGNMENT.md` | hs21 set: 10,521 chr21 Alu copies; 354 copies stay split (AluSx against AluY 222, AluJb against AluSx 132). |
| Tal (9ab286e) | `hum/LOG.md`, `hum/alignments/` | Whole-hg38 SINEderella run with 65 Dfam SINE consensuses, about 354,000 assigned copies. Against the UCSC `rmsk` track: 92.9 % of assigned loci overlap a RepeatMasker SINE call; subfamily names agree at 82.8 % raw, 85.0 % after `_short_` normalization. Best: AluYa5 99.3 %, AluSc8 98.8 %. Disagreement concentrates at FLAM/FRAM against AluJo/Jr/Jb, AluJr4 (58 %) and BC200 (RepeatMasker files it under `scRNA`, not `SINE`). 168 per-subfamily alignments (top100, rand100, subfam). |
| SINE-discriminator (f0db37f) | `FINDINGS.md`, `cpg_divergence_review/` | 64 human Alu sets in the benchmark: 55 accepted, 9 not assessable, 0 rejected. CpG review and the 5.8 ratio (section 3). |
| MSA-viewer (eda0240) | `examples/demo/`, `tests/kmer/` | Alu demo alignments and a subfamily clustering test. |
| knowlege (c6fba96) | `projects/` | Alu anchor-graph, SV-profiling and ddPCR idea notes. Not subfamily work. |

Tools available for the audit: SINEderella (discovery, 10-cycle `ssearch36` voting assignment), SubFam (chunk
consensuses without a reference), the peel, sear2k (genome search), SINE_orth_loc (orthology by flanks), SINE-discriminator,
MSA-viewer (manual review).

## 5. Gaps

1. No run on T2T-CHM13. Everything so far is hg38.
2. No whole-genome SubFam run: chr1 only, one seed (seeds 2 and 3 are pending per the SubFam README).
3. The COSEG comparison is designed but not run. COSEG is not installed on KIT.
4. No independent truth. Every label so far is similarity-derived (RepeatMasker name or best Price consensus), which
   favours any method that also uses similarity to a consensus.
5. The 137 chunk consensuses with no Dfam match are unexamined: new subfamilies or noise.
6. The peel was calibrated on Timema; Alu is out-of-sample for it.
7. Old-Alu boundaries (FLAM/FRAM against AluJ, BC200) have no agreed definition on either side.
8. No mutation data used yet (section 3).

## 6. Proposed order of work

1. **Copy set.** Extract all Alu copies from T2T-CHM13v2.0 with coordinates and RepeatMasker calls; record the
   RepeatMasker and Dfam versions. Keep truncated copies, flag them.
2. **Reference sets.** Dfam human Alu families, Price 2004 (213), Konkel 2015 additions, COSEG output on the same copies.
3. **Subfamily discovery.** SubFam on the whole genome with three seeds, then the peel, with no parameter changes after
   seeing Alu results. Run the pre-registered COSEG comparison (`COSEG_COMPARISON_DESIGN.md`) on the same copies.
4. **Copy assignment.** SINEderella assignment of every copy; firm, soft and unassigned all counted.
5. **Adjudication of disagreements,** in the fixed order already written in SubFam `benchmark/alu_hg38/README.md`:
   diagnostic positions read from the alignment; presence/absence polymorphism; chimpanzee orthology; divergence and CpG
   consistency; blind manual review in MSA-viewer with method labels hidden.
6. **CpG and recurrence.** For every candidate subfamily, the number of diagnostic positions that are CpG sites, the
   CpG : non-CpG ratio of the plate, and, where de novo data allow, the observed per-site mutation rate (section 3).
   A subfamily resting only on CpG transitions is reported as such.
7. **Novel candidates.** The chunk consensuses with no Dfam or Price match (137 and 94 on chr1) go through steps 5 and 6
   before any is named.
8. **Output.** One table per subfamily (consensus, copy count, diagnostic positions, CpG share, evidence class) and one
   row per copy (coordinates, call, confidence, RepeatMasker call, reason for any disagreement).

### Owner's decisions, 2026-11-11

- Reference call set: the RepeatMasker 4.2.2 / Dfam 3.9 run of hs1 dated 2025-10-31
  (<https://www.repeatmasker.org/genomes/hs1/rmsk4.2.2_dfam3.9_rb20181026_rmb/>).
- On step 3, in his words: "subfam on all alu is impratcical, sequential peeling is the key". So SubFam is not run on
  the whole copy set. Reading of this by Claude, to be confirmed by the owner: SubFam on a sample, peel the clearly
  isolated groups, build each group's consensus from its member copies, assign and remove those copies from the whole
  set, then sample again from what remains, and repeat until only ungroupable copies are left.
- Compute server: Monsoon, `/scratch/sk4386/alu_audit/`.

## 7. Open decisions

- Ground truth: RepeatMasker calls only, or a hand-called sample as well, and which sample.
- Whether to build the simulation with a known subfamily tree before the real-data runs (the only data with true labels).
- Nomenclature for anything new: the standard of lower-case letter plus number of diagnostic changes from the parent
  (Storer et al. 2023), or another scheme.
- How to state, in one paragraph, what the SINEderella route does that COSEG does not. The one small comparison so far is
  mixed: COSEG better on partition agreement, SubFam better on consensus containment.
- Scope of "Alu": include FLAM, FRAM, FAM and BC200, or treat them as a boundary set.

## 8. Not verified

- The 118,489 AluY T2T-CHM13 analysis (section 2) is unidentified.
- Contents of the supplementary tables of the two de novo mutation papers were not opened.
- Carey 2020 and Wacholder 2014 are cited here from notes in the other repositories, not from a fresh reading.
- Numbers in section 4 are copied from the READMEs and logs at the stated commits; they were not recomputed.

## 9. Background phase, 2026-11-11 (no analysis run)

**Literature.** `literature/SOURCES.md` lists every source with its access status and the check of each literature
statement in sections 2 and 3 against the opened text (verbatim quotes, section F). Full texts are kept locally and are
not in the repository. All paywalled and bot-blocked items were fetched by hand on 2026-11-11 (sections G and H of
`literature/SOURCES.md`); Xing et al. 2004 is now confirmed from the full text: R averages 6.72 for AluY, 6.18 for AluS
and 3.67 for AluJ, on 5296 elements in 20 subfamilies. Still missing: the online supplement of Price et al. 2004 (the
213 consensuses are available locally from another copy, see below).

- Price et al. 2004 exclude frequent CpG mutations when defining subfamilies. This matters for section 3.
- Doronina et al. 2021 (Genes): 98 clear Alu-to-Alu gene conversion cases among 68,097 Alu insertions.
- De novo data: Noyes et al. 2026 Supplementary Data 1 gives per-site de novo SNVs on T2T-CHM13v2.0, and Data 2 a
  RepeatMasker column per site; the Source Data sum to 704 germline SNVs in Alu across 73 children. Porubsky et al. 2025
  Supplementary Table 10 gives 652 germline and 120 postzygotic per-site SNVs. A per-site callable mask was not found in
  either paper; Noyes publish only the Snakefile that builds it.
- Not found in a PubMed and web search (not exhaustive): a 2020-2026 paper that analyses Alu subfamily structure or CpG
  decay genome-wide in T2T-CHM13. Nikitin 2026 (R Soc Open Sci, <https://doi.org/10.1098/rsos.260639>) was read on
  2026-11-11: it is an epigenomic study that takes the RepeatMasker subfamilies as given, so it does not overlap with this
  audit. Tang & Liang 2020 (<https://doi.org/10.1016/j.ab.2020.113825>) was read the same day: six primate
  genomes on hg38 with RepeatMasker names as given, master copies by best match; no overlap either.
- A third RepeatMasker call set for hs1 exists: RepeatMasker 4.2.2 with Dfam 3.9 (2025-10-31), with per-copy alignments,
  at <https://www.repeatmasker.org/genomes/hs1/rmsk4.2.2_dfam3.9_rb20181026_rmb/>.

**Compute server: Monsoon** (`sk4386@monsoon.hpc.nau.edu`, OpenSSH with `id_ed25519`; work under `/scratch/sk4386/`).
Read-only look on 2026-11-11:

- Quota: `/scratch` 7.6 of 13.7 TB and 903k of 2.0 M files.
- Present: `ssearch36`, `mafft`, `bedtools`, `samtools`, `seqkit`, `minimap2`, `blastn`, `bwa` (conda env `bioinfo`);
  modules `repeatmasker/4.2.4`, `rmblast/2.17.0`, `mafft/7.526`; `/projects/tollis_lab/databases/Dfam.h5`.
- Outdated: `/home/sk4386/bin/SINEderella-dev` (commit 9624a0e, 2026-02-15) and `/home/sk4386/bin/SubFam` (2025-10-16).
  Current sources are SINEderella 7a3a794 and SubFam 1.5.1 (53a3a47) on GitHub.
- Not found on Monsoon: a human genome (hg38 or T2T-CHM13), COSEG, EMBOSS `cons` on PATH.
- Public inputs, reachable, not downloaded: UCSC `hs1.fa.gz` and `hs1.repeatMasker.out.gz`
  (<https://hgdownload.soe.ucsc.edu/goldenPath/hs1/bigZips/>), and the T2T consortium
  `chm13v2.0_RepeatMasker_4.1.2p1.2022Apr14.out`.

**Tools, as read from source on 2026-11-11.**

- SubFam 1.5.1 needs only bash, awk, MAFFT and a C compiler. Its k-mer ordering holds an n x n matrix (30,000 copies:
  3.6 GB), so the whole Alu set cannot be ordered in one run; `-P` (PartTree) uses far less memory with less pure chunks.
- The peel is `peel_features.py` in SINE-discriminator, calibrated on Timema, run on Alu only for the 295 Konkel loci.
- The Price 2004 supplement with the 213 consensuses is at `C:\work\SubFam\SUBFAMILIES.FINAL.txt` (local, 213 records);
  the 42 Dfam 4.0 human Alu families are in SubFam `benchmark/alu_hg38/results/dfam_alu.fa`.
- COSEG 0.2.4 was built only in a cloud container for `benchmark/alu_konkel`; there is no server install.
- Not recorded anywhere found: the SINEderella command line of the Tal hg38 run, and the script behind its
  RepeatMasker concordance numbers.

## 10. Step 1: the Alu copy set (2026-11-11, measured)

Work directory `monsoon:/scratch/sk4386/alu_audit/`. Scripts in `scripts/`, summary tables in `results/01_copyset/`.

**Inputs** (`data/`, job 34188685): `hs1.fa.gz` from UCSC (md5 a493d540..., matches UCSC `md5sum.txt`); `hs1.fa.out.gz`
(md5 d797affd...) and `hs1.fa.align.gz` (md5 f22c100b...) from the RepeatMasker 4.2.2 / Dfam 3.9 run. No md5 is published
for the last two; they have the exact byte size the server reports and pass `gzip -t`.

**Table** (`scripts/02_alu_table.sh` -> `copyset/alu_rows.tsv`, one line per RepeatMasker row):
chr, start (0-based), end, name, RepeatMasker ID, strand, SW score, % divergence, % deletion, % insertion, consensus
start, consensus end, consensus bases left, class, overlap star.

- 1,204,897 `SINE/Alu` rows, 312,531,330 bp, 49 names; 1,163,404 elements by RepeatMasker ID (1,123,252 in one row,
  38,876 in two, 1,276 in three or more); 497 elements carry more than one name across their rows; 1,991 rows are
  starred (overlapped by a better match). The ID is unique genome-wide.
- Boundary set, kept apart in `copyset/boundary_rows.tsv` and not decided on: 7SLRNA 2,017 rows (`srpRNA`), BC200 690
  (`scRNA`); the monomers FLAM_C 33,685, FRAM 14,926, FLAM_A 7,462 and FAM 1,908 are inside `SINE/Alu`, as are a
  generic `Alu` (7,113 rows, mean 56 bp), `CAS` (115) and `ASR` (80). What `CAS` and `ASR` are has not been looked up.

**Controls with a known answer (both pass).**

- Alu bp without chrY: 312,531,330 - 4,246,017 = 308,285,313. Hoyt et al. 2022 Table 2 (CHM13 v1.1, no chrY):
  308,309.7 kbp. Difference 0.008 %, with a different RepeatMasker and Dfam version.
- All AluY-named rows: 166,151. Halabian et al. 2024 on the 2022 annotation: 166,483. Difference 0.2 %.

**Full-length rows** (at least 0.9 of the consensus covered; `summary_fulllength_by_name.tsv`): AluSx 253,607 of
315,295; AluJb 157,619 of 271,945; AluY 101,092 of 122,722; AluJo 4,586 of 15,736 (0.29) and AluJr 5,091 of 14,685 (0.35)
are mostly partial.

**Observation to explain (not a conclusion).** In full-length rows, several young-named subfamilies have two
divergence modes (`summary_div_hist_cov90.tsv`, RepeatMasker % divergence, 1 % bins):

| name | full-length rows | at 0-2 % | at 10 % or more |
|---|---|---|---|
| AluYa5 | 3,525 | 3,018 | 309 (9 %) |
| AluYb8 | 3,013 | 2,027 | 787 (26 %) |
| AluYg6 | 1,136 | 356 | 653 (57 %) |
| AluYa8 | 1,134 | 43 | 782 (69 %) |
| AluYk12 | 519 | 62 | 423 (82 %) |
| AluYh9 | 356 | 0 | 328 (92 %) |
| AluY | 101,092 | 1,922 | 11,031 (11 %) |

Counts are computed from `summary_div_hist_cov90.tsv`. AluYa5 has a second mode at 13-16 %, AluYg6 at 12-15 %,
AluYa8 modes at 8-10 % and 14-16 %, AluYk12 at 13-16 %; AluYh9 has a single mode at 13-16 % and no row under 6 %.
For comparison AluY has one mode at 6-7 %. A copy at 13-16 % from the consensus of a subfamily that expanded in the
human lineage is older than the subfamily can be, so these rows are candidates for a wrong name. Possible causes to
separate: an old AluS or AluJ copy that matches the young consensus best by chance or by parallel CpG changes; gene
conversion; a subfamily that is in fact old (AluYh9). Nothing here has been tested yet.

## 11. Round 1 of the sequential peeling (2026-11-11, measured)

Scripts `scripts/03_seqs_round1.sbatch`, `scripts/04_peel_round1.sbatch`, `scripts/05_peel_groups_vs_rm.py`; results in
`results/02_round1/`; full outputs in `monsoon:/scratch/sk4386/alu_audit/round1/`.

**Copies.** 824,790 full-length dimeric Alu (one RepeatMasker row for its ID, at least 0.9 of the consensus covered,
250-350 bp, monomers excluded; 247.7 Mbp, no N): `monsoon:/scratch/sk4386/alu_audit/copyset/alu_full.fa`.
Sample: 30,000 copies, seed 1 (awk `srand(1)`, sorted). The sample follows the genome's mix: 9,096 AluSx, 5,706 AluJb,
3,632 AluY, 2 AluYd8 (`s1.label_counts.txt`).

**SubFam 1.5.1 `-n 50`:** 600 chunk consensuses, 5 min 7 s, 3.6 GB peak, toy test (1,000 copies) passed first.
Chunk purity against the RepeatMasker names: mean 0.613; 64 chunks at 0.9 or more, 143 at 0.7-0.9, 393 below 0.7.
(RepeatMasker names are themselves similarity calls, so low purity is not proof of poor chunks.)

**Peel (`peel_features.py`, default parameters, none changed after seeing Alu data):** 2 groups, then "nothing separable".

| group | chunks | copies | by RepeatMasker name |
|---|---|---|---|
| G1 (round 1) | 123 | 6,150 | AluJb 86 %; family: AluJ 93 %, AluS 6 %, AluY 0 % |
| G2 (round 2) | 117 | 5,850 | AluY 60 %, AluSc 9 %, AluSx 6 %, AluSc8 6 %, AluYk3 4 %; family: AluY 74 %, AluS 26 % |
| residue | 360 | 18,000 | AluSx 47 %, AluSx1 10 %, AluSz 8 %, AluSp 7 %; family: AluS 95 % |

At defaults the peel recovers the three old/intermediate/young families (J, Y, S) and nothing inside S. Round 3 found
22 features and 0 blocks in the 360 residue chunks. G1 chunk ids are at both ends of the guide-tree order (1-99 and
574-600), so AluJ copies sit at both ends of SubFam's ordering.

**Not yet known.** Whether S-internal structure exists in the 18,000 residue copies but is hidden by sampling 50-copy
chunks across a mixed pool, or whether the peel's thresholds are too strict for a continuum. The planned test is the
sequential step the owner described: take the S copies out of the whole set and sample again from that remainder, so the
chunks and the alignment are built from S alone.

**Process note.** The first two jobs of step 3 failed on `sort | head` under `pipefail` (broken pipe); the second
resubmission still contained the bug because my patch did not apply and I did not check. Fixed in the script and
verified on Monsoon before the third job.

## 12. Round 2 of the sequential peeling (2026-11-11, measured)

Scripts `scripts/06_consensus.py`, `scripts/06_cons_from_aln.py`, `scripts/08_round2_asSINEment.sbatch`
(`07_round2.sbatch` is the failed version, kept as a record); results in `results/03_round2/`; full outputs in
`monsoon:/scratch/sk4386/alu_audit/round2/`.

**Consensuses from member copies** (500 random member copies per round-1 group, MAFFT, plurality, column dropped if more
than half gaps): `cons_G1` 297 bp, closest Dfam family AluJo (97.0 %); `cons_G2` 301 bp, AluY (100 %); `cons_S` (from the
residue) 302 bp, AluSx (99.7 %).

**Assignment with SINEderella step 2, unchanged** (`step2_asSINEment.sh`: 10 ssearch36 cycles, `-z 11`, 10/10
unanimity, 0.45 x TopN), all 824,790 full-length copies, 36 min on 32 cores:

| consensus | firm | not unanimous | low score |
|---|---|---|---|
| cons_S | 527,234 | 13,711 | 74 |
| cons_G1 (AluJ) | 145,702 | 5,728 | 150 |
| cons_G2 (AluY) | 124,824 | 7,366 | 1 |

Firm in total 797,760 (96.7 %).

**Control (passed).** The 30,000 round-1 sample copies have a group through their chunk: 29,019 firm, of which 27,123
agree (0.935). The main disagreement: 1,040 copies of round-1 G2 chunks go to `cons_S` (G2 was 26 % AluS by
RepeatMasker name), 577 of G1 go to `cons_S`.

**Failed attempts before this, both mine.** (1) One ssearch36 run on the whole library reported hits for only 62,957
copies. (2) With the library in blocks, `-z 1` estimated statistics from the library itself, which is all Alu: every
copy scored 15-19 bits and best and runner-up differed by less than 5 bits for 824,787 of 824,790 copies. The control
(0.669) stopped the job. I should have used step 2 from the start instead of writing an assignment of my own.

**Round 2 on AluS only.** 30,000 firm `cons_S` copies (seed 2): AluSx 14,144, AluSx1 2,789, AluSz 2,304, AluSp 1,827,
AluSg 1,466, AluSq2 1,432, AluSz6 1,205, AluSc 877, ... (`S/s2.label_counts.txt`). SubFam `-n 50`: 600 chunk consensuses;
chunk purity against RepeatMasker names mean 0.509 (1 chunk at 0.9 or more). Peel, defaults: 21 features, 0 blocks,
**0 groups**.

**Reading (not tested).** With AluJ and AluY removed, the peel still finds no structure inside AluS at default
parameters. A likely reason, to be tested rather than assumed: each chunk consensus is a plurality vote over 50 copies
that are mostly AluSx, so the diagnostic bases of the smaller S subfamilies (AluSp, AluSc, AluSq, AluSg) are outvoted
inside the chunks and never reach the peel. That is a property of chunk size against subfamily share, not evidence
that AluS has no subfamilies.

## 13. Round 2 with 10-copy chunks (owner's option 1, 2026-11-11, measured)

Same AluS sample of 30,000 as section 12; only the chunk size changes: SubFam `-n 10 -p 0.6` (the SubFam10 pairing),
3,000 chunk consensuses, 2 min 31 s. Script `scripts/09_round2_n10.sbatch`; random baseline
`scripts/10_random_chunk_purity.py` (same labels shuffled with seed 1, cut into chunks of the same size).

| chunks | mean purity | chunks at 0.7 or more | chunks at 0.9 or more |
|---|---|---|---|
| SubFam `-n 50` | 0.509 | 36 of 600 | 1 |
| random, 50 | 0.471 | 0 | 0 |
| SubFam `-n 10` | 0.543 | 753 of 3,000 | 119 |
| random, 10 | 0.479 | 396 of 3,000 | 20 |

Majority name of the `-n 10` chunks at purity 0.7 or more (sample size of that name in brackets): AluSx 578 (14,144),
**AluSp 103 (1,827), AluSc 26 (877)**, AluJb 24 (730), AluSq2 7 (1,432), AluSg 6 (1,466), AluSx1 2 (2,789), AluSz 1
(2,304), AluSz6 1 (1,205). At `-n 50` AluSp held 12 such chunks and AluSc 1.

Peel, defaults, on the 3,000 consensuses: 493 alignment columns, 258 features, 0 blocks, **0 groups**.

**What the test says (the prediction was written down before the run).** The outvoting explanation holds only in part.
AluSp and AluSc gain chunks of their own once chunks are small: they are separated by SubFam's ordering and were being
diluted at 50. AluSx1, AluSz, AluSz6, AluSq2 and AluSg do not: even at 10 copies per chunk the ordering does not bring
their copies together, so chunk size is not what hides them. Their copies are not neighbours in the k-mer guide tree,
which is built on whole-copy similarity and therefore dominated by each copy's private decay (about 12 % divergence),
while these subfamilies differ from AluSx by a few diagnostic positions. Whether those positions are real
synapomorphies or CpG changes is the question of section 3, still open. The peel found nothing at either chunk size.

## 14. COSEG on the same AluS sample, against RepeatMasker (2026-11-11, measured)

COSEG built from <https://github.com/rmhubley/coseg> commit cea334a on Monsoon (`tools/coseg/`). Script
`scripts/11_coseg_S.sbatch`, comparison `scripts/12_coseg_vs_rm.py`; results `results/03_round2/S/coseg/`.

- **Control:** COSEG's bundled Price example (4,000 copies, `-k -d -m 50`) runs in 1 s and gives 4 subfamilies.
- **Input:** the same 30,000 AluS copies as sections 12-13, aligned globally to COSEG's AluSx consensus
  (`to_coseg.py` from SubFam `benchmark/alu_konkel`); 1,285 copies dropped for missing more than 5 bases at an end
  (Price's rule), 28,715 kept. Settings `-k -d -m 50`, nothing tuned. Run time 56 s.
- **Result: 26 subfamilies** (14 leaves in COSEG's tree), each defined by named diagnostic positions
  (`s2.seqs.subfamilies`).

Where RepeatMasker names go (share of that name's copies in its main COSEG subfamily):

| RepeatMasker name | copies | main COSEG subfamily |
|---|---|---|
| AluSp | 1,770 | sf2, 82 % |
| AluSz6 | 1,149 | sf4, 74 % |
| AluSx4 | 322 | sf8, 74 % |
| AluSg4 | 222 | sf10, 70 % |
| AluSq2 | 1,392 | sf3, 65 % |
| AluSz | 2,209 | sf9, 63 % |
| AluSc | 846 | sf1, 56 % |
| AluSg | 1,431 | sf0, 52 % |
| AluSx1 | 2,663 | sf10, 47 % |
| AluSx3 | 829 | sf0, 30 % |
| AluSx | 13,475 | sf0, 30 %; spread over sf8, sf9, sf10 |

Agreement over all copies (RepeatMasker names as reference): homogeneity 0.304, completeness 0.264, V-measure 0.283.
Four small COSEG subfamilies (sf5, sf12, sf14, sf19; 383 copies) are 81-94 % AluJb: AluJb copies that the round-2
assignment had placed with the AluS consensus.

**What this shows.** COSEG separates AluSz, AluSz6 and AluSq2, which SubFam's ordering did not bring together at
either chunk size and the peel never found. The difference is the axis: COSEG tests co-occurring changes at single
positions against one reference alignment, SubFam orders copies by whole-copy k-mer similarity. AluSx, the largest
name, has no COSEG subfamily of its own; its copies sit in the four large COSEG subfamilies alongside the other names.

**What it does not show.** COSEG and RepeatMasker both work from consensus and diagnostic positions, so their partial
agreement is not independent evidence that these subfamilies are real lineages. Whether the diagnostic positions are
shared lineage markers or recurrent CpG changes (section 3) is still untested: COSEG run with `-k` uses Price's
original p-value, and Price excluded frequent CpG mutations; that exclusion has not been checked in COSEG's code.
