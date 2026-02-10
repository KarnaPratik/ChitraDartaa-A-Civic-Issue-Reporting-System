import tensorflow as tf
import numpy as np
from PIL import Image
import os
from ultralytics import YOLO
from tensorflow.keras import layers, models
import cv2

# path defining
path = os.path.dirname(os.path.realpath(__file__))

ISSUE_NON_ISSUE_PATH1 = "3rdmodelwithbetternoissueaccuracy.keras" #mahesh
ISSUE_NON_ISSUE_PATH2 = "issue_detector1_finetuned.keras" #finetuneAadim

CLASS_MODEL_PATH1 = "gar_pot1_finetuned.keras"#finetuneAadim
CLASS_MODEL_PATH2 = "pothole_garbage_classifier_final.h5"#Pratik

SEG_MODEL_PATH_POTHOLES = "best_for_potholes.pt"#abhyu
SEG_MODEL_PATH_GARBAGE = "best_for_garbage.pt"#abhyu

filepath_issue1= os.path.join(path, "models", ISSUE_NON_ISSUE_PATH1)
filepath_issue2 = os.path.join(path, "models", ISSUE_NON_ISSUE_PATH2)
filepath_class1 = os.path.join(path, "models", CLASS_MODEL_PATH1)
filepath_class2 = os.path.join(path, "models", CLASS_MODEL_PATH2)

seg_model_potholes = YOLO(os.path.join(path, "models", SEG_MODEL_PATH_POTHOLES))
seg_model_garbage = YOLO(os.path.join(path, "models", SEG_MODEL_PATH_GARBAGE))

#manual loading
print("Loading Issue Model...")
issue_model1 = tf.keras.models.load_model(filepath_issue1)

issue_model2 = tf.keras.models.load_model(filepath_issue2)

print("Loading Classification Model...")
class_model1 = tf.keras.models.load_model(filepath_class1)

class_model2 = tf.keras.models.load_model(filepath_class2)

CLASSES_TO_USE = ['Garbage', 'Potholes']

def preprocess_image(image: Image.Image):
    
    img = image.resize((224, 224))
    img_array = tf.keras.utils.img_to_array(img)
    img_array = img_array / 255.0  # training used 1./255 scaling
    img_array = np.expand_dims(img_array, axis=0)
    return img_array

def yolo_to_pil(annotated_frame: np.ndarray) -> Image.Image:
    # Ensure it's uint8
    if annotated_frame.dtype != np.uint8:
        annotated_frame = (np.clip(annotated_frame, 0.0, 1.0) * 255).astype(np.uint8)

    # YOLO usually returns BGR, convert to RGB
    pil_image = Image.fromarray(cv2.cvtColor(annotated_frame, cv2.COLOR_BGR2RGB))
    return pil_image



def run_inference(image: Image.Image):
    #preprocess
    processed_img = preprocess_image(image)

    #weightage to models for issueNoIssue
    w_issue1 = 0.3
    w_issue2 = 0.7

    # Training labels: ['Issues', 'NoIssue'] : Issues=0, NoIssue=1
    issue_pred1 = issue_model1.predict(processed_img)[0][0]
    issue_pred2 = issue_model2.predict(processed_img)[0][0]
    final_issue_pred = (w_issue1 * issue_pred1) + (issue_pred2* w_issue2)
    
    print(f"DEBUG: Issue Models | m1: {issue_pred1:.4f} | m2: {issue_pred2:.4f} | Weighted: {final_issue_pred:.4f}")
    
    # If the prediction is closer to 0, it's an "Issue"
    if final_issue_pred < 0.7:

        w_class1 = 0.4
        w_class2 = 0.6

        class_pred1 = class_model1.predict(processed_img)[0]
        class_pred2 = class_model2.predict(processed_img)[0]

        print( f"DEBUG: Class Models | " f"M1 -> Garbage: {class_pred1[0]:.4f}, Potholes: {class_pred1[1]:.4f} | " f"M2 -> Garbage: {class_pred2[0]:.4f}, Potholes: {class_pred2[1]:.4f}")

        # training labels: ['Garbage', 'Potholes'] : Garbage=0, Potholes=1
        final_class_pred = (w_class1* class_pred1) + (w_class2* class_pred2)


        class_idx = np.argmax(final_class_pred)

        predicted_class = CLASSES_TO_USE[class_idx]
        confidence = float(np.max(final_class_pred))

        print(f"DEBUG: Class Models | Final vector: {final_class_pred}")
        print(f"Class Probabilities: Garbage: {final_class_pred[0]:.4f}, Potholes: {final_class_pred[1]:.4f}")

        print(f"Detected {predicted_class}. Running segmentation...")
        open_cv_image = np.array(image)
        open_cv_image = open_cv_image[:, :, ::-1].copy() 

        if predicted_class == 'Potholes':
            results = seg_model_potholes.predict(source=open_cv_image, conf=0.25)
        else:
            results = seg_model_garbage.predict(source=open_cv_image, conf=0.25)


        annotated_frame = results[0].plot() 
        
        annotated_frame = results[0].plot()
        image = yolo_to_pil(annotated_frame)
        cv2.imshow("Segmentation Result", annotated_frame)
        cv2.waitKey(1)
    else:
        predicted_class = "No Issue"
        confidence = float(final_issue_pred)

    return image, confidence, predicted_class