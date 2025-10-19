# 🚀 Docker CI/CD Stack — GitLab Learning Environment

A **fully automated GitLab CI/CD stack** designed for training and experimentation.  
This setup lets you deploy a local GitLab instance and a Docker-based GitLab Runner in a few minutes.

---

## 🧩 Features

- 🐳 **Dockerized GitLab CE** with Omnibus configuration  
- ⚙️ **Docker Runner (DinD)** automatically registered to the server  
- 🌐 **Custom Docker network** (`10.0.0.0/24`) with fixed IPs  
- 🔐 Auto-generated **root password** and **runner registration token**  
- 🎓 Ideal for **DevOps and CI/CD workshops** or student labs

---

## 🏗️ Structure

```
docker-cicd-stack/
├── deploy_coding_stack.sh # Main automation script
├── serveur/
│ └── docker-compose.yml # GitLab server stack
└── runneur/
└── docker-compose.yml # GitLab Runner stack
```



---

## ⚙️ Requirements

- Linux host (Debian 12/13 recommended)  
- Docker & Docker Compose plugin  
- Root privileges (for first install)

---

## 🚀 Installation

```bash
git clone https://github.com/Jerom-e/docker-cicd-stack.git
cd docker-cicd-stack
sudo ./deploy_coding_stack.sh
