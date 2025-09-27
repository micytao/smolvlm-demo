# Multi-Architecture Build Guide

This guide shows how to build the SmolVLM container with modern UI for multiple architectures (ARM64 and x86_64) from your Apple Silicon Mac for deployment on x86_64 OpenShift.

## Prerequisites

- Podman installed on macOS
- Access to a container registry (Docker Hub, Quay.io, etc.)
- OpenShift CLI (`oc`) configured

## Method 1: Cross-Platform Build with Podman Buildx (Recommended)

### 1. Enable Multi-Architecture Support

```bash
# Install QEMU for emulation (if not already installed)
brew install qemu

# Create a multi-arch builder
podman manifest create smolvlm-demo:latest
```

### 2. Build for Multiple Architectures

```bash
# Build for ARM64 (your local Mac)
podman build \
  --platform linux/arm64 \
  --tag smolvlm-demo:arm64 \
  -f Containerfile .

# Build for x86_64 (your OpenShift cluster)
podman build \
  --platform linux/amd64 \
  --tag smolvlm-demo:amd64 \
  -f Containerfile .

# Add both architectures to the manifest
podman manifest add smolvlm-demo:latest smolvlm-demo:arm64
podman manifest add smolvlm-demo:latest smolvlm-demo:amd64
```

### 3. Push Multi-Architecture Image

```bash
# Tag for your registry
podman tag smolvlm-demo:latest your-registry/smolvlm-demo:latest

# Push the multi-arch manifest
podman manifest push smolvlm-demo:latest your-registry/smolvlm-demo:latest
```

## Method 2: Direct Cross-Platform Build (Alternative)

### Build Directly for x86_64

```bash
# Build specifically for x86_64 OpenShift
podman build \
  --platform linux/amd64 \
  --tag your-registry/smolvlm-demo:latest \
  -f Containerfile .

# Push to registry
podman push your-registry/smolvlm-demo:latest
```

## Method 3: Using Docker Buildx (If you have Docker)

### Setup Docker Buildx

```bash
# Create a new builder instance
docker buildx create --name multiarch --driver docker-container --use

# Initialize the builder
docker buildx inspect --bootstrap
```

### Build and Push Multi-Architecture

```bash
# Build and push for both architectures
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag your-registry/smolvlm-demo:latest \
  --push \
  -f Containerfile .
```

## Verification

### Check Image Architecture

```bash
# Inspect the manifest
podman manifest inspect your-registry/smolvlm-demo:latest

# Or with Docker
docker buildx imagetools inspect your-registry/smolvlm-demo:latest
```

### Test Local ARM64 Build

```bash
# Test on your Mac (ARM64) - includes modern UI with dark/light mode
podman run --platform linux/arm64 -p 8080:80 smolvlm-demo:arm64
```

## Containerfile Optimizations for Multi-Arch

The Containerfile has been optimized with these cross-platform considerations:

1. **Disabled Native Optimizations**: `-DLLAMA_NATIVE=OFF` ensures the binary works across architectures
2. **Parallel Build**: `-j$(nproc)` uses all available cores for faster compilation
3. **Release Build**: Optimized for production performance
4. **Minimal Build**: Only builds the server component we need

## OpenShift Deployment

### Update Deployment YAML

Make sure your `openshift-deployment.yaml` uses the multi-arch image:

```yaml
spec:
  template:
    spec:
      containers:
      - name: smolvlm-demo
        image: your-registry/smolvlm-demo:latest  # Multi-arch image
        # ... rest of configuration
```

### Deploy

```bash
# Deploy to OpenShift (will automatically pull x86_64 version)
oc apply -f openshift-deployment.yaml

# Verify the deployment
oc get pods
oc describe pod <pod-name>
```

## Troubleshooting

### Build Issues

1. **QEMU Emulation Slow**: Cross-compilation can be slow, expect 10-20 minutes for x86_64 build on ARM64
2. **Memory Issues**: Increase Docker/Podman memory limits for cross-compilation
3. **Registry Push Fails**: Ensure you're logged into your registry

```bash
# Login to registry
podman login your-registry.com
```

### Runtime Issues

1. **Architecture Mismatch**: Verify the deployed pod is using the correct architecture

```bash
# Check pod architecture
oc exec -it <pod-name> -- uname -m
# Should show: x86_64
```

2. **Performance Differences**: ARM64 and x86_64 may have different performance characteristics

### Registry Examples

**Docker Hub:**
```bash
podman tag smolvlm-demo:latest docker.io/username/smolvlm-demo:latest
podman push docker.io/username/smolvlm-demo:latest
```

**Quay.io:**
```bash
podman tag smolvlm-demo:latest quay.io/username/smolvlm-demo:latest
podman push quay.io/username/smolvlm-demo:latest
```

**OpenShift Internal Registry:**
```bash
# Get the registry route
oc get route default-route -n openshift-image-registry

# Tag and push
podman tag smolvlm-demo:latest <registry-route>/your-project/smolvlm-demo:latest
podman push <registry-route>/your-project/smolvlm-demo:latest
```

## Performance Notes

- **Cross-compilation time**: 15-30 minutes depending on your Mac's performance
- **Image size**: Expect ~2-3GB due to the model and dependencies
- **First deployment**: Additional 2-5 minutes for model download on OpenShift

## Best Practices

1. **Use registry**: Always push to a registry rather than trying to transfer images directly
2. **Tag versions**: Use specific version tags for production deployments
3. **Test locally**: Test the ARM64 version on your Mac before pushing
4. **Monitor resources**: Cross-compilation is resource-intensive
