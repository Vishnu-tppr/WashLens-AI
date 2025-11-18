# ML Model Training Guide

This guide explains how to train and convert the YOLOv8 model for cloth detection in WashLens AI.

## Prerequisites

- Python 3.8+
- CUDA-capable GPU (recommended)
- 16GB+ RAM
- 500+ labeled images

## Installation

```bash
pip install ultralytics
pip install onnx
pip install tensorflow
pip install onnx-tf
pip install tflite-support
```

## Dataset Preparation

### 1. Data Collection

Collect diverse laundry images:
- Different lighting conditions
- Various camera angles
- Multiple cloth types
- Different backgrounds
- Cluttered vs organized piles

**Recommended dataset size:**
- Training: 800 images
- Validation: 150 images
- Test: 150 images

### 2. Data Annotation

Use [Roboflow](https://roboflow.com) or [Label Studio](https://labelstud.io) to annotate bounding boxes.

**Class Labels:**
```
0: shirt
1: tshirt
2: pants
3: shorts
4: track_pant
5: towel
6: socks
7: bedsheet
```

### 3. Dataset Structure

```
laundry_dataset/
├── images/
│   ├── train/
│   │   ├── img001.jpg
│   │   ├── img002.jpg
│   │   └── ...
│   ├── val/
│   └── test/
├── labels/
│   ├── train/
│   │   ├── img001.txt
│   │   ├── img002.txt
│   │   └── ...
│   ├── val/
│   └── test/
└── data.yaml
```

**data.yaml:**
```yaml
path: ./laundry_dataset
train: images/train
val: images/val
test: images/test

nc: 8
names: ['shirt', 'tshirt', 'pants', 'shorts', 'track_pant', 'towel', 'socks', 'bedsheet']
```

### 4. Data Augmentation

Apply augmentations to increase dataset size:
- Horizontal flip
- Rotation (±15°)
- Brightness (±20%)
- Contrast adjustment
- Blur
- Mosaic augmentation

## Training

### 1. Train YOLOv8 Nano

```python
from ultralytics import YOLO

# Load pretrained model
model = YOLO('yolov8n.pt')

# Train
results = model.train(
    data='laundry_dataset/data.yaml',
    epochs=100,
    imgsz=640,
    batch=16,
    patience=20,
    save=True,
    device=0,  # GPU
    project='washlens_training',
    name='yolov8n_laundry',
    # Hyperparameters
    lr0=0.01,
    lrf=0.01,
    momentum=0.937,
    weight_decay=0.0005,
    warmup_epochs=3,
    warmup_momentum=0.8,
    box=7.5,
    cls=0.5,
    dfl=1.5,
    # Augmentation
    hsv_h=0.015,
    hsv_s=0.7,
    hsv_v=0.4,
    degrees=0.0,
    translate=0.1,
    scale=0.5,
    shear=0.0,
    perspective=0.0,
    flipud=0.0,
    fliplr=0.5,
    mosaic=1.0,
    mixup=0.0,
)

print(results)
```

### 2. Evaluate Model

```python
# Validate on test set
metrics = model.val(data='laundry_dataset/data.yaml')

print(f"mAP@0.5: {metrics.box.map50}")
print(f"mAP@0.5:0.95: {metrics.box.map}")
print(f"Precision: {metrics.box.mp}")
print(f"Recall: {metrics.box.mr}")
```

### 3. Test Inference

```python
# Test on sample image
results = model.predict(
    source='test_image.jpg',
    save=True,
    conf=0.5,
    iou=0.45
)

# Display results
for r in results:
    boxes = r.boxes
    for box in boxes:
        print(f"Class: {box.cls}, Confidence: {box.conf}, BBox: {box.xyxy}")
```

## Model Conversion

### 1. Export to ONNX

```python
from ultralytics import YOLO

model = YOLO('runs/detect/yolov8n_laundry/weights/best.pt')

# Export to ONNX
model.export(
    format='onnx',
    imgsz=640,
    simplify=True,
    opset=12
)

print("Exported to ONNX: best.onnx")
```

### 2. Convert ONNX to TensorFlow

```bash
python -m onnx_tf.backend.cli convert \
    -i best.onnx \
    -o washlens_tf
```

### 3. Convert to TFLite (INT8 Quantization)

```python
import tensorflow as tf
import numpy as np
from PIL import Image
import glob

# Load TF model
converter = tf.lite.TFLiteConverter.from_saved_model('washlens_tf')

# Representative dataset for quantization
def representative_dataset():
    # Use 100 sample images from training set
    image_paths = glob.glob('laundry_dataset/images/train/*.jpg')[:100]
    
    for image_path in image_paths:
        img = Image.open(image_path).resize((640, 640))
        img_array = np.array(img, dtype=np.float32) / 255.0
        img_array = np.expand_dims(img_array, axis=0)
        yield [img_array]

# Set optimization flags
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.representative_dataset = representative_dataset
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.float32
converter.inference_output_type = tf.float32

# Convert
tflite_model = converter.convert()

# Save
with open('washlens_yolo.tflite', 'wb') as f:
    f.write(tflite_model)

print("TFLite model saved: washlens_yolo.tflite")

# Check model size
import os
size_mb = os.path.getsize('washlens_yolo.tflite') / (1024 * 1024)
print(f"Model size: {size_mb:.2f} MB")
```

### 4. Verify TFLite Model

```python
import tensorflow as tf
import numpy as np
from PIL import Image

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path='washlens_yolo.tflite')
interpreter.allocate_tensors()

# Get input/output details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Input shape:", input_details[0]['shape'])
print("Output shape:", output_details[0]['shape'])

# Test inference
test_image = Image.open('test.jpg').resize((640, 640))
input_data = np.array(test_image, dtype=np.float32) / 255.0
input_data = np.expand_dims(input_data, axis=0)

interpreter.set_tensor(input_details[0]['index'], input_data)
interpreter.invoke()
output_data = interpreter.get_tensor(output_details[0]['index'])

print("Inference successful!")
print("Output shape:", output_data.shape)
```

### 5. Create Labels File

```python
labels = [
    'shirt',
    'tshirt',
    'pants',
    'shorts',
    'track_pant',
    'towel',
    'socks',
    'bedsheet'
]

with open('labels.txt', 'w') as f:
    for label in labels:
        f.write(label + '\n')
```

## Benchmarking

### Accuracy Metrics

Target performance:
- **mAP@0.5:** ≥ 0.90
- **mAP@0.5:0.95:** ≥ 0.75
- **Precision:** ≥ 0.88
- **Recall:** ≥ 0.85

### Inference Speed

Test on various devices:

```python
import time
import tensorflow as tf
import numpy as np

interpreter = tf.lite.Interpreter(model_path='washlens_yolo.tflite')
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Prepare dummy input
input_data = np.random.rand(1, 640, 640, 3).astype(np.float32)

# Warm-up
for _ in range(10):
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()

# Benchmark
num_runs = 100
start_time = time.time()

for _ in range(num_runs):
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()

end_time = time.time()

avg_time_ms = ((end_time - start_time) / num_runs) * 1000
print(f"Average inference time: {avg_time_ms:.2f} ms")
```

**Target latency:**
- High-end device: < 100ms
- Mid-range device: 150-300ms
- Low-end device: < 500ms

## Deployment

### 1. Copy to Flutter Assets

```bash
cp washlens_yolo.tflite ../assets/models/
cp labels.txt ../assets/models/
```

### 2. Update pubspec.yaml

Ensure assets are included:
```yaml
flutter:
  assets:
    - assets/models/washlens_yolo.tflite
    - assets/models/labels.txt
```

### 3. Test in App

Run Flutter app and test detection:
```bash
flutter run
```

## Continuous Improvement

### 1. Collect Edge Cases

Monitor production usage for:
- Low-confidence detections
- Missed items
- False positives
- New clothing types

### 2. Retrain Periodically

Add new data and retrain:
```bash
# Combine old and new datasets
# Retrain with updated data.yaml
yolo train data=updated_data.yaml model=yolov8n_laundry/weights/best.pt epochs=50
```

### 3. A/B Testing

Deploy multiple model versions:
- `washlens_yolo_v1.tflite`
- `washlens_yolo_v2.tflite`

Compare accuracy in production.

## Troubleshooting

### Low Accuracy
- Increase dataset size
- Add more augmentations
- Train for more epochs
- Use YOLOv8s (larger model)

### Slow Inference
- Reduce input size (640 → 416)
- Use INT8 quantization
- Enable GPU acceleration

### High False Positives
- Increase confidence threshold (0.5 → 0.6)
- Adjust NMS IoU threshold

### Missing Detections
- Increase recall (lower confidence threshold)
- Add more training data for specific classes

## Resources

- [Ultralytics Docs](https://docs.ultralytics.com)
- [TFLite Guide](https://www.tensorflow.org/lite)
- [YOLO Paper](https://arxiv.org/abs/2304.00501)
- [Roboflow Dataset](https://universe.roboflow.com)

---

**Last Updated:** November 15, 2025
