# SmolVLM Real-time Camera Demo - Build & Deploy Guide

This guide shows how to build and deploy the SmolVLM real-time camera demo with modern UI as a single container on OpenShift using Podman.

## Prerequisites

- Podman installed
- Access to an OpenShift cluster
- `oc` CLI tool installed and configured

## Architecture

The container includes:
- **llama.cpp server**: Serves the SmolVLM-500M-Instruct model on port 8080
- **Nginx web server**: Serves the modern HTML frontend on port 80 and proxies API calls
- **Supervisor**: Manages both services
- **Modern UI Features**: Dark/light mode, responsive design, smart API endpoint detection

## Build Instructions

### 1. Build the Container Image

#### For Multi-Architecture Support (macOS ARM64 → x86_64 OpenShift)

```bash
# Build for x86_64 OpenShift deployment
podman build \
  --platform linux/amd64 \
  --tag your-registry/smolvlm-demo:latest \
  -f Containerfile .

# For detailed multi-arch build instructions, see MULTI_ARCH_BUILD.md
```

#### For Single Architecture

```bash
# Build with Podman (native architecture)
podman build -t smolvlm-demo:latest -f Containerfile .

# Tag for registry
podman tag smolvlm-demo:latest your-registry/smolvlm-demo:latest
```

### 2. Test Locally (Optional)

```bash
# Run locally to test
podman run -p 8080:80 --name smolvlm-demo smolvlm-demo:latest

# Access the demo at http://localhost:8080
# The modern web interface will be served on port 80 inside the container
# Features include dark/light mode toggle and smart endpoint detection
```

### 3. Push to Registry

```bash
# Push to your container registry
podman push your-registry/smolvlm-demo:latest
```

## Deploy to OpenShift

### 1. Update Image Reference

Edit `openshift-deployment.yaml` and update the image reference:

```yaml
spec:
  template:
    spec:
      containers:
      - name: smolvlm-demo
        image: your-registry/smolvlm-demo:latest  # Update this line
```

### 2. Deploy to OpenShift

```bash
# Create a new project (optional)
oc new-project smolvlm-demo

# Deploy the application
oc apply -f openshift-deployment.yaml

# Check deployment status
oc get pods
oc get services
oc get routes
```

### 3. Access the Application

```bash
# Get the route URL
oc get route smolvlm-realtime-demo-route

# Access the demo using the provided URL
```

## Usage

1. **Open the application**: Navigate to the OpenShift route URL (automatically HTTPS)
2. **Choose your theme**: Toggle between light and dark mode using the theme button
3. **Grant camera permissions**: Allow the browser to access your camera
4. **Set API endpoint**: Use preset buttons or enter manually (auto-detected in container)
5. **Customize instruction**: Modify the instruction text (default: "What do you see?")
6. **Adjust interval**: Select how frequently to send frames (100ms to 2s)
7. **Use keyboard shortcuts**: Spacebar to start/stop, Escape to stop
8. **Start detection**: Click "Start Processing" to begin real-time object detection
9. **View results**: See the AI's responses with visual status indicators

## Troubleshooting

### Check Pod Logs

```bash
# Check application logs
oc logs -f deployment/smolvlm-realtime-demo

# Check specific container logs
oc logs -f deployment/smolvlm-realtime-demo -c smolvlm-demo
```

### Common Issues

1. **Model Download Fails**: The first startup takes time as it downloads the SmolVLM model (~2GB)
2. **Camera Access**: Ensure you're accessing via HTTPS (OpenShift route provides this)
3. **Resource Limits**: Adjust memory/CPU limits in deployment.yaml if needed
4. **CORS Issues**: The nginx configuration includes CORS headers for API access

### Resource Requirements

- **Minimum**: 4GB RAM, 2 CPU cores
- **Recommended**: 8GB RAM, 4 CPU cores
- **GPU**: Optional, but significantly improves performance

### Performance Notes

- First model load takes 2-5 minutes depending on network speed
- Inference speed depends on allocated CPU/GPU resources
- Consider using GPU-enabled nodes for better performance

## Security Considerations

- The container runs as root (required for nginx and supervisor)
- Camera access requires HTTPS (automatically provided by OpenShift routes)
- No persistent storage is used - models are downloaded on each startup

## Customization

### Model Changes

To use a different model, edit the `supervisord.conf` file and change the model reference:

```bash
command=/app/llama.cpp/build/bin/llama-server -hf your-model-name --host 0.0.0.0 --port 8080
```

### UI Modifications

Edit `index.html` to customize:
- Modern interface with CSS custom properties
- Dark/light theme colors and animations
- Default instructions and API endpoints
- Responsive design breakpoints
- Keyboard shortcuts and interactions

### Performance Tuning

Adjust resource limits in `openshift-deployment.yaml` based on your cluster's capabilities and performance requirements.
