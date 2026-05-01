# 🚀 Add Support for Running Splunk on Apple Silicon

## 📌 Motivation

Running Splunk Enterprise in Docker on Apple Silicon (e.g. Apple M1/M2) has been problematic starting from version **9.4+**.

The root cause is:

- Splunk’s KVStore depends on newer versions of MongoDB (7.x / 8.x)
- These binaries require modern CPU instruction sets (e.g. AVX, AUX)
- When running under emulation (`linux/amd64` via QEMU) on Apple Silicon, these instructions are **not supported**
- As a result:
  - `mongod` crashes with `Illegal instruction (SIGILL)`
  - KVStore fails to start
  - Splunk becomes partially unusable

👉 This repository provides a **workaround** by forcing Splunk to use an older MongoDB version (4.2), which is compatible with Apple Silicon emulation.

---

## 📖 Introduction

This project provides a **custom Docker image** for running Splunk on Apple Silicon by modifying its internal MongoDB (KVStore) behavior.

Special thanks to:
- [@outcoldman](https://github.com/outcoldman)
- [@cschmidt0121](https://github.com/cschmidt0121)

for their original research and workaround ideas.

---

## ⚙️ What This Image Changes

This image applies the following modifications:

### 1. Force MongoDB 4.2
- Overrides all `mongod` binaries to point to `mongod-4.2`
- Avoids unsupported CPU instructions in newer Mongo versions

---

### 2. Passthrough Wrapper Script

Replaces the default `mongod` entry with a custom wrapper:

- Filters out incompatible parameters:
  - `--setParameter=ocspEnabled=*`
  - `--setParameter=minSnapshotHistoryWindowInSeconds=5`
- Prevents runtime crashes due to unsupported features in Mongo 4.2

---

### 3. Compatibility Libraries

- Installs required legacy dependencies (e.g. `compat-openssl10`, `net-snmp`)
- Adds symlinks to match expected library versions:
  - Example:
    ```
    libnetsnmpmibs.so.31 → libnetsnmpmibs.so.35
    ```

---

### 4. SASL Plugin Disable

- Disables SASL plugin loading to avoid symbol mismatch errors:
```
SASL_PATH=/dev/null
```

---

## ⚠️ Disclaimer

> ⚠️ This solution is a **deep internal workaround** and not officially supported.

- It overrides Splunk’s expected KVStore version (Mongo >= 5.x → 4.2)
- It may break:
- Future Splunk upgrades
- Certain KVStore features
- Security-related functionality (SSL / OCSP)

👉 Use **only for development, testing, or local environments**

---

## 🛠️ Build Instructions

### Build (default version: 10.2.3)

```bash
docker buildx build --platform linux/amd64 -t splunk-universal .
```

---

### Build with custom Splunk version

```bash
docker buildx build \
  --platform linux/amd64 \
  --build-arg SPLUNK_VERSION=9.4.10 \
  -t splunk-universal .
```

---

## ▶️ Run Example

```bash
docker run \
  --platform=linux/amd64 \
  -d \
  -p 8000:8000 \
  -p 8089:8089 \
  -e "SPLUNK_GENERAL_TERMS=--accept-sgt-current-at-splunk-com" \
  -e "SPLUNK_START_ARGS=--accept-license" \
  -e "SPLUNK_PASSWORD=SplunkPassw0rd" \
  --name splunk \
  splunk-universal
```

---

## ✅ Expected Behavior

After startup:

* Splunk Web: [http://localhost:8000](http://localhost:8000)
* KVStore should:

  * Start successfully
  * Allow basic CRUD operations
* No more:

  * `Illegal instruction (SIGILL)`
  * `mongod exited abnormally`

---

## ❗ Limitations

* Not production-ready
* KVStore performance and feature set may differ
* Future Splunk versions may break this workaround
* Relies on internal implementation details of Splunk

---

## 💡 Final Notes

This approach prioritizes **practical usability on Apple Silicon** over strict compatibility with Splunk’s expected runtime.

If you need:

* Full compatibility → use x86 hardware
* Stability → use officially supported environments
