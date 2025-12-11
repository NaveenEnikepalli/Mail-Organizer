#!/usr/bin/env python3
"""
Mail Mind TFLite Validator

Quick test to verify that the converted TFLite model works correctly.
Tests model loading and inference without requiring the full Flutter app.

Usage:
    python3 test_tflite.py [--model <path>]

Default model path: assets/models/priority_classifier.tflite
"""

import sys
from pathlib import Path


def main():
    """Test TFLite model."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Test TFLite model')
    parser.add_argument(
        '--model',
        default='assets/models/priority_classifier.tflite',
        help='Path to TFLite model file',
    )
    
    args = parser.parse_args()
    model_path = Path(args.model)
    
    print(f"\n{'='*60}")
    print(f"  Mail Mind TFLite Model Test")
    print(f"{'='*60}\n")
    
    # Check file exists
    if not model_path.exists():
        print(f"✗ Model file not found: {model_path}")
        return 1
    
    print(f"✓ Model file found: {model_path}")
    print(f"  Size: {model_path.stat().st_size / (1024*1024):.2f} MB\n")
    
    try:
        import tensorflow as tf
        import numpy as np
        
        print("[1/3] Loading TFLite interpreter...")
        interpreter = tf.lite.Interpreter(model_path=str(model_path))
        interpreter.allocate_tensors()
        print("✓ Interpreter loaded\n")
        
        print("[2/3] Inspecting model...")
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"  Inputs:  {len(input_details)} tensor(s)")
        for inp in input_details:
            print(f"    - Shape: {inp['shape']}, dtype: {inp['dtype'].__name__}")
        
        print(f"  Outputs: {len(output_details)} tensor(s)")
        for out in output_details:
            print(f"    - Shape: {out['shape']}, dtype: {out['dtype'].__name__}")
        print()
        
        print("[3/3] Running inference...")
        input_shape = input_details[0]['shape']
        n_features = input_shape[1]
        
        # Create test input
        test_input = np.random.randn(1, n_features).astype(np.float32)
        
        interpreter.set_tensor(input_details[0]['index'], test_input)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]['index'])
        
        print(f"✓ Inference successful")
        print(f"  Input shape:  {test_input.shape}")
        print(f"  Output shape: {output.shape}")
        print(f"  Output value: {output.flatten()[0]:.4f}")
        print()
        
        print("="*60)
        print("  ✓ All tests passed!")
        print("="*60 + "\n")
        return 0
        
    except ImportError:
        print("✗ TensorFlow not installed")
        print("  Install with: pip install tensorflow\n")
        return 1
    except Exception as e:
        print(f"✗ Error: {e}\n")
        return 1


if __name__ == '__main__':
    sys.exit(main())
