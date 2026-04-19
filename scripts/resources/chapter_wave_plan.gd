class_name ChapterWavePlan
extends Resource

## 章节 -> 波次序列映射资源，避免把流程配置硬编码在 WaveManager 中。

@export var chapter_1: PackedInt32Array = PackedInt32Array([1, 2])
@export var chapter_2: PackedInt32Array = PackedInt32Array([3, 4])
@export var chapter_3: PackedInt32Array = PackedInt32Array([5])


func get_sequence(chapter: int) -> Array[int]:
	match chapter:
		1:
			return _packed_to_array(chapter_1)
		2:
			return _packed_to_array(chapter_2)
		3:
			return _packed_to_array(chapter_3)
		_:
			return _packed_to_array(chapter_3)


func _packed_to_array(source: PackedInt32Array) -> Array[int]:
	var result: Array[int] = []
	for value in source:
		result.append(value)
	return result
