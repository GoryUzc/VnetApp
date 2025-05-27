from flask import Blueprint, jsonify, request
from marshmallow import ValidationError
from services.contrators_service import (
    create_contrators, get_all_contrators, update_contrators, delete_contrators, update_installation
)