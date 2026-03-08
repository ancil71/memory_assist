// Web Face Service for Flutter Interop

class WebFaceService {
  constructor() {
    this.modelsLoaded = false;
  }

  async loadModels() {
    if (this.modelsLoaded) return;
    
    console.log("Loading Face API Models...");
    const MODEL_URL = 'assets/models';

    await faceapi.loadSsdMobilenetv1Model(MODEL_URL);
    await faceapi.loadFaceLandmarkModel(MODEL_URL);
    await faceapi.loadFaceRecognitionModel(MODEL_URL);

    this.modelsLoaded = true;
    console.log("Face API Models Loaded!");
  }

  async detectFace(imageElementOrUrl) {
    if (!this.modelsLoaded) await this.loadModels();

    let input;
    if (typeof imageElementOrUrl === 'string') {
        const img = new Image();
        img.src = imageElementOrUrl;
        await img.decode();
        input = img;
    } else {
        input = imageElementOrUrl;
    }

    // Detect single face with landmarks and descriptor
    const detection = await faceapi.detectSingleFace(input)
      .withFaceLandmarks()
      .withFaceDescriptor();

    if (!detection) {
        return null; // No face found
    }

    return {
        box: {
            x: detection.detection.box.x,
            y: detection.detection.box.y,
            width: detection.detection.box.width,
            height: detection.detection.box.height
        },
        descriptor: Array.from(detection.descriptor)
    };
  }

  async detectAllFaces(imageElementOrUrl) {
      if (!this.modelsLoaded) await this.loadModels();

    let input;
    if (typeof imageElementOrUrl === 'string') {
        const img = new Image();
        img.src = imageElementOrUrl;
        await img.decode();
        input = img;
    } else {
        input = imageElementOrUrl;
    }
    
    const detections = await faceapi.detectAllFaces(input)
        .withFaceLandmarks()
        .withFaceDescriptors();
        
    return detections.map(d => ({
        box: {
            x: d.detection.box.x,
            y: d.detection.box.y,
            width: d.detection.box.width,
            height: d.detection.box.height
        },
        descriptor: Array.from(d.descriptor)
    }));
  }
}

window.webFaceService = new WebFaceService();
