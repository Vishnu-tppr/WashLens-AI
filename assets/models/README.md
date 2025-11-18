# Placeholder TFLite Model

This is a placeholder file. The actual TFLite model (`washlens_yolo.tflite`) should be:

1. **Trained** following the guide in `docs/ML_TRAINING.md`
2. **Converted** using the script in `tools/convert_model.py`
3. **Placed** in this directory

## Quick Start (Development)

For development and testing without a trained model, you can:

### Option 1: Use Mock Detector

The app includes a mock detector that returns random detections for testing UI flows.

### Option 2: Download Pre-trained Model

If available, download from:
- Project releases page
- Google Drive link (team only)
- Firebase Storage

### Option 3: Train Your Own

```bash
# Install dependencies
pip install ultralytics tensorflow onnx onnx-tf

# Train model (requires labeled dataset)
python tools/train_model.py --data laundry_dataset/data.yaml --epochs 100

# Convert to TFLite
python tools/convert_model.py --model runs/detect/train/weights/best.pt --output assets/models/washlens_yolo.tflite
```

## Model Specifications

- **Architecture:** YOLOv8 Nano
- **Input Size:** 640x640x3
- **Output:** 8400 detections × 13 features
- **Quantization:** INT8
- **Size:** ~6 MB
- **Classes:** 8 (shirt, tshirt, pants, shorts, track_pant, towel, socks, bedsheet)

## Expected Performance

- **Inference Time:** 150-300ms (mid-range device)
- **mAP@0.5:** ≥0.90
- **Accuracy:** 92%+

## Troubleshooting

If you see "Model not found" errors:
1. Check this file exists: `assets/models/washlens_yolo.tflite`
2. Verify pubspec.yaml includes the asset
3. Run `flutter clean && flutter pub get`
4. Rebuild the app

## Contact

For access to the pre-trained model, contact:
- Email: dev@washlens.ai
- Team lead: @vishnu
