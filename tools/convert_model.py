#!/usr/bin/env python3
"""
Model Conversion Script for WashLens AI
Converts YOLOv8 → ONNX → TensorFlow → TFLite (INT8)
"""

import os
import sys
import argparse
import tensorflow as tf
import numpy as np
from PIL import Image
import glob

def export_to_onnx(model_path, output_path):
    """Export YOLOv8 to ONNX format"""
    print("Step 1: Exporting to ONNX...")
    
    try:
        from ultralytics import YOLO
        model = YOLO(model_path)
        model.export(
            format='onnx',
            imgsz=640,
            simplify=True,
            opset=12
        )
        print(f"✓ ONNX model saved: {output_path}")
        return True
    except Exception as e:
        print(f"✗ ONNX export failed: {e}")
        return False

def convert_onnx_to_tf(onnx_path, tf_path):
    """Convert ONNX to TensorFlow SavedModel"""
    print("\nStep 2: Converting ONNX to TensorFlow...")
    
    try:
        import onnx
        from onnx_tf.backend import prepare
        
        onnx_model = onnx.load(onnx_path)
        tf_rep = prepare(onnx_model)
        tf_rep.export_graph(tf_path)
        print(f"✓ TensorFlow model saved: {tf_path}")
        return True
    except Exception as e:
        print(f"✗ TensorFlow conversion failed: {e}")
        return False

def convert_tf_to_tflite(tf_path, tflite_path, dataset_path=None):
    """Convert TensorFlow to TFLite with INT8 quantization"""
    print("\nStep 3: Converting to TFLite with INT8 quantization...")
    
    try:
        converter = tf.lite.TFLiteConverter.from_saved_model(tf_path)
        
        # Representative dataset for quantization
        if dataset_path and os.path.exists(dataset_path):
            def representative_dataset():
                image_paths = glob.glob(os.path.join(dataset_path, '*.jpg'))[:100]
                
                for image_path in image_paths:
                    img = Image.open(image_path).resize((640, 640))
                    img_array = np.array(img, dtype=np.float32) / 255.0
                    img_array = np.expand_dims(img_array, axis=0)
                    yield [img_array]
            
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            converter.representative_dataset = representative_dataset
            converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
            converter.inference_input_type = tf.float32
            converter.inference_output_type = tf.float32
            print("  Using INT8 quantization with representative dataset")
        else:
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            print("  Using dynamic range quantization (no dataset provided)")
        
        tflite_model = converter.convert()
        
        with open(tflite_path, 'wb') as f:
            f.write(tflite_model)
        
        size_mb = os.path.getsize(tflite_path) / (1024 * 1024)
        print(f"✓ TFLite model saved: {tflite_path}")
        print(f"  Model size: {size_mb:.2f} MB")
        return True
    except Exception as e:
        print(f"✗ TFLite conversion failed: {e}")
        return False

def verify_tflite_model(tflite_path, test_image_path=None):
    """Verify TFLite model works"""
    print("\nStep 4: Verifying TFLite model...")
    
    try:
        interpreter = tf.lite.Interpreter(model_path=tflite_path)
        interpreter.allocate_tensors()
        
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"✓ Model loaded successfully")
        print(f"  Input shape: {input_details[0]['shape']}")
        print(f"  Output shape: {output_details[0]['shape']}")
        
        # Test inference
        if test_image_path and os.path.exists(test_image_path):
            test_image = Image.open(test_image_path).resize((640, 640))
            input_data = np.array(test_image, dtype=np.float32) / 255.0
            input_data = np.expand_dims(input_data, axis=0)
            
            import time
            start = time.time()
            interpreter.set_tensor(input_details[0]['index'], input_data)
            interpreter.invoke()
            end = time.time()
            
            output_data = interpreter.get_tensor(output_details[0]['index'])
            inference_time = (end - start) * 1000
            
            print(f"✓ Test inference successful")
            print(f"  Inference time: {inference_time:.2f} ms")
        
        return True
    except Exception as e:
        print(f"✗ Verification failed: {e}")
        return False

def create_labels_file(output_path):
    """Create labels.txt file"""
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
    
    with open(output_path, 'w') as f:
        for label in labels:
            f.write(label + '\n')
    
    print(f"\n✓ Labels file created: {output_path}")

def main():
    parser = argparse.ArgumentParser(description='Convert YOLOv8 model to TFLite')
    parser.add_argument('--model', type=str, required=True, help='Path to YOLOv8 .pt model')
    parser.add_argument('--output', type=str, default='washlens_yolo.tflite', help='Output TFLite path')
    parser.add_argument('--dataset', type=str, help='Path to representative dataset (for INT8 quantization)')
    parser.add_argument('--test-image', type=str, help='Path to test image for verification')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.model):
        print(f"Error: Model file not found: {args.model}")
        sys.exit(1)
    
    print("=" * 60)
    print("WashLens AI Model Conversion")
    print("=" * 60)
    
    # Create temp directories
    temp_dir = 'temp_conversion'
    os.makedirs(temp_dir, exist_ok=True)
    
    onnx_path = os.path.join(temp_dir, 'model.onnx')
    tf_path = os.path.join(temp_dir, 'model_tf')
    
    # Step 1: YOLOv8 → ONNX
    if not export_to_onnx(args.model, onnx_path):
        sys.exit(1)
    
    # Step 2: ONNX → TensorFlow
    if not convert_onnx_to_tf(onnx_path, tf_path):
        sys.exit(1)
    
    # Step 3: TensorFlow → TFLite
    if not convert_tf_to_tflite(tf_path, args.output, args.dataset):
        sys.exit(1)
    
    # Step 4: Verify
    if not verify_tflite_model(args.output, args.test_image):
        sys.exit(1)
    
    # Create labels file
    labels_path = args.output.replace('.tflite', '_labels.txt')
    create_labels_file(labels_path)
    
    print("\n" + "=" * 60)
    print("✓ Conversion completed successfully!")
    print("=" * 60)
    print(f"\nOutput files:")
    print(f"  - {args.output}")
    print(f"  - {labels_path}")
    print(f"\nNext steps:")
    print(f"  1. Copy {args.output} to assets/models/washlens_yolo.tflite")
    print(f"  2. Copy {labels_path} to assets/models/labels.txt")
    print(f"  3. Run 'flutter run' to test in app")

if __name__ == '__main__':
    main()
