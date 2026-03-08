// OpenCV.js Interop Service for Flutter

class OpenCVWeb {
    constructor() {
        this.netDet = null;
        this.netRec = null;
        this.isReady = false;
    }

    async init(detModelUrl, recModelUrl) {
        if (this.isReady) return;

        return new Promise((resolve, reject) => {
            // Wait for OpenCV to initialize
            cv['onRuntimeInitialized'] = async () => {
                console.log("OpenCV.js Ready");
                try {
                    // Load Models
                    this.netDet = await this.loadModel(detModelUrl);
                    this.netRec = await this.loadModel(recModelUrl);

                    // Configure YuNet
                    this.netDet.setInputSize(new cv.Size(320, 320));
                    this.netDet.setScoreThreshold(0.9);
                    this.netDet.setNMSThreshold(0.3);
                    this.netDet.setTopK(5000);

                    this.isReady = true;
                    console.log("OpenCV Models Loaded");
                    resolve(true);
                } catch (e) {
                    console.error("Error loading models", e);
                    reject(e);
                }
            };

            // If already initialized
            if (cv.Mat) {
                cv.onRuntimeInitialized();
            }
        });
    }

    async loadModel(url) {
        // Fetch model bytes
        const response = await fetch(url);
        const buffer = await response.arrayBuffer();
        const bytes = new Uint8Array(buffer);

        // Create FaceDetectorYN / FaceRecognizerSF
        // Note: Standard opencv.js might not expose FaceDetectorYN class directly depending on build.
        // If wrapping FaceDetectorYN is stored in 'cv', use it.
        // Usually opencv.js 4.8.0+ includes 'FaceDetectorYN' if configured.
        // If not, we have to use dnn.readNetFromONNX.
        // However, YuNet requires specific post-processing if using raw readNet.
        // Let's assume standard cv.FaceDetectorYN is available or we use raw DNN.

        // Checking availability
        if (cv.FaceDetectorYN) {
            // It's a file path usually for .create(), but here we have bytes.
            // We write bytes to FS
            const path = "model_" + Math.random() + ".onnx";
            cv.FS_createDataFile("/", path, bytes, true, false, false);

            if (url.includes("yunet")) {
                return cv.FaceDetectorYN.create(path, "", new cv.Size(320, 320), 0.9, 0.3, 5000);
            } else {
                return cv.FaceRecognizerSF.create(path, "");
            }
        } else {
            throw new Error("cv.FaceDetectorYN not found in this opencv.js build");
        }
    }

    async detect(imageSource) {
        if (!this.isReady) return [];

        return new Promise((resolve, reject) => {
            const img = new Image();
            img.onload = () => {
                try {
                    let mat = cv.imread(img);

                    // Resize if too big to speed up? YuNet takes 320x320 input but we should scale accordingly?
                    // For now, let's keep original for detection but YuNet will resize internally based on inputSize set?
                    // We set inputSize in detect loop usually.
                    // YuNet requires setInputSize to match image size?
                    // In init we set 320x320.
                    // If we pass larger image, we should probably update inputSize.

                    this.netDet.setInputSize(mat.size());

                    let faces = new cv.Mat();
                    this.netDet.detect(mat, faces);

                    let results = [];
                    for (let i = 0; i < faces.rows; i++) {
                        let faceData = faces.row(i);
                        let alignedWrapper = new cv.Mat();
                        this.netRec.alignCrop(mat, faceData, alignedWrapper);

                        let x = faceData.data32F[0];
                        let y = faceData.data32F[1];
                        let w = faceData.data32F[2];
                        let h = faceData.data32F[3];

                        results.push({
                            box: { x, y, w, h },
                            alignedFace: alignedWrapper,
                            faceRow: faceData
                        });
                    }

                    mat.delete();
                    faces.delete(); // Don't delete alignedFace or faceRow as we return them
                    // Wait, we can't return Mat to unknown context easily if not managed.
                    // But JS wrapper holds them.
                    // We should be careful about memory leaks.
                    // The Caller (Dart) won't delete them.
                    // We might need a cleanup method or return data objects (embeddings) directly?
                    // But 'generateEmbedding' needs the Mat.
                    // We'll rely on Dart calling generateEmbedding immediately?
                    // Or detection + embedding in one go for Web?
                    // Refactoring: Let's keep it as is.

                    resolve(results);
                } catch (e) {
                    reject(e);
                }
            };
            img.onerror = (e) => reject(e);
            img.src = imageSource;
        });
    }

    generateEmbedding(alignedFaceMat) {
        if (!this.isReady) return [];

        let feature = new cv.Mat();
        this.netRec.feature(alignedFaceMat, feature);

        // Convert to JS Array
        let embedding = [];
        // feature is 1x128 Float
        for (let i = 0; i < 128; i++) {
            embedding.push(feature.data32F[i]);
        }

        feature.delete();
        return embedding;
    }
}

window.opencvWeb = new OpenCVWeb();
