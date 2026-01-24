from flask import Blueprint, request, jsonify
from extension import db
from models import IssueReport
from utils.image_utils import base64_to_image, image_to_base64
from utils.model_runner import run_inference
import os
import time
from auth import token_required
from datetime import datetime
from werkzeug.utils import secure_filename

inference_bp = Blueprint("inference", __name__, url_prefix="/api/infer")

UPLOAD_FOLDER = "uploaded_images"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@inference_bp.route("", methods=["POST"])
@token_required
def infer_image():
    data = request.get_json()

    if not data:
        return jsonify({"error": "No JSON received"}), 400

    try:
        username = data["username"] #try request.user.username once
        location_data = data["location"]
        image_base64 = data["image"]

        # Handle different possible location formats from frontend
        if isinstance(location_data, dict):
            # If it's already a dict, ensure it has lat/lng keys
            if 'lat' in location_data and 'lng' in location_data:
                location = {
                    'lat': float(location_data['lat']),
                    'lng': float(location_data['lng'])
                }
            elif 'latitude' in location_data and 'longitude' in location_data:
                location = {
                    'lat': float(location_data['latitude']),
                    'lng': float(location_data['longitude'])
                }
            else:
                return jsonify({"error": "Location must contain lat/lng or latitude/longitude"}), 400
        else:
            return jsonify({"error": "Location must be an object with lat and lng"}), 400


        #  Convert base64 → image
        image = base64_to_image(image_base64)


        #  Run AI inference
        segmented_img, confidence, label = run_inference(image)
        confidence=float(confidence)
        #  Convert segmented image → base64 (for DB + frontend)
        segmented_base64 = image_to_base64(segmented_img)
        os.makedirs(UPLOAD_FOLDER, exist_ok=True)
        # Save segmented image locally
        timestamp_int = int(time.time())
        timestamp = datetime.fromtimestamp(timestamp_int)
        timestamp_str = datetime.utcnow().strftime("%Y%m%d_%H%M%S")   # e.g. 20260123_183614
        safe_username = secure_filename(str(username)) or "user" 
        filename = f"{safe_username}_{timestamp_str}.png"
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        segmented_img.save(filepath)

        # Store in DB
        report = IssueReport(
            username=username,
            location=location,
            segmented_image=segmented_base64,
            confidence_score=confidence,
            label = label,
            # is_resolved=False,
            filepath = filepath,
            created_at=timestamp
        )
        print("report made")
        db.session.add(report)
        db.session.commit()
        print("db added")
        # Return JSON
        return jsonify({
            "message": "Inference successful",
            "label": label,
            "segmented_image": segmented_base64,
            "confidence_score": confidence,
            "report_id": report.issue_id,
            "saved_file": filepath
        }), 200

    except KeyError as e:
        return jsonify({"error": f"Missing field {str(e)}"}), 400
    except Exception as e:
        import traceback
        traceback.print_exc()
        db.session.rollback()
        return jsonify({"error": str(e)}), 500
