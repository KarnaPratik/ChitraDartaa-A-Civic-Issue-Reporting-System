from flask import Blueprint, jsonify, request
from models import IssueReport
from extension import db
import json
admin_bp = Blueprint("admin", __name__, url_prefix="/api/admin")


@admin_bp.route("/reports", methods=["GET"])
def get_reports():
    resolved = request.args.get("resolved")

    if resolved is not None:
        resolved = resolved.lower() == "true"
        reports = IssueReport.query.filter_by(is_resolved=resolved).all()
    else:
        reports = IssueReport.query.all()

    data = []
    for report in reports:
        loc_raw = report.location or "{}" 
        
        # 2. Parse it into a Dictionary safely
        try:
            if isinstance(loc_raw, str):
                loc_dict = json.loads(loc_raw)
            else:
                loc_dict = loc_raw # in case it's already a dict
        except (TypeError, json.JSONDecodeError):
            loc_dict = {}

        # 3. Extract lat/lng from the DICTIONARY
        lat = loc_dict.get("lat")
        lng = loc_dict.get("lng")

        # 4. Force to float for Flutter's sake
        try:
            lat = float(lat) if lat is not None else 0.0
            lng = float(lng) if lng is not None else 0.0
        except (TypeError, ValueError):
            lat = 0.0
            lng = 0.0

        data.append({
            "id": report.issue_id,
            "title": f"Issue reported by {report.username}",
            "description": "AI detected issue", #could be better, nvm
            "reporter": report.username,
            "location": {"lat": lat, "lng": lng},
            "status": report.status, 
            "confidence_score": report.confidence_score,
            "segmented_image": report.segmented_image,
            "timestamp": report.created_at.isoformat(),
            "label": report.label,
        })

    return jsonify({
        "reports": data
    }), 200

#To update db after updating in frontend
@admin_bp.route("/reports/<int:report_id>", methods=["PATCH"])
def update_report(report_id):
    report = IssueReport.query.get_or_404(report_id)
    
    data = request.get_json()
    
    if "status" in data:
        report.status = data["status"]
    
    
    db.session.commit()
    
    return jsonify({"message": "Report updated successfully"}), 200