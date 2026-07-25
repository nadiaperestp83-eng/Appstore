import 'package:flutter_test/flutter_test.dart';

// O teste padrão do `flutter create` (widget_test.dart original) referenciava
// `package:playstore/main.dart` e o widget `MyApp`, que não existem neste
// projeto (o pacote real se chama `playstore_flutter` e tem sua própria tela
// inicial). Trocado por um smoke test simples que só garante que a suíte de
// testes roda no CI sem travar o `flutter analyze`/`flutter test`.
//
// Se quiser um teste de verdade depois, importe sua tela inicial real, ex.:
//   import 'package:playstore_flutter/main.dart';
// e troque o `expect` abaixo por um pumpWidget(const SeuApp()).

void main() {
  test('sanity check', () {
    expect(1 + 1, 2);
  });
}
