import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:healthbox/app/data/models/medicamento_info.dart';
import 'package:healthbox/app/data/models/opiniao.dart';
import 'package:healthbox/app/modules/opinioes/controller.dart';
import 'package:healthbox/app/modules/opinioes/widgets/detalhes_opiniao/card_detalhes_interacoes.dart';
import 'package:healthbox/app/modules/opinioes/widgets/detalhes_opiniao/card_detalhes_medicamentos.dart';
import 'package:healthbox/core/theme/app_text_theme.dart';

import '../../../../../core/values/keys.dart';

class PageDetalhesOpiniao extends GetView<OpinioesController> {
  late Opiniao opiniao;
  PageDetalhesOpiniao({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    opiniao = controller.opinioes[Get.arguments];
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 100.0,
              child: Image.asset('${baseImagemUrl}user_pic.png'),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              '${opiniao.tratamento!.titulo}',
              style: titulo,
              textAlign: TextAlign.center,
            ),
            Container(
              width: MediaQuery.of(context).size.width * 1,
              margin: const EdgeInsets.only(right: 25.0),
              padding: const EdgeInsets.fromLTRB(5, 15, 0, 0),
              child: Card(
                child: QuillEditor(
                  controller: QuillController(
                      document:
                          Document.fromJson(jsonDecode(opiniao.descricao)),
                      selection: const TextSelection.collapsed(offset: 0)),
                  scrollController: ScrollController(),
                  scrollable: true,
                  focusNode: FocusNode(),
                  minHeight: MediaQuery.of(context).size.height * 0.3,
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                  autoFocus: false,
                  readOnly: true,
                  enableInteractiveSelection: false,
                  expands: false,
                  padding: const EdgeInsets.all(5),
                ),
              ),
            ),
            CardDetalhesMedicamentos(
                medicamentos: opiniao.tratamento?.medicamentos ??
                    List<MedicamentoInfo>.empty()),
            CardDetalhesInteracoes(),
          ],
        ),
      ),
    );
  }
}
