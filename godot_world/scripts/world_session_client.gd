extends Node
## Secure in-memory bridge between the Android host and the verified Supabase session.
## The native host supplies only the short-lived access token. Refresh tokens stay in
## the existing app authentication layer and are never stored by this Godot node.

signal session_verified(member: Dictionary, permissions: Dictionary)
signal session_rejected(error_code: String)
signal session_cleared

@export var endpoint_url: String = "https://irwtnqekrwhgompulach.supabase.co/functions/v1/fc-world-session"
@export_range(3.0, 30.0, 1.0) var request_timeout_seconds: float = 10.0

var _http: HTTPRequest
var _request_pending: bool = false
var _current_member: Dictionary = {}
var _current_permissions: Dictionary = {}
var last_error_code: String = ""


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.name = "WorldSessionHTTPRequest"
	_http.timeout = request_timeout_seconds
	_http.use_threads = true
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

	# The Android host exposes a one-time access-token handoff. No refresh token
	# or privileged server key is made available to the Godot project.
	if Engine.has_singleton("FamilyColonyBridge"):
		var bridge: Object = Engine.get_singleton("FamilyColonyBridge")
		if bridge.has_method("consumeInitialAccessToken"):
			var initial_token := str(bridge.call("consumeInitialAccessToken"))
			var publishable_key := str(bridge.call("consumeInitialPublishableKey"))
			if initial_token.is_empty() or publishable_key.is_empty():
				_access_denied("native_session_credentials_missing")
			else:
				var request_error := verify_access_token(initial_token, publishable_key)
				if request_error != OK:
					push_warning("FAMILY COLONY: Could not start member session verification.")
		else:
			_access_denied("native_session_bridge_invalid")
	else:
		_access_denied("native_session_bridge_missing")


## Called by the future Android native bridge after the existing app login succeeds.
## Do not pass refresh tokens, service-role keys, member IDs, or role values here.
func verify_access_token(access_token: String, publishable_key: String) -> Error:
	var token := access_token.strip_edges()
	var api_key := publishable_key.strip_edges()
	if token.is_empty() or api_key.is_empty():
		return ERR_INVALID_PARAMETER
	if endpoint_url.strip_edges().is_empty():
		return ERR_UNCONFIGURED

	if _request_pending:
		_http.cancel_request()
	_request_pending = false
	_current_member.clear()
	_current_permissions.clear()
	last_error_code = ""

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + token,
		"apikey: " + api_key
	])
	var request_error := _http.request(
		endpoint_url,
		headers,
		HTTPClient.METHOD_POST,
		"{}"
	)
	if request_error != OK:
		_access_denied("session_request_could_not_start")
		return request_error

	_request_pending = true
	return OK


## Called by the Android host when the member logs out or leaves the world.
func clear_session() -> void:
	if _request_pending and is_instance_valid(_http):
		_http.cancel_request()
	_request_pending = false
	_current_member.clear()
	_current_permissions.clear()
	session_cleared.emit()


func has_native_bridge() -> bool:
	return Engine.has_singleton("FamilyColonyBridge")


func has_verified_session() -> bool:
	return not _current_member.is_empty() and bool(_current_permissions.get("can_enter_world", false))


func get_last_error_code() -> String:
	return last_error_code


func get_member_profile() -> Dictionary:
	return _current_member.duplicate(true)


func get_permission_snapshot() -> Dictionary:
	return _current_permissions.duplicate(true)


func _on_request_completed(
	result: int,
	response_code: int,
	_response_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if not _request_pending:
		return
	_request_pending = false

	if result != HTTPRequest.RESULT_SUCCESS:
		_access_denied("session_network_unavailable")
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_access_denied("session_response_invalid")
		return

	var payload: Dictionary = parsed
	if response_code != 200 or payload.get("ok") != true:
		_access_denied(str(payload.get("error", "session_verification_rejected")))
		return

	var member_value: Variant = payload.get("member", {})
	var permission_value: Variant = payload.get("permissions", {})
	if typeof(member_value) != TYPE_DICTIONARY or typeof(permission_value) != TYPE_DICTIONARY:
		_access_denied("session_identity_payload_invalid")
		return

	var member_data: Dictionary = member_value
	var permission_data: Dictionary = permission_value
	if str(member_data.get("member_id", "")).is_empty() or not bool(permission_data.get("can_enter_world", false)):
		_access_denied("session_world_access_denied")
		return

	last_error_code = ""
	_current_member = member_data.duplicate(true)
	_current_permissions = permission_data.duplicate(true)
	session_verified.emit(get_member_profile(), get_permission_snapshot())


func _access_denied(error_code: String) -> void:
	last_error_code = error_code
	_current_member.clear()
	_current_permissions.clear()
	session_rejected.emit(error_code)
