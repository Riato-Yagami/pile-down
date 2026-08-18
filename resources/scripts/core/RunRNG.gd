class_name RunRNG
extends RefCounted

const STREAM_IDS: Array[StringName] = [
	&"difficulty", &"hands", &"bonuses", &"special_rules",
	&"movement", &"challenge", &"cosmetic",
]
const FNV_OFFSET_BASIS := 0x14650FB0739D0383
const FNV_PRIME := 0x100000001B3

var seed_value: int
var seed_label: String
var streams: Dictionary[StringName, RandomNumberGenerator] = {}


func initialize(value: int, label := "") -> void:
	seed_value = value
	seed_label = label if not label.is_empty() else str(value)
	streams.clear()
	for stream_id in STREAM_IDS:
		get_stream(stream_id)


func get_stream(stream_id: StringName) -> RandomNumberGenerator:
	if streams.has(stream_id):
		return streams[stream_id]
	var stream := RandomNumberGenerator.new()
	stream.seed = derive_stream_seed(seed_value, stream_id)
	streams[stream_id] = stream
	return stream


static func derive_stream_seed(main_seed: int, stream_id: StringName) -> int:
	return _fnv1a_64("%d\u001f%s" % [main_seed, String(stream_id)])


static func seed_string_to_int(text: String) -> int:
	var normalized := text.strip_edges()
	if normalized.is_valid_int():
		return normalized.to_int()
	return _fnv1a_64(normalized)


static func generate_run_seed() -> int:
	var bytes := Crypto.new().generate_random_bytes(8)
	var result := 0
	for byte in bytes:
		result = (result << 8) | int(byte)
	return result


static func _fnv1a_64(text: String) -> int:
	var result := FNV_OFFSET_BASIS
	for byte in text.to_utf8_buffer():
		result = (result ^ int(byte)) * FNV_PRIME
	return result
