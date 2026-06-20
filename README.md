# CI-CD

Spring Boot 애플리케이션을 Docker 이미지로 빌드하고 Kubernetes 클러스터에 배포하기 위한 CI/CD 인프라 템플릿입니다.

> **실제 앱 코드는 별도 레포에 있습니다.**
> 👉 [springboot-cicd-k8s](https://github.com/hyominleee/springboot-cicd-k8s)

---

## 레포 구조

```
CI-CD/
├── Jenkinsfile                  # Jenkins 파이프라인 - 직접 배포 방식
├── Jenkinsfile-CI.docker        # Jenkins 파이프라인 - GitOps 방식
├── Dockerfile                   # 앱 컨테이너 빌드 설정
├── env.properties               # K8s 매니페스트 생성용 변수 정의
├── gen-yaml.sh                  # .t 템플릿 → .yaml 변환 스크립트
├── docker-build.sh              # 로컬 Docker 이미지 빌드 스크립트
├── docker-push.sh               # 로컬 Docker 레지스트리 푸시 스크립트
├── auto-commit.sh               # 파이프라인 트리거 테스트용 자동 커밋 스크립트
├── k8s/                         # 단일 환경 K8s 매니페스트
│   ├── deploy.t / deploy.yaml
│   ├── service.t / service.yaml
│   └── ingress.t / ingress.yaml
└── k8s-profile/                 # 환경별 K8s 매니페스트 (네임스페이스 미포함)
    ├── dev/
    ├── stage/
    └── prod/
```

---

## 두 레포의 역할

| 레포 | 역할 |
|------|------|
| [springboot-cicd-k8s](https://github.com/hyominleee/springboot-cicd-k8s) | Spring Boot 앱 소스 코드 |
| **CI-CD** (이 레포) | Dockerfile, Jenkins 파이프라인, K8s 매니페스트, 배포 스크립트 |

Jenkins가 파이프라인을 실행할 때 `springboot-cicd-k8s` 레포를 클론하여 빌드합니다.

---

## 파이프라인

### Jenkinsfile — 직접 배포 방식

```
Clone → Maven 빌드 → 이미지 태그 계산 → Docker Build/Push → kubectl apply
```

Jenkins가 앱 레포를 클론하여 빌드한 뒤, K8s 클러스터에 직접 `kubectl apply`로 배포합니다.

### Jenkinsfile-CI.docker — GitOps 방식

```
Clone → Maven 빌드 → 이미지 태그 계산 → Docker Build/Push
      → deploy.yaml 이미지 태그 수정 → gitops 브랜치에 commit/push
```

배포 상태를 코드로 관리합니다. 이미지 태그가 변경된 `deploy.yaml`을 `gitops` 브랜치에 커밋하여, ArgoCD 등의 GitOps 툴이 자동으로 배포를 반영하도록 합니다.

---

## K8s 매니페스트 템플릿 시스템

`.t` 파일은 `${변수명}` 형식의 템플릿이고, `gen-yaml.sh`가 `env.properties`의 값을 읽어 `.yaml`을 생성합니다.

**1. `env.properties` 설정**

```properties
SERVICE_NAME="<YOUR_SERVICE_NAME>"
IMAGE_NAME="<YOUR_IMAGE_NAME>"
VERSION="1.0.0"
DOCKER_REGISTRY="<YOUR_REGISTRY>/<YOUR_PROJECT>"
USER_NAME=<YOUR_USERNAME>
NAMESPACE=<YOUR_NAMESPACE>
REPLICAS=1
CONTAINER_PORT=8080
```

**2. yaml 생성**

```bash
# 현재 디렉토리 기준 yaml 생성
./gen-yaml.sh

# 생성된 yaml 삭제
./gen-yaml.sh delete
```

### k8s/ vs k8s-profile/

| 디렉토리 | 설명 |
|----------|------|
| `k8s/` | Deployment + Service + Ingress 포함. `namespace` 필드 있음. `kubectl apply -f ./k8s`로 단일 환경 배포 시 사용 |
| `k8s-profile/` | dev / stage / prod 환경별 Deployment + Service. `namespace` 필드 없음. `-n` 옵션으로 네임스페이스를 지정하여 환경별 배포 시 사용 |

---

## 시작하기

### 1. Jenkinsfile 설정

`Jenkinsfile` 또는 `Jenkinsfile-CI.docker` 상단의 환경 변수를 수정합니다.

```groovy
environment {
    GIT_URL                = '<YOUR_GIT_REPO_URL>'       // 앱 레포 URL
    GIT_BRANCH             = 'main'
    GIT_ID                 = '<YOUR_GIT_CREDENTIAL_ID>'  // Jenkins Credential ID
    IMAGE_NAME             = '<YOUR_IMAGE_NAME>'          // 예: username-appname
    IMAGE_REGISTRY_URL     = '<YOUR_REGISTRY_URL>'
    IMAGE_REGISTRY_PROJECT = '<YOUR_REGISTRY_PROJECT>'
    DOCKER_CREDENTIAL_ID   = '<YOUR_DOCKER_CREDENTIAL_ID>'
    K8S_NAMESPACE          = '<YOUR_K8S_NAMESPACE>'
}
```

### 2. env.properties 설정

`env.properties`의 플레이스홀더를 실제 값으로 채웁니다.

### 3. K8s 매니페스트 생성

```bash
./gen-yaml.sh
```

### 4. Jenkins 잡 구성

Jenkins에서 Pipeline 잡을 생성하고, 이 레포의 `Jenkinsfile`을 Pipeline Script 경로로 지정합니다.

---

## 로컬 빌드 및 푸시

앱 레포(`springboot-cicd-k8s`)에서 먼저 Maven 빌드 후 아래 스크립트를 실행합니다.

```bash
# Docker 이미지 빌드
./docker-build.sh

# 레지스트리에 푸시 (비밀번호는 환경변수로 주입)
export DOCKER_REGISTRY_PASSWORD="..."
./docker-push.sh
```
