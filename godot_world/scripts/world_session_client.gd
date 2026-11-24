extends Node
## Secure in-memory bridge between the Android host and the verified Supabase session.
## The native host supplies only the short-lived access token. Refresh tokens stay in
## the existing app authentication layer and are never stored by this Godot node.

signal session_verified(member: Dictionary, permissions: Dictionary)
signal session_rejected(error_code: String)
signal session_cleared
signal matchmaking_ready(server: Dictionary, member: Dictionary)
signal matchmaking_failed(error_code: String)

@export var endpoint_url: String = "https://irwtnqekrwhgompulach.supabase.co/functions/v1/fc-world-session"
@export var matchmaking_endpoint_url: String = "https://irwtnqekrwhgompulach.supabase.co/functions/v1/fc-world-matchmaking"
@export var default_world_id: String = "colony-main"
@export_range(3.0, 30.0, 1.0) var request_timeout_seconds: float = 10.0

var _http: HTTPRequest
var _matchmaking_http: HTTPRequest
var _request_pending: bool = false
var _matchmaking_pending: bool = false
var _access_token: String = ""
var _publishable_key: String = ""
var _requested_world_id: String = ""
var _current_member: Dictionary = {}
var _current_permissions: Dictionary = {}
var last_error_code: String = ""
var _refresh_timer: Timer


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.name = "WorldSessionHTTPRequest"
	_http.timeout = request_timeout_seconds
	_http.use_threads = true
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	_matchmaking_http = HTTPRequest.new()
	_matchmaking_http.name = "WorldMatchmakingHTTPRequest"
	_matchmaking_http.timeout = request_timeout_seconds
	_matchmaking_http.use_threads = true
	add_child(_matchmaking_http)
	_matchmaking_http.request_completed.connect(_on_matchmaking_request_completed)

	# The Android host exposes a one-time access-token handoff. No refresh token
	# or privileged server key is made available to the Godot project.
	if Engine.has_singleton("FamilyColonyBridge"):
		var bridge: Object = Engine.get_singleton("FamilyColonyBridge")
		if bridge.has_signal("session_credentials_refreshed"):
			bridge.connect("session_credentials_refreshed", Callable(self, "_on_session_credentials_refreshed"))
		if bridge.has_signal("session_refresh_failed"):
			bridge.connect("session_refresh_failed", Callable(self, "_on_session_refresh_failed"))
		# Godot Android JNISingleton does not implement has_method() for
		# Java plugin methods. Call the @UsedByGodot methods directly.
		var initial_token := str(bridge.call("consumeInitialAccessToken"))
		var publishable_key := str(bridge.call("consumeInitialPublishableKey"))
		# This marker confirms the native singleton methods are callable.
		print("FC_NATIVE_BRIDGE_METHODS_OK")
		if initial_token.is_empty() or publishable_key.is_empty():
			push_error("FC_NATIVE_BRIDGE_CREDENTIALS_MISSING")
			_access_denied("native_session_credentials_missing")
		else:
			# Separate from method registration: prove the Activity extras reached Godot.
			print("FC_NATIVE_BRIDGE_CREDENTIALS_OK")
			var request_error := verify_access_token(initial_token, publishable_key)
			if request_error != OK:
				push_warning("FAMILY COLONY: Could not start member session verification.")
	else:
		_access_denied("native_session_bridge_missing")


## Called with the one-time Android handoff after the existing app login succeeds.
## Never pass refresh tokens, service-role keys, member IDs, or client-selected roles.
func verify_access_token(access_token: String, publishable_key: String) -> Error:
	var token := access_token.strip_edges()
	var api_key := publishable_key.strip_edges()
	if token.is_empty() or api_key.is_empty():
		return ERR_INVALID_PARAMETER
	if endpoint_url.strip_edges().is_empty():
		return ERR_UNCONFIGURED

	if _request_pending:
		_http.cancel_request()
	if _matchmaking_pending:
		_matchmaking_http.cancel_request()
	_request_pending = false
	_matchmaking_pending = false
	_access_token = token
	_publishable_key = api_key
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
	print("FC_WORLD_SESSION_REQUEST_STARTED")
	return OK


## Called by the Android host when the member logs out or leaves the world.
func clear_session() -> void:
	if is_instance_valid(_refresh_timer):
		_refresh_timer.stop()
	if _request_pending and is_instance_valid(_http):
		_http.cancel_request()
	if _matchmaking_pending and is_instance_valid(_matchmaking_http):
		_matchmaking_http.cancel_request()
	_request_pending = false
	_matchmaking_pending = false
	_access_token = ""
	_publishable_key = ""
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
		push_warning("FC_WORLD_SESSION_NETWORK_RESULT=" + str(result))
		_access_denied("session_network_unavailable")
		return

	# A response proves the request reached the configured Supabase endpoint.
	# The smoke test uses deliberately invalid credentials; 401 is expected there.
	print("FC_WORLD_SESSION_HTTP_RESPONSE_RECEIVED=" + str(response_code))
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_access_denied("session_response_invalid")
		return

	var payload: Dictionary = parsed
	if response_code != 200 or payload.get("ok") != true:
		var server_error := str(payload.get("error", "session_verification_rejected"))
		push_warning("FC_WORLD_SESSION_HTTP_RESPONSE=" + str(response_code) + " ERROR=" + server_error)
		_access_denied(server_error)
		return
	print("FC_WORLD_SESSION_VERIFIED")

	var member_value: Variant = payload.get("member", {})
	var permission_value: Variant = payload.get("permissions", {})
	if typeof(member_value) != TYPE_DICTIONARY or typeof(permission_value) != TYPE_DICTIONARY:
		_access_denied("session_identity_payload_invalid")
		return

	var member_data: Dictionary = member_value
	var permission_data: Dictionary = permission_value
	if not _is_valid_verified_identity(member_data, permission_data):
		_access_denied("session_world_access_denied")
		return

	last_error_code = ""
	_current_member = member_data.duplicate(true)
	_current_permissions = permission_data.duplicate(true)
	session_verified.emit(get_member_profile(), get_permission_snapshot())
	_start_refresh_timer()
	# Cloud matchmaking is best-effort until a healthy dedicated server is deployed.
	var matchmaking_error := request_world_matchmaking(default_world_id)
	if matchmaking_error != OK:
		push_warning("FAMILY COLONY: Could not start cloud matchmaking request.")


func _start_refresh_timer() -> void:
	if not is_instance_valid(_refresh_timer):
		_refresh_timer = Timer.new()
		_refresh_timer.name = "WorldSessionRefreshTimer"
		_refresh_timer.wait_time = 600.0
		_refresh_timer.one_shot = false
		_refresh_timer.timeout.connect(_request_session_refresh)
		add_child(_refresh_timer)
	_refresh_timer.start()


func _request_session_refresh() -> void:
	if not has_verified_session() or not Engine.has_singleton("FamilyColonyBridge"):
		return
	var bridge: Object = Engine.get_singleton("FamilyColonyBridge")
	# has_method() is unsupported for Android Java plugin methods.
	bridge.call("requestSessionRefresh")


func _on_session_credentials_refreshed(access_token: String, api_key: String) -> void:
	var request_error := verify_access_token(access_token, api_key)
	if request_error != OK:
		_access_denied("session_refresh_request_failed")



## Requests a cloud server with the already verified member session.
## The existing Supabase access token is the credential; no entrance ticket is used.
func request_world_matchmaking(world_id: String = "colony-main") -> Error:
	var requested_world := world_id.strip_edges()
	if not has_verified_session() or _access_token.is_empty() or _publishable_key.is_empty():
		return ERR_UNAUTHORIZED
	var world_id_pattern := RegEx.new()
	world_id_pattern.compile("^[A-Za-z0-9_-]{1,64}$")
	if world_id_pattern.search(requested_world) == null:
		return ERR_INVALID_PARAMETER
	if matchmaking_endpoint_url.strip_edges().is_empty():
		return ERR_UNCONFIGURED
	if _matchmaking_pending:
		_matchmaking_http.cancel_request()
		_matchmaking_pending = false
	_requested_world_id = requested_world
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + _access_token,
		"apikey: " + _publishable_key
	])
	var request_error := _matchmaking_http.request(
		matchmaking_endpoint_url,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify({"world_id": requested_world})
	)
	if request_error != OK:
		matchmaking_failed.emit("matchmaking_request_could_not_start")
		return request_error
	_matchmaking_pending = true
	print("FC_WORLD_MATCHMAKING_REQUEST_STARTED")
	return OK


func _on_matchmaking_request_completed(
	result: int,
	response_code: int,
	_response_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if not _matchmaking_pending:
		return
	_matchmaking_pending = false
	if result != HTTPRequest.RESULT_SUCCESS:
		matchmaking_failed.emit("matchmaking_network_unavailable")
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		matchmaking_failed.emit("matchmaking_response_invalid")
		return
	var payload: Dictionary = parsed
	if response_code != 200 or payload.get("ok") != true:
		var server_error := str(payload.get("error", "matchmaking_unavailable"))
		push_warning("FC_WORLD_MATCHMAKING_HTTP_RESPONSE=" + str(response_code) + " ERROR=" + server_error)
		matchmaking_failed.emit(server_error)
		return
	var server_value: Variant = payload.get("server", {})
	var member_value: Variant = payload.get("member", {})
	if typeof(server_value) != TYPE_DICTIONARY or typeof(member_value) != TYPE_DICTIONARY:
		matchmaking_failed.emit("matchmaking_payload_invalid")
		return
	var server_data: Dictionary = server_value
	var member_data: Dictionary = member_value
	if str(payload.get("access", "")) != "member_session" or str(payload.get("credential", "")) != "supabase_access_token":
		matchmaking_failed.emit("matchmaking_access_contract_invalid")
		return
	var server_id := str(server_data.get("server_id", "")).strip_edges()
	var response_world_id := str(server_data.get("world_id", "")).strip_edges()
	var server_endpoint := str(server_data.get("endpoint", "")).strip_edges()
	var server_id_pattern := RegEx.new()
	server_id_pattern.compile("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$")
	if server_id_pattern.search(server_id) == null or response_world_id != _requested_world_id or server_endpoint.is_empty() or server_endpoint.length() > 255:
		matchmaking_failed.emit("matchmaking_server_payload_invalid")
		return
	if str(member_data.get("member_id", "")) != str(_current_member.get("member_id", "")):
		matchmaking_failed.emit("matchmaking_identity_mismatch")
		return
	matchmaking_ready.emit(server_data.duplicate(true), member_data.duplicate(true))


func _on_session_refresh_failed(invalidated: bool) -> void:
	if invalidated:
		_access_denied("session_refresh_invalidated")
	else:
		push_warning("FAMILY COLONY: Session refresh is temporarily unavailable; it will retry.")


func _access_denied(error_code: String) -> void:
	if is_instance_valid(_refresh_timer):
		_refresh_timer.stop()
	last_error_code = error_code
	_access_token = ""
	_publishable_key = ""
	if _matchmaking_pending and is_instance_valid(_matchmaking_http):
		_matchmaking_http.cancel_request()
	_matchmaking_pending = false
	_current_member.clear()
	_current_permissions.clear()
	session_rejected.emit(error_code)


## Validate the canonical server response before unlocking the world.
## This is a client-side consistency check; protected actions must still be
## authorized by the backend at the time they are performed.
func _is_valid_verified_identity(member_data: Dictionary, permission_data: Dictionary) -> bool:
	var member_id := str(member_data.get("member_id", "")).strip_edges()
	var display_name := str(member_data.get("name", "")).strip_edges()
	var username := str(member_data.get("username", "")).strip_edges()
	var role := str(member_data.get("role", "")).strip_edges().to_lower()
	var status := str(member_data.get("status", "")).strip_edges().to_lower()
	var allowed_roles := ["kepsuk", "deputi", "admin", "member", "developer"]
	var active_statuses := ["aktif", "active"]

	if member_id.is_empty() or display_name.is_empty() or username.is_empty():
		return false
	if not allowed_roles.has(role) or not active_statuses.has(status):
		return false
	if permission_data.get("can_enter_world") != true:
		return false
	if str(permission_data.get("world_role", "")) != "member":
		return false
	return true
