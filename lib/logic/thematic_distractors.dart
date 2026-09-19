/// Laufzeit-Erzeugung von Falschantworten ist absichtlich entfernt.
///
/// Das Quiz verwendet ausschließlich die drei gespeicherten Distraktoren
/// derselben Karte. Qualität prüft [DistractorValidator], Duplikate
/// [QuestionNormalizer]. KI nur im Import/Review, nie beim Quizstart.
const bool kRuntimeDistractorGenerationRemoved = true;
