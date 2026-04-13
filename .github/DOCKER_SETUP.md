# GitHub Actions Docker Setup

This repository uses GitHub Actions to automatically build and push Docker images to Docker Hub.

## Setup Instructions

### 1. Add Docker Hub PAT as GitHub Secret

You need to add your Docker Hub Personal Access Token as a GitHub secret:

1. Go to your GitHub repository: https://github.com/rob-j-au/djtip
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secret:
   - **Name**: `DOCKER_PAT`
   - **Value**: Your Docker Hub Personal Access Token
5. Click **Add secret**

**Note**: Use your Docker Hub PAT with `Read, Write, Delete` permissions.

### 2. Workflow Details

The workflow (`.github/workflows/docker-build.yml`) will:

- **Trigger on**:
  - Push to `main` branch
  - Pull requests to `main` branch
  - Manual workflow dispatch
  
- **Build**:
  - Multi-platform images (linux/amd64, linux/arm64)
  - Uses Docker Buildx for efficient builds
  - Caches layers for faster builds

- **Tag strategy**:
  - `latest` - Latest commit on main branch
  - `main` - Main branch builds
  - `main-<sha>` - Specific commit SHA
  - `v1.2.3` - Semantic version tags (if you create git tags)
  - `1.2` - Major.minor version tags

### 3. Image Location

Images are pushed to: **`robj/djtip`**

### 4. Manual Trigger

You can manually trigger a build:

1. Go to **Actions** tab in GitHub
2. Select **Build and Push Docker Image** workflow
3. Click **Run workflow**
4. Select branch and click **Run workflow**

### 5. Monitoring Builds

- View build status in the **Actions** tab
- Each push to `main` will trigger an automatic build
- Build logs show detailed progress

### 6. Using the Images

Pull the latest image:
```bash
docker pull robj/djtip:latest
```

Pull a specific version:
```bash
docker pull robj/djtip:main-abc1234
```

## Security Notes

- The Docker PAT is stored as an encrypted GitHub secret
- Only repository collaborators can view/edit secrets
- Secrets are not exposed in workflow logs
- Consider rotating the PAT periodically for security

## Troubleshooting

**Build fails with authentication error:**
- Verify the `DOCKER_PAT` secret is set correctly
- Check that the PAT hasn't expired
- Ensure the PAT has `Read, Write, Delete` permissions

**Build is slow:**
- First builds are slower (no cache)
- Subsequent builds use GitHub Actions cache
- Multi-platform builds take longer than single platform

**Image not updating in Kubernetes:**
- Check that ArgoCD is configured to pull new images
- Verify the image tag in `values.yaml` matches
- Force a hard refresh in ArgoCD if needed
