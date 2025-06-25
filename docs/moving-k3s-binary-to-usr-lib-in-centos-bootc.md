# Moving k3s binary to /usr/lib in CentOS bootc

**SylChamber**: this script installs k3s on a linux system. it downloads the binary, installs it, sets up systemd services. The installation directory is under /var/lib/rancher.

I want to move the binary under /usr/lib because I want to install k3s in a CentOS bootc derived OS, where /var is editable to the user and should not host binaries.

Make recommendations for this task.

**GitHub Copilot**: To adapt the install-k3s.sh script for a CentOS bootc-derived OS and move the k3s binary under lib (instead of bin or `/opt/bin`), here are recommendations:

---

### 1. **Set `INSTALL_K3S_BIN_DIR`**

- The script already supports a custom binary directory via the `INSTALL_K3S_BIN_DIR` environment variable.
- Set this variable before running the script:
    ```sh
    INSTALL_K3S_BIN_DIR=/usr/lib ./install-k3s.sh
    ```
- This will install k3s and its symlinks (kubectl, crictl, ctr) under lib.

---

### 2. **Review Symlink Creation**

- The script creates symlinks for `kubectl`, `crictl`, and `ctr` in the same directory as the binary.
- If you want these symlinks in bin or bin (for easier access), you may need to adjust the `create_symlinks` function.

---

### 3. **SELinux Context**

- lib is typically for libraries and some system binaries, but not always in the default `$PATH`.
- Ensure the SELinux context is correct for executables in lib. You may need to adjust the `setup_selinux` function or manually set the context:
    ```sh
    sudo chcon -u system_u -r object_r -t bin_t /usr/lib/k3s
    ```

---

### 4. **Systemd Service File**

- The systemd service file will reference `${BIN_DIR}/k3s`, so no change is needed if you set `INSTALL_K3S_BIN_DIR`.

---

### 5. **PATH Considerations**

- lib is not in the default `$PATH` for most users.
- You may want to add lib to the `$PATH`, or create symlinks in bin:
    ```sh
    sudo ln -sf /usr/lib/k3s /usr/bin/k3s
    ```

---

### 6. **Script Modifications (if needed)**

- If you want lib as the default without setting an env var, modify the `setup_env` function:
    ````bash
    # filepath: /home/sylvain/tmp/install-k3s.sh
    # ...existing code...
    if [ -n "${INSTALL_K3S_BIN_DIR}" ]; then
        BIN_DIR=${INSTALL_K3S_BIN_DIR}
    else
        BIN_DIR=/usr/lib
        # ...existing code...
    fi
    # ...existing code...
    ````

---

### 7. **Documentation**

- Document this change for users and admins, as it is non-standard for binaries to reside in lib.

---

**Summary:**  
Set `INSTALL_K3S_BIN_DIR=/usr/lib` when running the script. Optionally, adjust symlink locations and ensure SELinux and PATH are handled. No major script changes are required unless you want lib as the default for all installs.