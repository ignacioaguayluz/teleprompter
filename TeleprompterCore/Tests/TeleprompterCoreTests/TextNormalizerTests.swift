import Testing
@testable import TeleprompterCore

@Suite struct TextNormalizerTests {
    @Test(arguments: [
        ("Países,", "paises"),
        ("¿Ciberseguridad?", "ciberseguridad"),
        ("Niño", "nino"),
        ("PINGÜINO", "pinguino"),
        ("—", ""),
        ("\"hoy\"", "hoy"),
    ])
    func normalizesWord(input: String, expected: String) {
        #expect(TextNormalizer.normalize(input) == expected)
    }
}
