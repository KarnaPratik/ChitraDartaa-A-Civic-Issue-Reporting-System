from flask import Blueprint, jsonify, request
from models import IssueReport
from extension import db

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
        data.append({
            "id": report.issue_id,
            "title": f"Issue reported by {report.username}",
            "description": "AI detected issue", #could be better, nvm
            "reporter": report.username,
            "location": report.location,
            "status": report.status, 
            "confidence_score": report.confidence_score,
            "segmented_image": report.segmented_image,
            "timestamp": report.created_at.isoformat()
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