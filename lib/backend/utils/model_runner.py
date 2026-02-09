import tensorflow as tf
import numpy as np
from PIL import Image
import os
from tensorflow.keras import layers, models

# Define paths
path = os.path.dirname(os.path.realpath(__file__))
ISSUE_NON_ISSUE_PATH2 = "issue_detector1_finetuned.keras"
CLASS_MODEL_PATH = "gar_pot1_finetuned.keras"

filepath_issue = os.path.join(path, "models", ISSUE_NON_ISSUE_PATH2)
filepath_class = os.path.join(path, "models", CLASS_MODEL_PATH)

def build_model_for_loading(num_classes):
    """
    Reconstructs the EXACT architecture used in training to 
    bypass Sequential loading bugs.
    """
    base_model = tf.keras.applications.EfficientNetV2B0(
        input_shape=(224, 224, 3),
        include_top=False,
        weights=None # We will load your custom weights
    )
    
    # We use the Functional API here as it's more stable for loading
    inputs = layers.Input(shape=(224, 224, 3))
    x = base_model(inputs, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.3)(x)
    
    activation = 'sigmoid' if num_classes == 1 else 'softmax'
    outputs = layers.Dense(num_classes, activation=activation)(x)
    
    return models.Model(inputs, outputs)

# --- LOAD MODELS MANUALLY ---
print("Loading Issue Model...")
issue_model = build_model_for_loading(num_classes=1)
issue_model.load_weights(filepath_issue)

print("Loading Classification Model...")
class_model = build_model_for_loading(num_classes=2)
class_model.load_weights(filepath_class)

# This must match your training class_names=['Garbage', 'Potholes']
CLASSES_TO_USE = ['Garbage', 'Potholes']

def preprocess_image(image: Image.Image):
    """Matches the preprocessing used in training: 224x224 and 1/255 scaling."""
    img = image.resize((224, 224))
    img_array = tf.keras.utils.img_to_array(img)
    img_array = img_array / 255.0  # Training used 1./255 scaling
    img_array = np.expand_dims(img_array, axis=0)
    return img_array

def run_inference(image: Image.Image):
    # 1. Preprocess
    processed_img = preprocess_image(image)

    # 2. Model 1: Issue vs NoIssue
    # Training labels: ['Issues', 'NoIssue'] -> Issues=0, NoIssue=1
    issue_pred = issue_model.predict(processed_img)[0][0]
    print(f"DEBUG: Isuue Prediction: {issue_pred}")
    
    # If the probability is closer to 0, it's an "Issue"
    if issue_pred < 0.5:
        # 3. Model 2: Garbage vs Potholes
        # Training labels: ['Garbage', 'Potholes'] -> Garbage=0, Potholes=1
        type_preds = class_model.predict(processed_img)[0]
        print(f"DEBUG: Raw model output: {type_preds}") 
        print(f"DEBUG: Argmax index: {np.argmax(type_preds)}")
        class_idx = np.argmax(type_preds)
        # DEBUG PRINTS - Keep these until you are sure of the order
        print(f"--- INFERENCE DEBUG ---")
        print(f"Issue Confidence (0=Issue, 1=No): {issue_pred:.4f}")
        print(f"Class Probabilities: Garbage: {type_preds[0]:.4f}, Potholes: {type_preds[1]:.4f}")
        predicted_class = CLASSES_TO_USE[class_idx]
        confidence = float(np.max(type_preds))
    else:
        predicted_class = "No Issue"
        confidence = float(issue_pred)

    return image, confidence, predicted_class