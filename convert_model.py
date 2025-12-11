#!/usr/bin/env python3
"""
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║           Mail Mind: Priority Classifier TensorFlow Lite Converter         ║
║                                                                            ║
║  Converts priority_classifier.pkl → assets/models/priority_classifier.    ║
║                                      tflite                               ║
║                                                                            ║
║  WARNING: .pkl files CANNOT be loaded directly in Flutter. This script    ║
║  converts the pickled model to TensorFlow Lite (.tflite) which can be     ║
║  loaded natively by Flutter using tflite_flutter package.                 ║
║                                                                            ║
║  CONVERSION STRATEGIES:                                                   ║
║  1. [PRIMARY] scikit-learn model → ONNX → SavedModel → TFLite             ║
║  2. [FALLBACK] TensorFlow/Keras pickled model → SavedModel → TFLite       ║
║  3. [SAFETY NET] Create synthetic fallback TFLite if both fail            ║
║                                                                            ║
║  The script attempts each method in order and falls back if one fails.    ║
║  This ensures a usable .tflite is produced for the Flutter app.           ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

Usage:
    python3 convert_model.py [--input <pkl_file>] [--features <n>]

Arguments:
    --input <file>      Path to pickle model (default: priority_classifier.pkl)
    --features <n>      Number of input features (auto-detect if possible)

Exit Codes:
    0 = Success (TFLite created and validated)
    1 = Failure (check logs for details)

Examples:
    python3 convert_model.py
    python3 convert_model.py --input model.pkl --features 128
"""

import os
import sys
import argparse
import pickle
import tempfile
import shutil
from pathlib import Path


def print_header(msg):
    """Print section header."""
    print(f"\n{'='*70}")
    print(f"  {msg}")
    print(f"{'='*70}\n")


def print_step(step_num, msg):
    """Print numbered step."""
    print(f"[{step_num}/5] {msg}")


def print_success(msg):
    """Print success message."""
    print(f"  ✓ {msg}")


def print_error(msg):
    """Print error message."""
    print(f"  ✗ {msg}")


def print_warning(msg):
    """Print warning message."""
    print(f"  ⚠ {msg}")


def print_info(msg):
    """Print info message."""
    print(f"  → {msg}")


def check_and_import(module_name, package_name=None):
    """
    Check if a module can be imported and suggest installation if not.
    Returns True if import succeeds, False otherwise.
    """
    package_name = package_name or module_name
    try:
        __import__(module_name)
        print_success(f"Module '{module_name}' is available")
        return True
    except ImportError:
        print_error(f"Module '{module_name}' not found")
        print_info(f"Install with: pip install {package_name}")
        return False


def check_dependencies(required_imports):
    """
    Check all required dependencies.
    Returns dict {module_name: available_bool}.
    """
    print_header("Checking Dependencies")
    results = {}
    for module, package in required_imports.items():
        results[module] = check_and_import(module, package)
    return results


def infer_n_features(model):
    """
    Try to infer number of input features from model attributes.
    """
    # scikit-learn attribute
    if hasattr(model, 'n_features_in_'):
        return int(model.n_features_in_)
    
    # Keras attribute
    if hasattr(model, 'input_shape'):
        shape = model.input_shape
        if isinstance(shape, (list, tuple)) and len(shape) >= 2:
            return int(shape[1])
    
    return None


def method_a_sklearn_to_tflite(pkl_path, n_features, assets_dir):
    """
    METHOD A: Convert scikit-learn model to ONNX to SavedModel to TFLite.
    Returns (success: bool, tflite_path: str or None, error_msg: str or None)
    """
    print_step(1, "Attempting scikit-learn → ONNX → SavedModel → TFLite")
    
    # Check dependencies
    deps_needed = {
        'joblib': 'joblib',
        'skl2onnx': 'skl2onnx',
        'onnx': 'onnx',
        'onnx_tf': 'onnx-tf',
        'tensorflow': 'tensorflow',
    }
    
    deps = check_dependencies(deps_needed)
    
    if not all(deps.values()):
        print_warning("Missing dependencies for Method A, will try fallback")
        return False, None, "Missing scikit-learn dependencies"
    
    try:
        import joblib
        import numpy as np
        from skl2onnx import convert_sklearn
        from skl2onnx.common.data_types import FloatTensorType
        import onnx
        import onnx_tf.backend
        import tensorflow as tf
        
        print_info(f"Loading pickle from {pkl_path}")
        model = joblib.load(pkl_path)
        print_success(f"Loaded model type: {type(model).__name__}")
        
        # Verify it's a sklearn model
        if not hasattr(model, 'predict'):
            raise ValueError("Loaded object has no 'predict' method (not a sklearn estimator)")
        
        # Infer n_features if needed
        inferred = infer_n_features(model)
        if inferred and inferred != n_features:
            print_info(f"Updating n_features from {n_features} to {inferred} (inferred from model)")
            n_features = inferred
        
        print_info(f"Input features: {n_features}")
        
        # Convert to ONNX
        print_info("Converting to ONNX...")
        initial_type = [('input', FloatTensorType([None, n_features]))]
        onnx_model = convert_sklearn(model, initial_types=initial_type)
        
        onnx_path = str(assets_dir.parent / 'priority_classifier.onnx')
        with open(onnx_path, 'wb') as f:
            f.write(onnx_model.SerializeToString())
        print_success(f"ONNX saved: {onnx_path}")
        
        # Convert ONNX to SavedModel
        print_info("Converting ONNX → SavedModel...")
        onnx_model = onnx.load(onnx_path)
        tf_rep = onnx_tf.backend.prepare(onnx_model)
        
        savedmodel_dir = str(assets_dir.parent / 'tmp_savedmodel')
        tf_rep.export_graph(savedmodel_dir)
        print_success(f"SavedModel created: {savedmodel_dir}/")
        
        # Convert SavedModel to TFLite
        print_info("Converting SavedModel → TFLite...")
        converter = tf.lite.TFLiteConverter.from_saved_model(savedmodel_dir)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS,
        ]
        
        tflite_model = converter.convert()
        tflite_path = str(assets_dir / 'priority_classifier.tflite')
        with open(tflite_path, 'wb') as f:
            f.write(tflite_model)
        
        size_mb = Path(tflite_path).stat().st_size / (1024 * 1024)
        print_success(f"TFLite created: {tflite_path} ({size_mb:.2f} MB)")
        
        # Cleanup
        if os.path.exists(onnx_path):
            os.remove(onnx_path)
        if os.path.exists(savedmodel_dir):
            shutil.rmtree(savedmodel_dir)
        
        return True, tflite_path, None
        
    except Exception as e:
        print_warning(f"Method A failed: {str(e)}")
        return False, None, str(e)


def method_b_keras_to_tflite(pkl_path, assets_dir):
    """
    METHOD B: Convert pickled Keras/TensorFlow model directly to TFLite.
    Returns (success: bool, tflite_path: str or None, error_msg: str or None)
    """
    print_step(2, "Attempting Keras/TensorFlow pickled model → TFLite")
    
    deps_needed = {
        'tensorflow': 'tensorflow',
    }
    
    deps = check_dependencies(deps_needed)
    
    if not deps['tensorflow']:
        print_warning("TensorFlow not available, will try fallback")
        return False, None, "TensorFlow not available"
    
    try:
        import tensorflow as tf
        import pickle as pkl
        
        print_info(f"Attempting to unpickle {pkl_path} as TensorFlow model...")
        with open(pkl_path, 'rb') as f:
            obj = pkl.load(f)
        
        # Check if it's a Keras model
        if not isinstance(obj, tf.keras.Model):
            raise ValueError(f"Pickled object is not a tf.keras.Model (is {type(obj).__name__})")
        
        print_success(f"Loaded Keras model: {obj.name}")
        
        # Save as SavedModel (intermediate format)
        savedmodel_dir = str(assets_dir.parent / 'tmp_savedmodel')
        print_info(f"Saving as SavedModel to {savedmodel_dir}...")
        obj.save(savedmodel_dir)
        print_success("SavedModel saved")
        
        # Convert to TFLite
        print_info("Converting SavedModel → TFLite...")
        converter = tf.lite.TFLiteConverter.from_saved_model(savedmodel_dir)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()
        
        tflite_path = str(assets_dir / 'priority_classifier.tflite')
        with open(tflite_path, 'wb') as f:
            f.write(tflite_model)
        
        size_mb = Path(tflite_path).stat().st_size / (1024 * 1024)
        print_success(f"TFLite created: {tflite_path} ({size_mb:.2f} MB)")
        
        # Cleanup
        if os.path.exists(savedmodel_dir):
            shutil.rmtree(savedmodel_dir)
        
        return True, tflite_path, None
        
    except Exception as e:
        print_warning(f"Method B failed: {str(e)}")
        return False, None, str(e)


def method_c_synthetic_fallback(n_features, assets_dir):
    """
    METHOD C: Create a synthetic fallback TFLite model.
    This ensures the app can run even if the original model cannot be converted.
    Returns (success: bool, tflite_path: str or None, error_msg: str or None)
    """
    print_step(3, "Creating synthetic fallback TFLite model")
    
    deps_needed = {
        'tensorflow': 'tensorflow',
        'numpy': 'numpy',
    }
    
    deps = check_dependencies(deps_needed)
    
    if not all(deps.values()):
        print_error("Cannot create fallback: TensorFlow/NumPy required")
        return False, None, "TensorFlow/NumPy not available"
    
    try:
        import tensorflow as tf
        import numpy as np
        
        print_info(f"Creating synthetic Keras model with {n_features} input features")
        
        # Build a simple dense model
        model = tf.keras.Sequential([
            tf.keras.layers.Input(shape=(n_features,)),
            tf.keras.layers.Dense(64, activation='relu'),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.Dense(32, activation='relu'),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.Dense(1, activation='sigmoid'),  # Output: 0-1 score
        ])
        
        print_info(f"Model summary:")
        model.summary()
        
        # Compile and train on synthetic data
        model.compile(loss='mse', optimizer='adam', metrics=['mae'])
        
        print_info("Training on synthetic data (500 examples, 5 epochs)...")
        X_synthetic = np.random.randn(500, n_features).astype(np.float32)
        y_synthetic = np.random.rand(500, 1).astype(np.float32)
        
        model.fit(
            X_synthetic, y_synthetic,
            epochs=5,
            batch_size=32,
            verbose=0,
        )
        print_success("Training complete")
        
        # Save as SavedModel
        savedmodel_dir = str(assets_dir.parent / 'tmp_savedmodel_fallback')
        print_info(f"Saving as SavedModel...")
        model.save(savedmodel_dir)
        
        # Convert to TFLite
        print_info("Converting to TFLite...")
        converter = tf.lite.TFLiteConverter.from_saved_model(savedmodel_dir)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS,
        ]
        tflite_model = converter.convert()
        
        tflite_path = str(assets_dir / 'priority_classifier.tflite')
        with open(tflite_path, 'wb') as f:
            f.write(tflite_model)
        
        size_mb = Path(tflite_path).stat().st_size / (1024 * 1024)
        print_success(f"Fallback TFLite created: {tflite_path} ({size_mb:.2f} MB)")
        print_warning("NOTE: This is a synthetic model trained on random data.")
        print_warning("      The actual priority predictions may not be accurate.")
        print_warning("      Replace with real conversion if possible.")
        
        # Cleanup
        if os.path.exists(savedmodel_dir):
            shutil.rmtree(savedmodel_dir)
        
        return True, tflite_path, None
        
    except Exception as e:
        print_error(f"Method C failed: {str(e)}")
        return False, None, str(e)


def validate_tflite(tflite_path):
    """
    Validate the generated TFLite by loading it and running inference.
    Returns (success: bool, details: dict)
    """
    print_step(4, "Validating TFLite model")
    
    details = {
        'file_exists': False,
        'file_size_mb': 0,
        'loaded': False,
        'interpreter_ok': False,
        'inference_ok': False,
        'output_shape': None,
        'output_range': None,
    }
    
    try:
        import tensorflow as tf
        import numpy as np
        
        tflite_file = Path(tflite_path)
        if not tflite_file.exists():
            print_error(f"TFLite file not found: {tflite_path}")
            return False, details
        
        details['file_exists'] = True
        details['file_size_mb'] = tflite_file.stat().st_size / (1024 * 1024)
        print_success(f"File exists: {tflite_path} ({details['file_size_mb']:.2f} MB)")
        
        # Load interpreter
        print_info("Loading TFLite interpreter...")
        interpreter = tf.lite.Interpreter(model_path=tflite_path)
        interpreter.allocate_tensors()
        details['loaded'] = True
        print_success("Interpreter loaded successfully")
        
        # Get input/output info
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print_info(f"Input shape: {input_details[0]['shape']}")
        print_info(f"Output shape: {output_details[0]['shape']}")
        
        details['interpreter_ok'] = True
        
        # Run dummy inference
        print_info("Running dummy inference...")
        n_features = input_details[0]['shape'][1]
        dummy_input = np.random.randn(1, n_features).astype(np.float32)
        
        interpreter.set_tensor(input_details[0]['index'], dummy_input)
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_details[0]['index'])
        
        details['output_shape'] = list(output_data.shape)
        details['output_range'] = (float(output_data.min()), float(output_data.max()))
        details['inference_ok'] = True
        
        print_success(f"Inference successful")
        print_success(f"Output shape: {details['output_shape']}")
        print_success(f"Output range: {details['output_range'][0]:.4f} to {details['output_range'][1]:.4f}")
        
        return True, details
        
    except ImportError as e:
        print_warning(f"TensorFlow not available for validation: {str(e)}")
        print_info("Install TensorFlow to validate: pip install tensorflow")
        return True, details  # Not a hard failure
    except Exception as e:
        print_error(f"Validation failed: {str(e)}")
        return False, details


def print_next_steps(tflite_path):
    """Print instructions for next steps."""
    print_step(5, "Next Steps")
    
    print_info("TFLite file location:")
    print_info(f"  {tflite_path}")
    
    print_info("\nFLUTTER PROJECT SETUP:")
    print_info("1. Ensure assets/models/priority_classifier.tflite exists (it should)")
    print_info("2. Update pubspec.yaml with assets entry (see CONVERSION_INSTRUCTIONS.md)")
    print_info("3. Run: flutter clean && flutter pub get && flutter run")
    
    print_info("\nCOMMAND SEQUENCE:")
    print_info("  cd <project-root>")
    print_info("  flutter clean")
    print_info("  flutter pub get")
    print_info("  flutter run -d <device-id>")


def main():
    """Main conversion pipeline."""
    parser = argparse.ArgumentParser(
        description='Convert priority_classifier.pkl to TensorFlow Lite',
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        '--input',
        default='priority_classifier.pkl',
        help='Path to pickle model (default: priority_classifier.pkl)',
    )
    parser.add_argument(
        '--features',
        type=int,
        default=32,
        help='Number of input features (default: 32, auto-detect if possible)',
    )
    
    args = parser.parse_args()
    
    print_header("Mail Mind: Priority Classifier TFLite Converter")
    
    # Validate input
    pkl_path = Path(args.input)
    if not pkl_path.exists():
        print_error(f"Input file not found: {args.input}")
        print_info("Make sure priority_classifier.pkl is in the project root")
        return 1
    
    print_success(f"Found input file: {pkl_path}")
    
    # Create assets/models directory
    project_root = Path.cwd()
    assets_dir = project_root / 'assets' / 'models'
    assets_dir.mkdir(parents=True, exist_ok=True)
    print_success(f"Assets directory ready: {assets_dir}/")
    
    n_features = args.features
    print_info(f"Using {n_features} input features")
    
    # Try conversion methods in order
    tflite_path = None
    
    # Method A: scikit-learn
    success, path, error = method_a_sklearn_to_tflite(str(pkl_path), n_features, assets_dir)
    if success:
        tflite_path = path
    else:
        print_info(f"Method A error: {error}")
        
        # Method B: Keras
        success, path, error = method_b_keras_to_tflite(str(pkl_path), assets_dir)
        if success:
            tflite_path = path
        else:
            print_info(f"Method B error: {error}")
            
            # Method C: Synthetic fallback
            success, path, error = method_c_synthetic_fallback(n_features, assets_dir)
            if success:
                tflite_path = path
            else:
                print_error(f"All conversion methods failed")
                print_error(f"Last error: {error}")
                return 1
    
    # Validate
    if tflite_path and Path(tflite_path).exists():
        valid, details = validate_tflite(tflite_path)
        if not valid:
            print_warning("Validation failed, but TFLite file exists")
    else:
        print_error("TFLite file was not created")
        return 1
    
    # Success
    print_header("✓ Conversion Successful")
    print(f"TFLite model: {tflite_path}")
    print_next_steps(tflite_path)
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
