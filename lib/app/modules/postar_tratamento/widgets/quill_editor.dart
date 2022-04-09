import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:healthbox/app/modules/postar_tratamento/controller.dart';

class QuillEditorColumn extends StatelessWidget {
  final controller = Get.find<PostarTratamentoController>();

  QuillEditorColumn({Key? key}) : super(key: key) {
    controller.controller_editor = QuillController(
        onReplaceText: (int1, int2, obj) {
          if (controller.texto == null) controller.texto = '';
          int tamanho =
              controller.controller_editor.document.toPlainText().length;
          controller.controller_editor.document.toDelta();
          if ((int1 == 0 && int2 == 1) || tamanho >= 200) return false;
          return true;
        },
        document: controller.doc,
        selection: const TextSelection.collapsed(offset: 0));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
            height: MediaQuery.of(context).size.height * 0.1,
            child: QuillToolbar.basic(
              controller: controller.controller_editor,
              showAlignmentButtons: true,
              showImageButton: false,
              showVideoButton: false,
              showCameraButton: false,
              showColorButton: false,
              showUndo: false,
              showRedo: false,
              showBackgroundColorButton: false,
              showStrikeThrough: false,
              showClearFormat: false,
              locale: const Locale('pt'),
              toolbarIconAlignment: WrapAlignment.start,
            )),
        Container(
          margin: const EdgeInsets.only(top: 25),
          width: MediaQuery.of(context).size.width,
          color: Colors.white,
          height: MediaQuery.of(context).size.height * 0.3,
          child: Obx(() => controller.carregando
              ? const Text('carregando...')
              : QuillEditor(
                  controller: controller.controller_editor,
                  scrollController: ScrollController(),
                  scrollable: true,
                  focusNode: FocusNode(),
                  autoFocus: false,
                  readOnly: false,
                  placeholder: controller.texto,
                  expands: true,
                  padding: const EdgeInsets.all(5),
                )),
        ),
        const SizedBox(
          height: 25,
        ),
        Obx(() => Wrap(
              spacing: 25,
              children: [
                Text(
                  controller.TextoErroMensagem ?? '',
                  style: const TextStyle(color: Colors.red),
                ),
                Text(
                  '${(controller.editorLength) - 2}/200',
                  style: TextStyle(
                      color: controller.editorLength <= 200
                          ? Colors.black
                          : Colors.red),
                )
              ],
            ))
      ],
    );
  }
}