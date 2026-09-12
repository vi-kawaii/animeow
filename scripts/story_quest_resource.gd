extends Quest  # Наследуемся от базового класса плагина QuestSystem!
class_name StoryQuest

# Поля id, title, description уже унаследованы от Quest из плагина.

# Массив названий основных целей (шагов) квеста
@export var goals: Array[String] = []

# Массив названий подцелей (подшагов) квеста
@export var sub_goals: Array[String] = []
