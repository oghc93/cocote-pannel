#!/usr/bin/env python3
"""Adapter Xray untuk MaxLogin: akun berlimit HANYA boleh ada di inbound "-ml".

Inbound -ml mendengar di 127.0.0.1 dan path internal (/vless-ml dst) yang hanya dicapai
lewat location Nginx bertoken. Akun berlimit dihapus dari inbound lama supaya UUID yang
sama tidak bisa dipakai lewat path polos (/vless-ws) tanpa melewati MaxLogin.
Memakai API Xray yang ada: `xray api adu` / `xray api rmu` (tanpa restart).
Config selalu di-backup dulu (config.json.ml-bak.<ts>), tulis atomik.
"""
import json, os, shutil, subprocess, tempfile, time

ML = {  # proto -> (tag, port, path)
    "vless": ("vless-ws-ml", 10102, "/vless-ml"),
    "vmess": ("vmess-ws-ml", 10101, "/vmess-ml"),
    "trojan": ("trojan-ws-ml", 10105, "/trojan-ml"),
}
ML_TAGS = {v[0] for v in ML.values()}


def _inbound(proto):
    tag, port, path = ML[proto]
    st = {"network": "ws", "wsSettings": {"path": path}}
    settings = {"clients": []}
    if proto == "vless":
        settings["decryption"] = "none"
    return {"tag": tag, "listen": "127.0.0.1", "port": port, "protocol": proto,
            "settings": settings, "streamSettings": st}


def _client(proto, user, secret):
    if proto == "trojan":
        return {"password": secret, "email": user}
    c = {"id": secret, "email": user}
    if proto == "vmess":
        c["alterId"] = 0
    return c


def _save(path, cfg):
    bak = "%s.ml-bak.%d" % (path, int(time.time()))
    shutil.copy2(path, bak)
    d = os.path.dirname(path) or "."
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".ml-")
    with os.fdopen(fd, "w") as f:
        json.dump(cfg, f, indent=2)
    os.chmod(tmp, os.stat(path).st_mode)
    os.replace(tmp, path)
    return bak


def sync_limited(config_path, limited, xray_bin="xray", server="127.0.0.1:10085", runtime=True):
    """limited: {user: {proto: secret}}. Pastikan user hanya ada di inbound -ml.
    Mengembalikan ringkasan perubahan. Tidak menyentuh akun tanpa limit."""
    cfg = json.load(open(config_path))
    ibs = cfg.setdefault("inbounds", [])
    by_tag = {i.get("tag"): i for i in ibs}
    changed = False
    for proto in ML:
        if ML[proto][0] not in by_tag and any(limited[u].get(proto) for u in limited):
            ib = _inbound(proto); ibs.append(ib); by_tag[ib["tag"]] = ib; changed = True
    moved = {"added": [], "removed": []}
    for ib in ibs:
        proto, tag = ib.get("protocol"), ib.get("tag", "")
        if proto not in ML or "clients" not in ib.get("settings", {}):
            continue
        if tag in ML_TAGS:
            have = {c.get("email") for c in ib["settings"]["clients"]}
            for u, creds in limited.items():
                if creds.get(proto) and u not in have:
                    ib["settings"]["clients"].append(_client(proto, u, creds[proto]))
                    moved["added"].append((tag, u)); changed = True
        else:
            keep = []
            for c in ib["settings"]["clients"]:
                u = c.get("email")
                if u in limited and limited[u].get(proto):
                    moved["removed"].append((tag, u)); changed = True
                else:
                    keep.append(c)
            ib["settings"]["clients"] = keep
    bak = _save(config_path, cfg) if changed else None
    runtime_errs = []
    if changed and runtime:
        for tag, u in moved["removed"]:
            r = subprocess.run([xray_bin, "api", "rmu", "--server=" + server, "-tag=" + tag, u], capture_output=True, text=True)
            if r.returncode: runtime_errs.append(("rmu", tag, u, (r.stderr or r.stdout)[:200]))
        for tag, u in moved["added"]:
            proto = [p for p, v in ML.items() if v[0] == tag][0]
            ib = {"inbounds": [{"tag": tag, "protocol": proto, "port": ML[proto][1], "listen": "127.0.0.1",
                                "settings": {"clients": [_client(proto, u, limited[u][proto])]}}]}
            if proto == "vless": ib["inbounds"][0]["settings"]["decryption"] = "none"
            with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
                json.dump(ib, f); fn = f.name
            r = subprocess.run([xray_bin, "api", "adu", "--server=" + server, fn], capture_output=True, text=True)
            os.unlink(fn)
            # `xray api adu` keluar dengan kode 0 walau gagal: baca keluarannya
            if r.returncode or "Added 1 user" not in (r.stdout + r.stderr):
                runtime_errs.append(("adu", tag, u, (r.stderr + r.stdout)[:200]))
    return {"changed": changed, "backup": bak, "moved": moved, "runtime_errors": runtime_errs}
