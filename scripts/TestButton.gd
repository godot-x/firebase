class_name TestButton
extends Button

enum Status {
	IDLE,
	PENDING,
	SUCCESS,
	FAILURE
}

@export var reset_time: float = 3.0
var _timer: SceneTreeTimer = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	update_status(Status.IDLE)

func update_status(status: int) -> void:
	match status:
		Status.IDLE:
			self_modulate = Color.WHITE
		Status.PENDING:
			self_modulate = Color.YELLOW
		Status.SUCCESS:
			self_modulate = Color.GREEN
		Status.FAILURE:
			self_modulate = Color.RED
			_start_reset_timer()

func _start_reset_timer() -> void:
	if _timer:
		_timer = null # Cancel previous timer by letting it die

	_timer = get_tree().create_timer(reset_time)
	_timer.timeout.connect(func(): update_status(Status.IDLE))
