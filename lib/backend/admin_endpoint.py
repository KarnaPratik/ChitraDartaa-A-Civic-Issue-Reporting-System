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
            "id": report.id,
            "username": report.username,
            "location": report.location,
            "confidence_score": report.confidence_score,
            "is_resolved": report.is_resolved,
            "segmented_image": report.segmented_image,
            "created_at": report.created_at.isoformat()
        })

    return jsonify({
        "count": len(data),
        "reports": data
    }), 200
