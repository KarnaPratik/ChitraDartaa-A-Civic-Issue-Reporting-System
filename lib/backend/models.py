from extension import db
from datetime import datetime

class IssueReport(db.Model):
    __tablename__ = "issue_reports"

    issue_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), nullable=False)
    location = db.Column(db.JSON, nullable=False)
    segmented_image = db.Column(db.Text, nullable=False)  # base64
    confidence_score = db.Column(db.Float, nullable=False)

    status =db.Column(db.String(20), default = "reported")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    filepath = db.Column(db.String(200), nullable = False)
    label = db.Column(db.String(200), nullable = False)
