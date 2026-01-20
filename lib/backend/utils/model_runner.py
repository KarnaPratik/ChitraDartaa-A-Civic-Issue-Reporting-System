import tensorflow as tf
import numpy as np
from PIL import Image
import os



# Load your models once

ISSUE_NON_ISSUE_PATH1 = "issue_non_issue_model1_20split_96.07accuracy.keras"
ISSUE_NON_ISSUE_PATH2 = "issue_non_issue_model2_40split_96.76accuracy.keras"
CLASS_MODEL_PATH = "pothole_garbage_classifier.h5"
# SEG_MODEL_PATH = "segmentation_model.h5"

path = os.path.dirname(os.path.realpath(__file__))
filepath1 = os.path.join(path,"models",ISSUE_NON_ISSUE_PATH1)
filepath2 = os.path.join(path,"models",ISSUE_NON_ISSUE_PATH2)
filepath3 = os.path.join(path,"models",CLASS_MODEL_PATH)


issue_model1 = tf.keras.models.load_model(filepath1)
issue_model2 = tf.keras.models.load_model(filepath2)
class_model = tf.keras.models.load_model(filepath3)
# seg_model = tf.keras.models.load_model(SEG_MODEL_PATH)



# # Preprocessing functions
# def preprocess_class(image: Image.Image):
#     # Resize and normalize as your model expects
#     img = image.resize((224, 224))
#     arr = np.array(img) / 255.0
#     if arr.ndim == 2:  # grayscale → RGB
#         arr = np.stack([arr]*3, axis=-1)
#     arr = np.expand_dims(arr, 0)  # batch dimension
#     return arr

# def preprocess_seg(image: Image.Image):
#     img = image.resize((256, 256)) 
#     arr = np.array(img) / 255.0
#     if arr.ndim == 2:  # grayscale → RGB
#         arr = np.stack([arr]*3, axis=-1)
#     arr = np.expand_dims(arr, 0)  # batch dimension
#     return arr

def predict_for_single_image(model, img_input):
    if isinstance(img_input, str):#this is for when we send image from dir
        img = tf.keras.utils.load_img(img_input, target_size=(224, 224))
    else:
        img = img_input.resize((224, 224))#this is for when we send the image directly
    img_array=tf.keras.utils.img_to_array(img)
    img_array=np.expand_dims(img_array, axis=0)
    prediction=model.predict(img_array)
    probability=prediction[0][0]

    return probability

def run_inference(image: Image.Image):
    """
    image: PIL Image
    returns:
        segmented_image: PIL Image
        confidence_score: float (from classification model)
    """
    #Issue or non issue classify


    conf1 = predict_for_single_image(model = issue_model1,img_input= image)
    conf2 = predict_for_single_image(model = issue_model1,img_input= image)
    combined_agreement=(2*conf1*conf2)/(conf1+conf2)
    if combined_agreement:
        label="Natural Road"
    else:
        ...
        #pratik mula tmro model yeta run garnu
    #pothole or garbage classify
    # class_input = preprocess_class(image)
    class_pred = class_model.predict(image)
    combined_agreement = float(np.max(class_pred))
    predicted_class = int(np.argmax(class_pred))

    #Segmented image block
    # seg_input = preprocess_seg(image)

    # seg_pred = seg_model.predict(image)  # shape = (1,H,W,num_classes) or (1,H,W,1)
    
    # # Convert seg_pred to mask
    # seg_mask = np.argmax(seg_pred[0], axis=-1).astype(np.uint8) * 255  # shape (H,W)
    # segmented_image = Image.fromarray(seg_mask)


    # return segmented_image, confidence_score

    return image, combined_agreement

