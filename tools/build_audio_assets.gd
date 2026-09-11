extends SceneTree
## Original layered synthesis. Replace with licensed recordings at the resource hooks.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _initialize() -> void:
	rng.seed = 47192
	DirAccess.make_dir_recursive_absolute("res://assets/audio/designed")
	for cue: String in ["m1911", "p38", "thompson", "mp40", "stg44", "bazooka", "panzerfaust", "mg42", "m1919", "reload", "dry", "impact_dirt", "impact_wood", "impact_concrete", "impact_metal", "footstep_dirt", "footstep_wood", "footstep_concrete", "footstep_metal", "explosion", "wind", "birds", "distant_artillery", "distant_fire", "bunker"]:
		_make(cue)
	for cue: String in ["canopy", "gust", "radio_bed", "radio_signal", "hit_flesh", "hit_gear"]: _make(cue)
	print("Built original layered sound palette")
	quit()

func _make(cue: String) -> void:
	var loop: bool = cue in ["wind", "birds", "bunker", "canopy", "gust", "radio_bed"]
	var length: float = 12.0 if loop else (3.5 if cue in ["explosion", "distant_artillery"] else 0.75)
	if cue == "reload": length = 1.3
	var rate: int = 22050
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(int(length * rate) * 2)
	var low: float = 0.0
	var mid: float = 0.0
	var pitch: float = 95.0 + float(cue.hash() % 100)
	for i: int in range(bytes.size() / 2):
		var t: float = float(i) / rate
		var noise: float = rng.randf_range(-1, 1)
		low = lerpf(low, noise, 0.015)
		mid = lerpf(mid, noise, 0.23)
		var value: float = 0.0
		if cue in ["wind", "canopy", "gust"]:
			value = low * 2.6 * (0.65 + sin(t * TAU / length) * 0.3) + mid * 0.09
			if cue == "canopy": value = mid * 0.23 + low * 0.5
			if cue == "gust": value = low * (1.3 + sin(t * 0.8) * 0.6)
		elif cue == "radio_bed":
			value = mid * 0.065 + low * 0.2 + sin(t * TAU * 50) * 0.03
		elif cue == "radio_signal":
			var slot: int = int(t / 0.075)
			var on: bool = slot in [0, 2, 3, 4, 6, 8]
			var envelope: float = minf(fmod(t, 0.075) * 500, 1) * minf((0.075 - fmod(t, 0.075)) * 500, 1)
			value = sin(t * TAU * 690) * 0.16 * envelope if on else mid * 0.03
		elif cue in ["hit_flesh", "hit_gear"]:
			value = (low * 3 + sin(t * TAU * 95) * 0.3) * exp(-t * 32) + mid * 0.3 * exp(-t * 45)
			if cue == "hit_gear": value += sin(t * 3700) * 0.09 * exp(-t * 36)
		elif cue == "birds":
			var pulse: float = fmod(t, 3.0)
			value = sin(TAU * (2200 * t + sin(t * 17) * 12)) * maxf(0, 1.0 - pulse * 3.0) * 0.13
		elif cue == "bunker":
			value = sin(TAU * 50 * t) * 0.055 + sin(TAU * 100 * t) * 0.025 + low * 0.4
		elif cue in ["explosion", "distant_artillery"]:
			value = (low * 6.0 + mid * 0.5 + sin(t * 240 * exp(-t * 0.8)) * 0.12) * exp(-t * 1.8)
			value += noise * 0.4 * exp(-t * 45)
			if cue == "explosion":
				value += low * 2.0 * (1 - exp(-t * 12)) * exp(-t * 1.2)
				for impact: float in [0.18, 0.31, 0.52, 0.8]:
					if t > impact: value += mid * 0.23 * exp(-(t - impact) * 42)
		elif cue == "reload":
			for at: float in [0.02, 0.36, 0.82, 1.05]:
				if t >= at:
					value += (mid * 0.8 + sin(t * 4500) * 0.1) * exp(-(t - at) * 65)
		elif cue.begins_with("footstep"):
			# Soft heel contact and a delayed sole scuff, without a firearm-like crack.
			var attack: float = smoothstep(0.0, 0.035, t)
			var grit: float = 0.12 if cue.ends_with("dirt") else 0.045
			value = (low * 0.7 + sin(TAU * 85 * t) * 0.08) * attack * exp(-t * 18)
			if t > 0.06:
				value += mid * grit * smoothstep(0.06, 0.10, t) * exp(-(t - 0.06) * 16)
			if cue.ends_with("metal"): value += sin(TAU * 260 * t) * 0.025 * attack * exp(-t * 25)
		elif cue.begins_with("impact") or cue == "dry":
			value = mid * exp(-t * 36) * 0.7
			if cue.ends_with("metal") or cue == "dry": value += (sin(t * 7400) + sin(t * 5100)) * exp(-t * 24) * 0.18
			if cue.ends_with("wood"): value += sin(t * 800) * exp(-t * 45) * 0.3
		else:
			value = noise * exp(-t * 140) * 0.8 + low * exp(-t * 12) * 3.5 + mid * exp(-t * 16) * 0.5
			value += sin(TAU * pitch * t * exp(-t * 6)) * exp(-t * 28) * 0.35
			if t > 0.07: value += mid * exp(-(t - 0.07) * 25) * 0.13
			if t > 0.12: value += noise * exp(-(t - 0.12) * 100) * 0.08
		# Fade loop joins and tails to avoid discontinuities/clicks.
		if not loop: value *= minf(t * 3000, 1.0) * minf((length - t) * 30, 1.0)
		bytes.encode_s16(i * 2, int(clampf(value, -0.95, 0.95) * 30000))
	if loop:
		# Overlap-add the tail into the opening, then remove the duplicated tail.
		# Neither side of the actual loop boundary fades to silence.
		var join: int = rate / 2
		var end: int = bytes.size() / 2 - join
		for i: int in range(join):
			bytes.encode_s16(i * 2, int(lerpf(bytes.decode_s16((end + i) * 2), bytes.decode_s16(i * 2), float(i) / join)))
		bytes.resize(end * 2)
	var wave: AudioStreamWAV = AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = rate
	wave.data = bytes
	if loop:
		wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wave.loop_end = bytes.size() / 2
	ResourceSaver.save(wave, "res://assets/audio/designed/" + cue + ".res")
